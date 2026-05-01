#!/bin/bash

set -e

echo "========================================================"
echo "🚀 Starting Universal Google Cloud Setup (macOS/Linux)"
echo "========================================================"

# --- OS & Architecture Detection ---
OS="$(uname -s)"
ARCH="$(uname -m)"
echo "💻 Detected System: $OS ($ARCH)"

# --- STEP 1: Python & Venv Check ---
if ! command -v python3 &> /dev/null; then
    if [ "$OS" = "Darwin" ]; then
        echo "📦 Python3 not found. Triggering Apple's developer tools installation..."
        xcode-select --install || true
        echo "⚠️ Please finish that installation, then run this script again."
        exit 1
    elif [ "$OS" = "Linux" ]; then
        echo "❌ Python3 is not installed."
        echo "Please install it using your package manager (e.g., 'sudo apt install python3' on Ubuntu/Debian)."
        exit 1
    fi
else
    echo "✅ Python3 is installed."
fi

# Linux Specific Check: Ubuntu/Debian often strip the 'venv' module out of default Python
if [ "$OS" = "Linux" ]; then
    if ! python3 -c "import venv" &> /dev/null; then
        echo "❌ Python3 'venv' module is missing."
        echo "On Ubuntu/Debian, please run: sudo apt install python3-venv"
        echo "Then run this script again."
        exit 1
    fi
fi

# --- STEP 2: GCloud Install ---
GCLOUD_DIR="$HOME/google-cloud-sdk"
GCLOUD_BIN="$GCLOUD_DIR/bin/gcloud"

if [ ! -f "$GCLOUD_BIN" ]; then
    echo "📦 Google Cloud CLI not found. Preparing download..."
    
    if [ "$OS" = "Darwin" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz"
        elif [ "$ARCH" = "arm64" ]; then
            GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz"
        fi
    elif [ "$OS" = "Linux" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-arm.tar.gz"
        fi
    fi

    if [ -z "$GCLOUD_URL" ]; then
        echo "❌ Unsupported Architecture/OS combination: $OS / $ARCH"
        exit 1
    fi

    echo "📥 Downloading Google Cloud SDK..."
    curl -O $GCLOUD_URL
    tar -xf $(basename $GCLOUD_URL) -C "$HOME"
    rm $(basename $GCLOUD_URL)
    
    echo "⚙️ Running silent install..."
    "$GCLOUD_DIR/install.sh" --quiet --path-update=false
    echo "✅ Google Cloud CLI installed successfully."
else
    echo "✅ Google Cloud CLI is already installed."
fi

export PATH="$GCLOUD_DIR/bin:$PATH"

# --- STEP 3: Base Authentication ---
if ! gcloud auth print-access-token &> /dev/null; then
    echo "========================================================"
    echo "🔑 Step 3: Google Account Login"
    echo "========================================================"
    # On headless Linux (no GUI), this safely falls back to giving a terminal link
    gcloud auth login
else
    echo "✅ Already logged into Google Cloud."
fi

# --- STEP 4: Intelligent Project & Billing Setup ---
echo "========================================================"
echo "🏗️ Step 4: Project & Billing Configuration"
echo "========================================================"

EXISTING_PROJECT=$(gcloud projects list --format="value(projectId)" --limit=1 2>/dev/null || true)
NEEDS_BILLING=true

if [ -n "$EXISTING_PROJECT" ]; then
    echo "🔍 Found an existing project: $EXISTING_PROJECT"
    read -p "Do you want to use this project? (y/n): " USE_EXISTING
    
    if [[ "$USE_EXISTING" =~ ^[Yy]$ ]]; then
        PROJECT_ID=$EXISTING_PROJECT
        gcloud config set project $PROJECT_ID --quiet
        
        echo "⏳ Checking if billing and Vertex AI are already set up..."
        API_STATUS=$(gcloud services list --project="$PROJECT_ID" --enabled --filter="config.name=aiplatform.googleapis.com" --format="value(config.name)")
        
        if [ "$API_STATUS" == "aiplatform.googleapis.com" ]; then
            echo "✅ Vertex AI API is already enabled! (Billing is active)."
            NEEDS_BILLING=false
        else
            echo "⚠️ Project exists, but Vertex AI is not enabled."
        fi
    else
        PROJECT_ID="gemini-trial-$(date +%s)"
        echo "🏗️ Creating a new project: $PROJECT_ID"
        gcloud projects create $PROJECT_ID
        gcloud config set project $PROJECT_ID --quiet
    fi
else
    PROJECT_ID="gemini-trial-$(date +%s)"
    echo "🏗️ No projects found. Creating: $PROJECT_ID"
    gcloud projects create $PROJECT_ID
    gcloud config set project $PROJECT_ID --quiet
fi

if [ "$NEEDS_BILLING" = true ]; then
    echo "========================================================"
    echo "🛑 MANUAL STEP REQUIRED: Billing Activation"
    echo "========================================================"
    echo "1. Copy/paste this link into your browser:"
    echo "   👉 https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    echo "2. Accept the free trial terms and link your billing account."
    echo ""
    read -p "Press [ENTER] only AFTER you have linked the billing account..."

    echo "⚙️ Enabling Vertex AI API (this takes about 30 seconds)..."
    gcloud services enable aiplatform.googleapis.com
fi

# --- STEP 5: Application Default Credentials (ADC) ---
echo "========================================================"
echo "🛡️ Step 5: Local Code Credentials (ADC)"
echo "========================================================"
ADC_FILE="$HOME/.config/gcloud/application_default_credentials.json"

if [ -f "$ADC_FILE" ]; then
    echo "✅ Application Default Credentials already exist."
    read -p "Do you want to re-authenticate just to be safe? (y/n - press 'n' if unsure): " REAUTH_ADC
    if [[ "$REAUTH_ADC" =~ ^[Yy]$ ]]; then
        gcloud auth application-default login
    else
        echo "⏭️ Skipping ADC generation."
    fi
else
    gcloud auth application-default login
fi

# --- STEP 6: Workspace & Virtual Environment ---
WORKSPACE_DIR="$HOME/gemini_agent_workspace"
echo "========================================================"
echo "🐍 Step 6: Setting up Python Workspace"
echo "========================================================"

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
echo "📦 Installing Google GenAI SDK..."
pip install google-genai --quiet

# --- STEP 7: Write & Run the Agent Script ---
echo "📝 Writing the Gemini test script..."
cat << 'EOF' > test_agent.py
from google import genai
from google.genai import types
import os

project_id = os.popen('gcloud config get-value project').read().strip()

print(f"\n🚀 Initializing Gemini 2.5 Pro on Vertex AI...")
print(f"📂 Routing billing to Project: {project_id}")

try:
    client = genai.Client(
        vertexai=True,
        project=project_id, 
        location="us-central1"
    )

    config = types.GenerateContentConfig(
        tools=[types.Tool(google_search=types.GoogleSearch())],
        temperature=1.0
    )

    print("\n🔍 Asking Gemini to search the live web for Coal India stock data...\n")

    response = client.models.generate_content(
        model='gemini-2.5-pro',
        contents='What is the current share price and latest market news for Coal India?',
        config=config
    )
    print("================ RESPONSE ================")
    print(response.text)
    print("==========================================")
                
except Exception as e:
    print(f"\n❌ Error during execution: {e}")
EOF

echo "========================================================"
echo "🎉 Setup Complete! Running your first Agentic Query..."
echo "========================================================"
python test_agent.py

echo ""
echo "✅ You are all set."

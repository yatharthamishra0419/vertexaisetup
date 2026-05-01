# **🚀 Universal Vertex AI Setup for Gemini Agents (macOS & Linux)**

Welcome to the **Universal Google Cloud Setup for Gemini Agents**. This repository contains a bulletproof, state-aware bash script designed to bootstrap your entire development environment for building autonomous AI agents using Google's flagship Gemini models.

This setup specifically targets **Google Cloud Vertex AI** rather than standard API keys to ensure you can safely utilize Google Cloud promotional credits without incurring unexpected out-of-pocket charges.

## **🌟 What This Provides & Why It Is Helpful**

Setting up a robust, enterprise-grade AI environment usually requires navigating complex IAM permissions, installing multiple command-line tools, configuring virtual environments, and understanding convoluted billing architectures. For developers or researchers new to Google Cloud, this can take hours.

This repository solves that friction by providing a **single-click-style script** that automates the entire process from zero to a fully grounded, agentic AI query.

## **✨ Advantages**

1. **Fully Automated Dependency Management:** Automatically detects your OS (macOS/Linux) and architecture (Intel/ARM), safely installing Python 3, virtual environments, and the correct Google Cloud CLI binaries.  
2. **The $300 Free Trial Shield:** Explicitly routes your authentication through **Vertex AI Application Default Credentials (ADC)**. This protects you from the common trap of accidentally charging your credit card via standard AI Studio API keys.  
3. **State-Aware Execution:** The script is intelligent. It checks your system state before acting. If you already have a Google Cloud project, billing enabled, or Python installed, it seamlessly skips those steps rather than crashing or duplicating resources.  
4. **Instant Grounding Access:** Comes pre-configured with a Python test script demonstrating **Google Search Grounding**, allowing your Gemini model to bypass its training cutoff and pull live data directly from the web.

## **🛡️ The $300 Free Trial Shield Explained**

A major trap for new developers is creating an API key in **Google AI Studio** while on the Google Cloud Free Trial. Google's billing policies dictate that AI Studio API keys **bypass** the $300 Welcome Credit and directly charge your credit card.

**How this script protects you:**

This script entirely avoids AI Studio. Instead, it enables the **Vertex AI API** inside your Google Cloud Console and generates local Application Default Credentials (ADC). Because Vertex AI is considered an enterprise cloud service, all of your model usage costs will safely drain from your $300 promotional buffer instead of your bank account.

## **🛠️ Prerequisites**

* A **macOS** (Intel or Apple Silicon) or **Linux** (Ubuntu/Debian/Fedora, etc.) operating system.  
* A standard user account with internet access.  
* A Google Account (preferably with the $300 Google Cloud Free Trial activated).

## **🚀 Setup Instructions**

Follow these exact steps to completely automate your environment setup:

### **1\. Download the Setup Script**

Clone this repository to your local machine:

git clone \<your-repository-url\>  
cd \<repository-folder\>

### **2\. Make the Script Executable**

Before running the script, you need to grant it execution permissions:

chmod \+x setup\_gemini.sh

### **3\. Run the Installer**

Execute the script. It will guide you through the process via simple, interactive prompts:

./setup\_gemini.sh

### **What to expect during installation:**

* **Google Login:** A browser window will open asking you to log into your Google Account.  
* **Project Initialization:** It will check for existing projects or create a new one (e.g., gemini-trial-xxxx).  
* **Billing Activation (Manual Step):** The script will pause and provide a direct link to the Google Cloud Console. You must click this link and link your billing account to activate the trial. *(Your card will not be charged; this simply enables the trial).*  
* **ADC Generation:** It will securely generate Application Default Credentials linking your local computer to your cloud project.  
* **Workspace Creation:** It builds an isolated Python virtual environment at \~/gemini\_agent\_workspace and installs the new google-genai SDK.

## **🐍 The Test Script**

At the end of the installation, the script automatically writes and executes a test Python file (test\_agent.py) to prove your environment is fully operational.

Here is the code that is generated. It demonstrates how to call **Gemini 2.5 Pro** and use the **Google Search Grounding** tool to fetch live stock market data:

from google import genai  
from google.genai import types  
import os

\# Securely grab the project ID dynamically from your active gcloud config  
project\_id \= os.popen('gcloud config get-value project').read().strip()

print(f"\\n🚀 Initializing Gemini 2.5 Pro on Vertex AI...")  
print(f"📂 Routing billing to Project: {project\_id}")

try:  
    \# Initialize the client enforcing Vertex AI to protect your $300 trial  
    client \= genai.Client(  
        vertexai=True,  
        project=project\_id,   
        location="us-central1"  
    )

    \# Attach the Google Search Grounding tool  
    config \= types.GenerateContentConfig(  
        tools=\[types.Tool(google\_search=types.GoogleSearch())\],  
        temperature=1.0 \# Recommended 1.0 for best search synthesis  
    )

    print("\\n🔍 Asking Gemini to search the live web for Coal India stock data...\\n")

    response \= client.models.generate\_content(  
        model='gemini-2.5-pro',  
        contents='What is the current share price and latest market news for Coal India?',  
        config=config  
    )  
    print("================ RESPONSE \================")  
    print(response.text)  
    print("==========================================")  
      
    \# Extract and display the actual web URLs the model read  
    if response.candidates and response.candidates\[0\].grounding\_metadata:  
        print("\\n🌐 Sources Used:")  
        for chunk in response.candidates\[0\].grounding\_metadata.grounding\_chunks:  
            if hasattr(chunk, 'web'):  
                print(f"- {chunk.web.title}: {chunk.web.uri}")  
                  
except Exception as e:  
    print(f"\\n❌ Error during execution: {e}")

## **🔄 Daily Usage**

Once the initial setup is complete, you do not need to run the shell script again. Whenever you want to return to your code and build new agents, simply open a terminal and activate your workspace:

cd \~/gemini\_agent\_workspace  
source venv/bin/activate

You are now ready to install additional libraries (like LangChain, LlamaIndex, or CrewAI) and build your autonomous AI applications\!

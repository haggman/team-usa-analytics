#!/bin/bash
# =============================================================================
# Team USA Analytics Agent — Setup Script
# =============================================================================
# This script prepares your environment:
#   1. Validates your .env configuration
#   2. Downloads the MCP Toolbox binary (if not present)
#   3. Creates a Python virtual environment with ADK dependencies
#
# Usage: chmod +x setup.sh && ./setup.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================="
echo "  Team USA Analytics Agent — Setup"
echo "============================================="
echo ""

# --- Step 1: Validate .env ---
if [ ! -f .env ]; then
    echo "ERROR: .env file not found!"
    echo "Copy and edit .env from the template, then re-run this script."
    exit 1
fi

source .env

if [[ "$PROJECT_ID" == "__PROJECT_ID__" || -z "$PROJECT_ID" ]]; then
    echo "ERROR: PROJECT_ID not configured in .env"
    echo "Edit .env and fill in your lab values, then re-run."
    exit 1
fi

echo "✓ Environment configured"
echo "  Project:  $PROJECT_ID"
echo "  Region:   $REGION"
echo "  DB User:  $DB_USER"
echo ""

# --- Step 2: Download MCP Toolbox binary ---
TOOLBOX_VERSION="0.26.0"

if [ ! -f ./toolbox ]; then
    echo "Downloading MCP Toolbox v${TOOLBOX_VERSION}..."
    curl -sO "https://storage.googleapis.com/genai-toolbox/v${TOOLBOX_VERSION}/linux/amd64/toolbox"
    chmod +x toolbox
    echo "✓ Toolbox downloaded"
else
    echo "✓ Toolbox binary already present"
fi
echo ""

# --- Step 3: Python virtual environment ---
if [ ! -d .venv ]; then
    echo "Creating Python virtual environment and loading requirements..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -q --upgrade pip wheel
    pip install -q -r requirements.txt
    echo "✓ Virtual environment created and dependencies installed"
else
    source .venv/bin/activate
    echo "✓ Virtual environment activated"
fi
echo ""

# --- Ready! ---
echo "============================================="
echo "  Setup complete! Next steps:"
echo "============================================="
echo ""
echo "  1. Start the Toolbox server (in this terminal):"
echo "     source .env && ./toolbox --tools-file tools.yaml"
echo ""
echo "  2. Open a NEW terminal tab, then start the agent:"
echo "     cd $(pwd)"
echo "     source .env && source .venv/bin/activate"
echo "     adk web"
echo ""
echo "  3. Open the ADK web UI link that appears and start chatting!"
echo ""

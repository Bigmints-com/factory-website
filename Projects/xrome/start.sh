#!/bin/bash

# PySide Browser App Startup Script

echo "🚀 Starting PySide Browser App..."

# Check if Python 3.11+ is available
python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
required_version="3.11"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "❌ Error: Python 3.11+ is required. Found: $python_version"
    echo "Please install Python 3.11 or later."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "app/main.py" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    echo "Expected to find app/main.py"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install -e .
pip install playwright
playwright install chromium
echo "✅ Dependencies installed"

# Set environment variables
export PYTHONPATH="${PYTHONPATH}:$(pwd)/app"

# Run the application
echo "🌐 Launching PySide Browser App..."
python3 run.py

echo "👋 PySide Browser App closed"

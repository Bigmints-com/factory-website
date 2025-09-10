@echo off
REM PySide Browser App Startup Script for Windows

echo 🚀 Starting PySide Browser App...

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Python is not installed or not in PATH
    echo Please install Python 3.11+ from https://python.org
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "app\main.py" (
    echo ❌ Error: Please run this script from the project root directory
    echo Expected to find app\main.py
    pause
    exit /b 1
)

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo 📦 Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo 📥 Installing dependencies...
python -m pip install --upgrade pip
pip install -e .
pip install playwright
playwright install chromium
echo ✅ Dependencies installed

REM Set environment variables
set PYTHONPATH=%PYTHONPATH%;%CD%\app

REM Run the application
echo 🌐 Launching PySide Browser App...
python run.py

echo 👋 PySide Browser App closed
pause

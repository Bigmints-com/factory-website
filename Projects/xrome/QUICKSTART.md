# Quick Start Guide

## 🚀 Running the Application

### On macOS/Linux:
```bash
./start.sh
```

### On Windows:
```cmd
start.bat
```

## 📋 Prerequisites

- Python 3.11 or later
- Internet connection (for installing dependencies)

## 🎯 What the App Does

1. **Opens a modern browser interface** with navigation controls
2. **Shows a chat sidebar** for AI-powered page analysis
3. **Provides analysis tools** for websites (Analytics, Usability, Accessibility)
4. **Streams results** directly into the chat interface

## ⚙️ First Run

1. The script will automatically:
   - Create a virtual environment
   - Install all dependencies
   - Download Playwright browser
   - Launch the application

2. **Configure your LLM API**:
   - Click the ⚙️ Settings button in the sidebar
   - Enter your OpenAI API key (or compatible service)
   - Select your preferred model

3. **Start browsing and chatting**:
   - Navigate to any website
   - Ask questions about the page in the chat
   - Use the Tools menu to run analysis

## 🔧 Troubleshooting

- **Import errors**: Make sure you're running from the project root directory
- **Python version**: Ensure you have Python 3.11+ installed
- **Dependencies**: The start script will install everything automatically
- **Playwright issues**: Run `playwright install chromium` manually if needed

## 📁 Project Structure

```
├── start.sh          # macOS/Linux startup script
├── start.bat         # Windows startup script
├── run.py            # Python runner
├── app/              # Main application code
└── requirements.txt  # Dependencies
```

Enjoy your new AI-powered browser! 🎉

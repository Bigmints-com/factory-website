#!/bin/bash
# Development script with hot reload

echo "🔥 Starting PySide Browser with Hot Reload..."
echo "📁 Watching for changes in Python and QSS files..."
echo "💡 Make changes to any .py or .qss file to see them instantly!"
echo "🛑 Press Ctrl+C to stop"
echo "----------------------------------------"

# Activate virtual environment
source venv/bin/activate

# Start hot reload
python hot_reload.py

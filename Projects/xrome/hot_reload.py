#!/usr/bin/env python3
"""
Hot reload script for PySide Browser App
Watches for file changes and automatically restarts the application
"""

import os
import sys
import time
import subprocess
import signal
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class AppReloader(FileSystemEventHandler):
    def __init__(self):
        self.process = None
        self.restart_app()
    
    def restart_app(self):
        """Restart the application"""
        if self.process:
            print("🔄 Stopping application...")
            try:
                self.process.terminate()
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                print("⚠️  Force killing application...")
                self.process.kill()
                self.process.wait()
            except Exception as e:
                print(f"⚠️  Error stopping app: {e}")
        
        print("🚀 Starting application...")
        try:
            self.process = subprocess.Popen([
                sys.executable, "run.py"
            ], cwd=os.getcwd())
            print("✅ Application started successfully")
        except Exception as e:
            print(f"❌ Error starting app: {e}")
    
    def on_modified(self, event):
        """Handle file modification events"""
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        
        # Only watch Python files and QSS files
        if file_path.suffix in ['.py', '.qss']:
            print(f"📝 File changed: {file_path.name}")
            time.sleep(0.5)  # Small delay to avoid multiple restarts
            self.restart_app()
    
    def on_created(self, event):
        """Handle file creation events"""
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        if file_path.suffix in ['.py', '.qss']:
            print(f"📄 New file: {file_path.name}")
            time.sleep(0.5)
            self.restart_app()

def main():
    print("🔥 Hot Reload Server Starting...")
    print("📁 Watching for changes in Python and QSS files...")
    print("💡 Make changes to any .py or .qss file to see them instantly!")
    print("🛑 Press Ctrl+C to stop")
    print("-" * 50)
    
    # Create the event handler
    event_handler = AppReloader()
    
    # Create the observer
    observer = Observer()
    
    # Watch the app directory and assets directory
    watch_dirs = [
        "app/",
        "app/ui/",
        "app/ui/widgets/",
        "app/assets/styles/",
        "app/core/",
        "app/browser/"
    ]
    
    for watch_dir in watch_dirs:
        if os.path.exists(watch_dir):
            observer.schedule(event_handler, watch_dir, recursive=True)
            print(f"👀 Watching: {watch_dir}")
    
    # Start watching
    observer.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Stopping hot reload server...")
        observer.stop()
        
        # Stop the application
        if event_handler.process:
            print("🔄 Stopping application...")
            try:
                event_handler.process.terminate()
                event_handler.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                event_handler.process.kill()
                event_handler.process.wait()
    
    observer.join()
    print("✅ Hot reload server stopped")

if __name__ == "__main__":
    main()

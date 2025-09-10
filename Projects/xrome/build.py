#!/usr/bin/env python3
"""
Build script for PySide Browser App
"""
import os
import sys
import subprocess
import shutil
from pathlib import Path

def run_command(cmd, cwd=None):
    """Run a command and return success status"""
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd)
    return result.returncode == 0

def build_app():
    """Build the application using PyInstaller"""
    print("Building PySide Browser App...")
    
    # Clean previous builds
    if os.path.exists("dist"):
        shutil.rmtree("dist")
    if os.path.exists("build"):
        shutil.rmtree("build")
    
    # PyInstaller command
    cmd = [
        "pyinstaller",
        "--onefile",
        "--windowed",
        "--name=pyside-browser",
        "--add-data=app:app",
        "--hidden-import=PySide6.QtWebEngineWidgets",
        "--hidden-import=PySide6.QtWebEngineCore",
        "--hidden-import=playwright",
        "--hidden-import=httpx",
        "--hidden-import=sqlmodel",
        "app/main.py"
    ]
    
    if not run_command(" ".join(cmd)):
        print("Build failed!")
        return False
    
    print("Build completed successfully!")
    print("Executable created in dist/pyside-browser")
    return True

def install_dependencies():
    """Install required dependencies"""
    print("Installing dependencies...")
    
    # Install Python dependencies
    if not run_command("pip install -e ."):
        print("Failed to install Python dependencies")
        return False
    
    # Install Playwright browsers
    if not run_command("playwright install chromium"):
        print("Failed to install Playwright browsers")
        return False
    
    print("Dependencies installed successfully!")
    return True

def main():
    """Main build function"""
    if len(sys.argv) > 1 and sys.argv[1] == "install":
        if not install_dependencies():
            sys.exit(1)
    else:
        if not build_app():
            sys.exit(1)

if __name__ == "__main__":
    main()

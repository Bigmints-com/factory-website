#!/usr/bin/env python3
"""
Test script to verify installation
"""
import sys
import os

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

def test_imports():
    """Test that all required modules can be imported"""
    try:
        print("Testing imports...")
        
        # Test PySide6
        from PySide6.QtWidgets import QApplication
        print("✅ PySide6 imported successfully")
        
        # Test our modules
        from core.config import Config
        print("✅ Config imported successfully")
        
        from core.state import AppState
        print("✅ AppState imported successfully")
        
        from browser.view import BrowserView
        print("✅ BrowserView imported successfully")
        
        from ui.main_window import MainWindow
        print("✅ MainWindow imported successfully")
        
        print("\n🎉 All imports successful! The application should run correctly.")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("Please run: pip install -e .")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_imports()
    sys.exit(0 if success else 1)

#!/usr/bin/env python3
"""
Simple run script for development
"""
import sys
import os

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

if __name__ == "__main__":
    from main import main
    main()

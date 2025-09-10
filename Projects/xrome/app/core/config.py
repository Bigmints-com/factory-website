import os
from pathlib import Path
from typing import Dict, Any
import json

class Config:
    def __init__(self):
        self.config_dir = Path.home() / ".pyside-browser"
        self.config_dir.mkdir(exist_ok=True)
        self.config_file = self.config_dir / "config.json"
        self.db_file = self.config_dir / "browser.db"
        
        # Default settings
        self.settings = {
            "llm_base": "http://localhost:11434",
            "llm_key": "",
            "models": [],  # Will be populated from Ollama
            "default_model": "",
            "home_url": "https://www.google.com",
            "window_width": 1400,
            "window_height": 900,
        }
        self.load()
    
    def load(self):
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    saved = json.load(f)
                    self.settings.update(saved)
            except Exception as e:
                print(f"Error loading config: {e}")
    
    def save(self):
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.settings, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def get(self, key: str, default=None):
        return self.settings.get(key, default)
    
    def set(self, key: str, value: Any):
        self.settings[key] = value
        self.save()
    
    def update(self, updates: Dict[str, Any]):
        self.settings.update(updates)
        self.save()


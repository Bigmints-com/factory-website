#!/usr/bin/env python3
"""
Script to display all available Feather icons
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.core.icons import icon_manager

def main():
    print("🎨 Available Feather Icons:")
    print("=" * 50)
    
    icons = icon_manager.list_available_icons()
    
    # Group icons by category
    categories = {
        "Navigation": ["arrow-left", "arrow-right", "refresh-cw", "home", "menu", "chevron-left", "chevron-right", "chevron-up", "chevron-down"],
        "Actions": ["search", "settings", "plus", "more-horizontal", "more-vertical"],
        "Chat": ["message-circle", "send", "user", "bot"],
        "Tools": ["tool", "activity", "bar-chart", "shield"],
        "Status": ["check", "x-circle", "alert-circle", "info", "x"],
        "Files": ["folder", "file", "download", "upload"],
    }
    
    for category, icon_list in categories.items():
        print(f"\n📁 {category}:")
        for icon in icon_list:
            if icon in icons:
                print(f"  • {icon}")
    
    print(f"\n📊 Total icons available: {len(icons)}")
    print("\n💡 Usage example:")
    print("   icon_manager.get_icon('settings', 24, '#007AFF')")

if __name__ == "__main__":
    main()

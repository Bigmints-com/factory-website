"""
Icon management system for PySide Browser App
Handles Feather icons and other icon resources
"""

import os
import sys
from pathlib import Path
from PySide6.QtGui import QIcon, QPixmap, QPainter, QColor
from PySide6.QtCore import QSize
from PySide6.QtSvg import QSvgRenderer

class IconManager:
    """Manages icons for the application"""
    
    def __init__(self):
        self.icons_dir = Path("app/assets/icons")
        self.icons_dir.mkdir(exist_ok=True)
        
        # Feather icons mapping
        self.feather_icons = {
            # Navigation
            "arrow-left": "M19 12H5m7-7l-7 7 7 7",
            "arrow-right": "M5 12h14m-7-7l7 7-7 7",
            "refresh-cw": "M23 4v6h-6M1 20v-6h6M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15",
            "home": "M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
            "menu": "M3 12h18M3 6h18M3 18h18",
            "x": "M18 6L6 18M6 6l12 12",
            
            # Globe and Web
            "globe": "M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10zM2 12h20",
            "zap": "M13 2L3 14h9l-1 8 10-12h-9l1-8z",
            "compass": "M21 12a9 9 0 1 1-6.219-8.56",
            "navigation": "M3 11l19-9-9 19-2-8-8-2z",
            
            # Additional UI Icons
            "layers": "M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5",
            "grid": "M3 3h7v7H3V3zM14 3h7v7h-7V3zM14 14h7v7h-7v-7zM3 14h7v7H3v-7z",
            "sidebar": "M3 3h18v18H3V3zM9 9h6v6H9V9z",
            "bookmark": "M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z",
            "star": "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z",
            "heart": "M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z",
            "book": "M4 19.5A2.5 2.5 0 0 1 6.5 17H20",
            "calendar": "M8 2v4M16 2v4M3 10h18M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z",
            "clock": "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zM12 6v6l4 2",
            "bell": "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M13.73 21a2 2 0 0 1-3.46 0",
            "mail": "M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z",
            "phone": "M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z",
            "camera": "M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z",
            "image": "M21 19V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z",
            "video": "M23 7l-7 5 7 5V7zM14 5H3a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z",
            "music": "M9 18V5l12-2v13M9 9c0 2.21-1.79 4-4 4s-4-1.79-4-4 1.79-4 4-4 4 1.79 4 4zM21 9c0 2.21-1.79 4-4 4s-4-1.79-4-4 1.79-4 4-4 4 1.79 4 4z",
            "play": "M8 5v14l11-7z",
            "pause": "M6 4h4v16H6zM14 4h4v16h-4z",
            "stop": "M18 6H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2z",
            "volume-2": "M11 5L6 9H2v6h4l5 4V5zM19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07",
            "volume-x": "M11 5L6 9H2v6h4l5 4V5zM23 9l-6 6M17 9l6 6",
            "mic": "M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3zM19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8",
            "headphones": "M3 14v3a3 3 0 0 0 3 3h1a3 3 0 0 0 3-3v-3M21 14v3a3 3 0 0 1-3 3h-1a3 3 0 0 1-3-3v-3M12 2a4 4 0 0 0-4 4v6a4 4 0 0 0 8 0V6a4 4 0 0 0-4-4z",
            
            # Additional action icons
            "trash-2": "M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M10 11v6M14 11v6",
            "edit": "M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z",
            "copy": "M20 9H11a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2v-9a2 2 0 0 0-2-2zM5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1",
            "share": "M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13",
            "external-link": "M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6M15 3h6v6M10 14L21 3",
            "link": "M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71",
            "unlink": "M18.84 19.25A9.94 9.94 0 0 0 21 12c0-5.52-4.48-10-10-10-2.12 0-4.08.66-5.7 1.78L5.5 5.5A12 12 0 0 1 12 2c5.52 0 10 4.48 10 10 0 2.12-.66 4.08-1.78 5.7l-1.38-1.45zM2 12c0 5.52 4.48 10 10 10 2.12 0 4.08-.66 5.7-1.78L18.5 18.5A12 12 0 0 1 12 22c-5.52 0-10-4.48-10-10zM8.5 8.5l7 7",
            "archive": "M21 8v13H3V8M1 3h22v5H1zM10 12h4",
            "folder-plus": "M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2zM12 11v6M9 14h6",
            "save": "M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2zM17 21v-8H7v8M7 3v5h8",
            
            # Actions
            "search": "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z",
            "settings": "M12 15a3 3 0 100-6 3 3 0 000 6zM19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z",
            "plus": "M12 5v14m-7-7h14",
            "more-horizontal": "M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z",
            "more-vertical": "M12 5v.01M12 12v.01M12 19v.01M19 12a1 1 0 11-2 0 1 1 0 012 0zM5 12a1 1 0 11-2 0 1 1 0 012 0z",
            
            # Chat
            "message-circle": "M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z",
            "send": "M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z",
            "user": "M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2",
            "bot": "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z",
            
            # Tools
            "tool": "M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.76z",
            "activity": "M22 12h-4l-3 9L9 3l-3 9H2",
            "bar-chart": "M12 20V10M18 20V4M6 20v-4",
            "shield": "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",
            
            # Status
            "check": "M20 6L9 17l-5-5",
            "x-circle": "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zM15 9l-6 6M9 9l6 6",
            "alert-circle": "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zM12 8v4M12 16h.01",
            "info": "M12 16v-4M12 8h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
            
            # Navigation
            "chevron-left": "M15 18l-6-6 6-6",
            "chevron-right": "M9 18l6-6-6-6",
            "chevron-up": "M18 15l-6-6-6 6",
            "chevron-down": "M6 9l6 6 6-6",
            
            # File operations
            "folder": "M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z",
            "file": "M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z",
            "download": "M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3",
            "upload": "M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 15V3",
        }
    
    def get_icon(self, name: str, size: int = 24, color: str = "#cccccc") -> QIcon:
        """Get a Feather icon as QIcon"""
        if name not in self.feather_icons:
            print(f"Warning: Icon '{name}' not found in Feather icons")
            return QIcon()
        
        # Create SVG content
        svg_content = self._create_svg_icon(name, size, color)
        
        # Create QIcon from SVG
        return self._svg_to_qicon(svg_content, size)
    
    def _create_svg_icon(self, name: str, size: int, color: str) -> str:
        """Create SVG content for a Feather icon"""
        path_data = self.feather_icons[name]
        
        svg = f'''<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="{path_data}"/>
</svg>'''
        return svg
    
    def _svg_to_qicon(self, svg_content: str, size: int) -> QIcon:
        """Convert SVG content to QIcon"""
        try:
            # Create QSvgRenderer from SVG content
            renderer = QSvgRenderer()
            renderer.load(svg_content.encode('utf-8'))
            
            # Create pixmap
            pixmap = QPixmap(size, size)
            pixmap.fill(QColor(0, 0, 0, 0))  # Transparent background
            
            # Render SVG to pixmap
            painter = QPainter(pixmap)
            renderer.render(painter)
            painter.end()
            
            return QIcon(pixmap)
        except Exception as e:
            print(f"Error creating icon: {e}")
            return QIcon()
    
    def get_icon_pixmap(self, name: str, size: int = 24, color: str = "#cccccc") -> QPixmap:
        """Get a Feather icon as QPixmap"""
        icon = self.get_icon(name, size, color)
        return icon.pixmap(size, size)
    
    def list_available_icons(self) -> list:
        """List all available Feather icons"""
        return list(self.feather_icons.keys())

# Global icon manager instance
icon_manager = IconManager()

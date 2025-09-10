from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, 
                               QLabel, QPushButton, QScrollArea, QFrame)
from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QFont, QPixmap, QPainter
from app.core.icons import icon_manager

class FeatureCard(QFrame):
    """Individual feature card widget"""
    clicked = Signal(str)  # feature_name
    
    def __init__(self, title, description, icon_name, feature_name, parent=None):
        super().__init__(parent)
        self.feature_name = feature_name
        self.setup_ui(title, description, icon_name)
    
    def setup_ui(self, title, description, icon_name):
        self.setFixedSize(280, 200)
        self.setStyleSheet("""
            QFrame {
                background-color: #2d2d2d;
                border: 1px solid #404040;
                border-radius: 12px;
                margin: 8px;
            }
            QFrame:hover {
                background-color: #3a3a3a;
                border-color: #007AFF;
                transform: translateY(-2px);
            }
        """)
        
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(12)
        
        # Icon
        icon_label = QLabel()
        icon_label.setFixedSize(48, 48)
        icon_label.setAlignment(Qt.AlignCenter)
        icon_label.setPixmap(icon_manager.get_icon_pixmap(icon_name, 32, "#007AFF"))
        layout.addWidget(icon_label)
        
        # Title
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 18px;
                font-weight: 600;
                color: #ffffff;
                margin-bottom: 4px;
            }
        """)
        title_label.setWordWrap(True)
        layout.addWidget(title_label)
        
        # Description
        desc_label = QLabel(description)
        desc_label.setStyleSheet("""
            QLabel {
                font-size: 14px;
                color: #cccccc;
                line-height: 1.4;
            }
        """)
        desc_label.setWordWrap(True)
        desc_label.setAlignment(Qt.AlignTop)
        layout.addWidget(desc_label)
        
        # Add stretch to push content to top
        layout.addStretch()
        
        # Make clickable
        self.mousePressEvent = self.on_click
    
    def on_click(self, event):
        self.clicked.emit(self.feature_name)

class FeaturesGrid(QWidget):
    """Main features grid widget"""
    feature_clicked = Signal(str)  # feature_name
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()
    
    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        
        # Header
        header_widget = QWidget()
        header_widget.setStyleSheet("""
            QWidget {
                background-color: #1a1a1a;
                border-bottom: 1px solid #404040;
            }
        """)
        header_layout = QVBoxLayout(header_widget)
        header_layout.setContentsMargins(40, 40, 40, 40)
        header_layout.setSpacing(16)
        
        # Welcome title
        welcome_label = QLabel("Welcome to PySide Browser")
        welcome_label.setStyleSheet("""
            QLabel {
                font-size: 32px;
                font-weight: 700;
                color: #ffffff;
                margin-bottom: 8px;
            }
        """)
        header_layout.addWidget(welcome_label)
        
        # Subtitle
        subtitle_label = QLabel("Your AI-powered browser with modern features")
        subtitle_label.setStyleSheet("""
            QLabel {
                font-size: 18px;
                color: #cccccc;
                font-weight: 400;
            }
        """)
        header_layout.addWidget(subtitle_label)
        
        layout.addWidget(header_widget)
        
        # Scroll area for features
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll_area.setStyleSheet("""
            QScrollArea {
                background-color: #1a1a1a;
                border: none;
            }
            QScrollBar:vertical {
                background-color: #2d2d2d;
                width: 8px;
                border-radius: 4px;
            }
            QScrollBar::handle:vertical {
                background-color: #555555;
                border-radius: 4px;
                min-height: 20px;
            }
            QScrollBar::handle:vertical:hover {
                background-color: #666666;
            }
        """)
        
        # Features container
        features_widget = QWidget()
        features_layout = QVBoxLayout(features_widget)
        features_layout.setContentsMargins(40, 40, 40, 40)
        features_layout.setSpacing(40)
        
        # Features grid
        grid_widget = QWidget()
        grid_layout = QGridLayout(grid_widget)
        grid_layout.setSpacing(20)
        grid_layout.setContentsMargins(0, 0, 0, 0)
        
        # Define features
        features = [
            {
                "title": "AI Chat Assistant",
                "description": "Chat with AI about the current webpage. Get insights, summaries, and answers based on page content.",
                "icon": "message-circle",
                "name": "chat"
            },
            {
                "title": "Web Analysis Tools",
                "description": "Analyze websites for performance, accessibility, SEO, and usability with automated tools.",
                "icon": "activity",
                "name": "analysis"
            },
            {
                "title": "Page Context Extraction",
                "description": "Automatically extract and understand webpage content, structure, and metadata.",
                "icon": "compass",
                "name": "context"
            },
            {
                "title": "Ollama Integration",
                "description": "Use local Ollama models for private, fast AI responses without sending data to external services.",
                "icon": "bot",
                "name": "ollama"
            },
            {
                "title": "Modern UI",
                "description": "Clean, dark-themed interface with chat bubbles, icons, and responsive design.",
                "icon": "grid",
                "name": "ui"
            },
            {
                "title": "Chat History",
                "description": "Save and manage multiple chat conversations with persistent storage.",
                "icon": "bookmark",
                "name": "history"
            },
            {
                "title": "Navigation Tools",
                "description": "Back, forward, reload, home, and URL navigation with Chrome-like controls.",
                "icon": "navigation",
                "name": "navigation"
            },
            {
                "title": "Settings & Config",
                "description": "Customize models, endpoints, and application preferences to your needs.",
                "icon": "settings",
                "name": "settings"
            }
        ]
        
        # Add feature cards to grid
        for i, feature in enumerate(features):
            row = i // 3
            col = i % 3
            
            card = FeatureCard(
                feature["title"],
                feature["description"],
                feature["icon"],
                feature["name"]
            )
            card.clicked.connect(self.on_feature_clicked)
            grid_layout.addWidget(card, row, col)
        
        features_layout.addWidget(grid_widget)
        
        # Add some bottom spacing
        features_layout.addStretch()
        
        scroll_area.setWidget(features_widget)
        layout.addWidget(scroll_area)
    
    def on_feature_clicked(self, feature_name):
        """Handle feature card click"""
        self.feature_clicked.emit(feature_name)

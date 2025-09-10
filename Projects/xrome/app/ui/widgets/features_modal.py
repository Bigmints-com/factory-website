from PySide6.QtWidgets import QDialog, QVBoxLayout, QGridLayout, QPushButton, QLabel, QScrollArea, QWidget
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont

class FeaturesModal(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Features")
        self.setModal(True)
        self.resize(600, 400)
        
        layout = QVBoxLayout(self)
        
        # Title
        title = QLabel("Available Features")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        # Features grid
        scroll = QScrollArea()
        scroll_widget = QWidget()
        grid_layout = QGridLayout(scroll_widget)
        
        features = [
            ("Image Analysis", "Analyze images for content, colors, and composition"),
            ("Website Audits", "Comprehensive website performance and SEO audits"),
            ("Brand Token Extraction", "Extract brand colors, fonts, and design tokens"),
            ("User Journey Creation", "Map user flows and journey paths"),
            ("Flow Diagrams", "Generate visual flow diagrams from user interactions"),
            ("Image Comparison", "Compare images for differences and similarities"),
        ]
        
        for i, (name, description) in enumerate(features):
            btn = QPushButton(name)
            btn.setMinimumHeight(60)
            btn.setStyleSheet("""
                QPushButton {
                    background-color: #f0f0f0;
                    border: 1px solid #ccc;
                    border-radius: 8px;
                    padding: 10px;
                    text-align: left;
                    font-weight: bold;
                }
                QPushButton:hover {
                    background-color: #e0e0e0;
                }
                QPushButton:pressed {
                    background-color: #d0d0d0;
                }
            """)
            btn.clicked.connect(lambda checked, n=name: self.feature_clicked(n))
            
            desc = QLabel(description)
            desc.setWordWrap(True)
            desc.setStyleSheet("color: #666; font-size: 12px; margin-top: 5px;")
            
            grid_layout.addWidget(btn, i, 0)
            grid_layout.addWidget(desc, i, 1)
        
        scroll.setWidget(scroll_widget)
        scroll.setWidgetResizable(True)
        layout.addWidget(scroll)
        
        # Close button
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)
    
    def feature_clicked(self, feature_name):
        # For now, just show a message. In a real implementation,
        # this would trigger the specific feature
        print(f"Feature clicked: {feature_name}")
        # You could emit a signal here or call a method on the parent
        self.accept()

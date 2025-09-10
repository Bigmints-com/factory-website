from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QPushButton, 
                               QLabel, QFrame, QSizePolicy)
from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QFont
from app.ui.widgets.features_modal import FeaturesModal
from app.ui.widgets.tools_menu import ToolsMenu
from app.core.icons import icon_manager

class LeftSidebar(QWidget):
    # Signals
    menu_clicked = Signal(str)  # menu item clicked
    
    def __init__(self, state, browser, parent=None):
        super().__init__(parent)
        self.state = state
        self.browser = browser
        self.setFixedWidth(60)  # Fixed width like VS Code
        self.setup_ui()
    
    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        
        # Top section - Main navigation
        top_section = QFrame()
        top_section.setStyleSheet("""
            QFrame {
                background-color: #1a1a1a;
                border-right: 1px solid #404040;
            }
        """)
        top_layout = QVBoxLayout(top_section)
        top_layout.setContentsMargins(0, 8, 0, 8)
        top_layout.setSpacing(4)
        
        # Browser icon (active by default)
        self.browser_btn = self.create_icon_button("globe", "Browser", True)
        self.browser_btn.clicked.connect(lambda: self.menu_clicked.emit("browser"))
        top_layout.addWidget(self.browser_btn)
        
        # Features icon
        self.features_btn = self.create_icon_button("zap", "Features")
        self.features_btn.clicked.connect(self.open_features)
        top_layout.addWidget(self.features_btn)
        
        # Tools icon
        self.tools_btn = self.create_icon_button("tool", "Tools")
        self.tools_btn.clicked.connect(self.open_tools)
        top_layout.addWidget(self.tools_btn)
        
        # Add stretch to push everything up
        top_layout.addStretch()
        
        # Bottom section - Settings and utilities
        bottom_section = QFrame()
        bottom_section.setStyleSheet("""
            QFrame {
                background-color: #1a1a1a;
                border-right: 1px solid #404040;
                border-top: 1px solid #404040;
            }
        """)
        bottom_layout = QVBoxLayout(bottom_section)
        bottom_layout.setContentsMargins(0, 8, 0, 8)
        bottom_layout.setSpacing(4)
        
        # Settings icon
        self.settings_btn = self.create_icon_button("settings", "Settings")
        self.settings_btn.clicked.connect(self.open_settings)
        bottom_layout.addWidget(self.settings_btn)
        
        # Add stretch to push settings to bottom
        bottom_layout.addStretch()
        
        layout.addWidget(top_section)
        layout.addWidget(bottom_section)
    
    def create_icon_button(self, icon_name, tooltip, active=False):
        """Create an icon button with VS Code styling"""
        btn = QPushButton()
        btn.setIcon(icon_manager.get_icon(icon_name, 24, "#cccccc"))
        btn.setToolTip(tooltip)
        btn.setFixedSize(48, 48)
        btn.setCheckable(True)
        btn.setChecked(active)
        
        # Base styling
        base_style = """
            QPushButton {
                background-color: transparent;
                border: none;
                border-radius: 8px;
                font-size: 22px;
                color: #cccccc;
                margin: 3px;
            }
            QPushButton:hover {
                background-color: #404040;
                color: #ffffff;
            }
            QPushButton:pressed {
                background-color: #007AFF;
                color: #ffffff;
            }
        """
        
        # Active state styling
        if active:
            active_style = """
                QPushButton {
                    background-color: #e8f0fe;
                    color: #1a73e8;
                    border-left: 3px solid #1a73e8;
                }
            """
            btn.setStyleSheet(base_style + active_style)
        else:
            btn.setStyleSheet(base_style)
        
        return btn
    
    def set_active_button(self, button_name):
        """Set the active button and update styling"""
        # Reset all buttons
        for btn in [self.browser_btn, self.features_btn, self.tools_btn, self.settings_btn]:
            btn.setChecked(False)
            btn.setStyleSheet("""
                QPushButton {
                    background-color: transparent;
                    border: none;
                    border-radius: 8px;
                    font-size: 20px;
                    color: #5f6368;
                    margin: 2px;
                }
                QPushButton:hover {
                    background-color: #e8f0fe;
                    color: #1a73e8;
                }
                QPushButton:pressed {
                    background-color: #e8f0fe;
                    color: #1a73e8;
                }
            """)
        
        # Set active button
        active_btn = None
        if button_name == "browser":
            active_btn = self.browser_btn
        elif button_name == "features":
            active_btn = self.features_btn
        elif button_name == "tools":
            active_btn = self.tools_btn
        elif button_name == "settings":
            active_btn = self.settings_btn
        
        if active_btn:
            active_btn.setChecked(True)
            active_btn.setStyleSheet("""
                QPushButton {
                    background-color: #e8f0fe;
                    color: #1a73e8;
                    border: none;
                    border-radius: 8px;
                    border-left: 3px solid #1a73e8;
                    font-size: 20px;
                    margin: 2px;
                }
                QPushButton:hover {
                    background-color: #e8f0fe;
                    color: #1a73e8;
                }
                QPushButton:pressed {
                    background-color: #e8f0fe;
                    color: #1a73e8;
                }
            """)
    
    def open_features(self):
        """Open features modal"""
        self.set_active_button("features")
        dlg = FeaturesModal(self)
        dlg.exec()
        # Return to browser after closing
        self.set_active_button("browser")
    
    def open_tools(self):
        """Open tools menu"""
        self.set_active_button("tools")
        if self.browser:
            menu = ToolsMenu(self.state, self.browser, self)
            menu.exec(self.mapToGlobal(self.rect().bottomRight()))
        # Return to browser after closing
        self.set_active_button("browser")
    
    def open_settings(self):
        """Open settings dialog"""
        self.set_active_button("settings")
        from app.ui.widgets.settings_dialog import SettingsDialog
        dlg = SettingsDialog(self.state, self)
        dlg.exec()
        # Return to browser after closing
        self.set_active_button("browser")

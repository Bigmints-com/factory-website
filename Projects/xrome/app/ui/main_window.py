from PySide6.QtWidgets import QMainWindow, QDockWidget, QHBoxLayout, QWidget, QStackedWidget
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont
from app.ui.widgets.header import HeaderBar
from app.ui.widgets.footer import FooterBar
from app.ui.widgets.sidebar import SideBar
from app.ui.widgets.left_sidebar import LeftSidebar
from app.ui.widgets.features_grid import FeaturesGrid
from app.browser.view import BrowserView
from app.core.state import AppState
import os

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("PI - AI Browser by P")
        self.state = AppState()

        # Apply modern styling
        self.apply_modern_style()

        # Create central widget container with stacked layout
        central_widget = QWidget()
        central_layout = QHBoxLayout(central_widget)
        central_layout.setContentsMargins(0, 0, 0, 0)
        central_layout.setSpacing(0)
        
        # Left sidebar (icon strip)
        self.left_sidebar = LeftSidebar(self.state, None, parent=self)
        self.left_sidebar.menu_clicked.connect(self.on_menu_clicked)
        central_layout.addWidget(self.left_sidebar)
        
        # Stacked widget for main content
        self.stacked_widget = QStackedWidget()
        
        # Features grid (default view)
        self.features_grid = FeaturesGrid()
        self.features_grid.feature_clicked.connect(self.on_feature_clicked)
        self.stacked_widget.addWidget(self.features_grid)
        
        # Browser view
        self.browser = BrowserView(self.state)
        self.stacked_widget.addWidget(self.browser)
        
        # Set browser reference in left sidebar after creation
        self.left_sidebar.browser = self.browser
        
        central_layout.addWidget(self.stacked_widget)
        self.setCentralWidget(central_widget)
        
        # Show features grid by default
        self.stacked_widget.setCurrentWidget(self.features_grid)

        # Header and footer
        self.header = HeaderBar(self.state, self.browser, parent=self)
        self.addToolBar(self.header)
        self.footer = FooterBar(self.state, parent=self)
        self.setStatusBar(self.footer)

        # Right sidebar dock (AI Assistant)
        dock = QDockWidget("AI Assistant", self)
        dock.setAllowedAreas(Qt.RightDockWidgetArea)
        dock.setFeatures(QDockWidget.DockWidgetMovable | QDockWidget.DockWidgetFloatable)
        self.sidebar = SideBar(self.state, self.browser)
        dock.setWidget(self.sidebar)
        self.addDockWidget(Qt.RightDockWidgetArea, dock)
        
        # Connect URL changes to show/hide welcome screen
        self.state.url_changed.connect(self.on_url_changed)
        
        # Set initial size and position
        self.resize(1400, 900)
        self.setMinimumSize(800, 600)
        
        # Center window on screen
        self.center_window()
    
    def on_menu_clicked(self, menu_item):
        """Handle menu item clicks from left sidebar"""
        if menu_item == "browser":
            # Switch to browser view
            self.stacked_widget.setCurrentWidget(self.browser)
        # Other menu items are handled by the left sidebar itself
    
    def on_feature_clicked(self, feature_name):
        """Handle feature card clicks"""
        if feature_name == "chat":
            # Switch to browser and focus on chat
            self.stacked_widget.setCurrentWidget(self.browser)
            # You could add logic here to highlight the chat sidebar
        elif feature_name == "analysis":
            # Switch to browser and open tools
            self.stacked_widget.setCurrentWidget(self.browser)
            # You could add logic here to open the tools menu
        elif feature_name == "settings":
            # Switch to browser and open settings
            self.stacked_widget.setCurrentWidget(self.browser)
            # You could add logic here to open settings
        else:
            # For other features, just switch to browser
            self.stacked_widget.setCurrentWidget(self.browser)
    
    def on_url_changed(self, url):
        """Handle URL changes to show/hide welcome screen"""
        if not url or url.strip() == "":
            # Show welcome screen when URL is empty
            self.stacked_widget.setCurrentWidget(self.features_grid)
        else:
            # Show browser when URL is loaded
            self.stacked_widget.setCurrentWidget(self.browser)
    
    def apply_modern_style(self):
        """Apply Chrome-like modern styling"""
        # Load stylesheet
        style_path = os.path.join(os.path.dirname(__file__), "..", "assets", "styles", "chrome_style.qss")
        if os.path.exists(style_path):
            with open(style_path, 'r') as f:
                self.setStyleSheet(f.read())
        
        # Set macOS native font
        font = QFont("SF Pro Display", 9)
        font.setStyleHint(QFont.SansSerif)
        self.setFont(font)
    
    def center_window(self):
        """Center the window on the screen"""
        screen = self.screen().availableGeometry()
        size = self.size()
        self.move(
            (screen.width() - size.width()) // 2,
            (screen.height() - size.height()) // 2
        )

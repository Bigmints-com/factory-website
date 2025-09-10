from PySide6.QtWidgets import QToolBar, QLineEdit, QWidget, QHBoxLayout, QSizePolicy, QDockWidget, QPushButton
from PySide6.QtGui import QAction
from PySide6.QtCore import Qt
from app.ui.widgets.features_modal import FeaturesModal
from app.ui.widgets.tools_menu import ToolsMenu
from app.core.icons import icon_manager

class HeaderBar(QToolBar):
    def __init__(self, state, browser, parent=None):
        super().__init__(parent)
        self.state = state
        self.browser = browser
        self.parent_window = parent
        self.setMovable(False)
        self.setToolButtonStyle(Qt.ToolButtonIconOnly)
        self.setStyleSheet("""
            QToolBar {
                background-color: #2d2d2d;
                border: none;
                border-bottom: 1px solid #404040;
                padding: 6px 8px;
                spacing: 6px;
            }
            QToolBar QAction {
                background-color: transparent;
                border: none;
                border-radius: 12px;
               
                font-size: 128px;
                color: #cccccc;
               
            }
            QToolBar QAction:hover {
                background-color: #404040;
                color: #ffffff;
            }
            QToolBar QAction:pressed {
                background-color: #007AFF;
                color: #ffffff;
            }
            QToolBar QAction:disabled {
                color: #666666;
            }
        """)
        
        # Sidebar toggle button (VS Code style)
        self.act_sidebar_toggle = QAction(self)
        self.act_sidebar_toggle.setIcon(icon_manager.get_icon("menu", 20, "#cccccc"))
        self.act_sidebar_toggle.setToolTip("Toggle AI Sidebar")
        self.act_sidebar_toggle.triggered.connect(self.toggle_sidebar)
        self.addAction(self.act_sidebar_toggle)
        
        self.addSeparator()
        
        # Navigation buttons - Chrome style with Feather icons
        self.act_back = QAction(self)
        self.act_back.setIcon(icon_manager.get_icon("arrow-left", 20, "#cccccc"))
        self.act_back.setToolTip("Back")
        self.act_back.triggered.connect(browser.back)
        self.addAction(self.act_back)
        
        self.act_forward = QAction(self)
        self.act_forward.setIcon(icon_manager.get_icon("arrow-right", 20, "#cccccc"))
        self.act_forward.setToolTip("Forward")
        self.act_forward.triggered.connect(browser.forward)
        self.addAction(self.act_forward)
        
        self.act_reload = QAction(self)
        self.act_reload.setIcon(icon_manager.get_icon("refresh-cw", 20, "#cccccc"))
        self.act_reload.setToolTip("Reload")
        self.act_reload.triggered.connect(browser.reload)
        self.addAction(self.act_reload)
        
        self.act_home = QAction(self)
        self.act_home.setIcon(icon_manager.get_icon("home", 20, "#cccccc"))
        self.act_home.setToolTip("Home")
        self.act_home.triggered.connect(browser.home)
        self.addAction(self.act_home)
        
        self.addSeparator()
        
        # Address bar container with submit button
        addr_container = QWidget()
        addr_layout = QHBoxLayout(addr_container)
        addr_layout.setContentsMargins(0, 0, 0, 0)
        addr_layout.setSpacing(4)
        
        # Address bar (search/URL input) - Chrome style
        self.addr = QLineEdit()
        self.addr.setPlaceholderText("Search Google or type a URL")
        self.addr.returnPressed.connect(self.navigate)
        self.addr.setObjectName("addressBar")
        self.addr.setStyleSheet("""
            QLineEdit#addressBar {
                background-color: #3a3a3a;
                border: 2px solid #555555;
                border-radius: 20px;
                padding: 10px 20px;
                font-size: 15px;
                color: #ffffff;
                selection-background-color: #007AFF;
                selection-color: white;
                min-width: 500px;
                font-weight: 400;
            }
            QLineEdit#addressBar:focus {
                border-color: #007AFF;
                background-color: #4a4a4a;
            }
            QLineEdit#addressBar::placeholder {
                color: #888888;
                font-style: normal;
            }
        """)
        addr_layout.addWidget(self.addr)
        
        # Submit button
        self.submit_btn = QPushButton("Go")
        self.submit_btn.setToolTip("Go to URL")
        self.submit_btn.clicked.connect(self.navigate)
        self.submit_btn.setStyleSheet("""
            QPushButton {
                background-color: #000000;
                color: white;
                border: none;
                border-radius: 16px;
                padding: 0px 0px;
                font-weight: 500;
                font-size: 14px;
                min-width: 50px;
            }
            QPushButton:hover {
                background-color: #1557b0;
            }
            QPushButton:pressed {
                background-color: #0d47a1;
            }
        """)
        addr_layout.addWidget(self.submit_btn)
        
        self.addWidget(addr_container)
        
        # Update address bar when URL changes
        self.state.url_changed.connect(self.update_address)
        
        self.addSeparator()
        
        # Tools button
        self.act_tools = QAction(self)
        self.act_tools.setIcon(icon_manager.get_icon("settings", 20, "#cccccc"))
        self.act_tools.setToolTip("Tools & Analysis")
        self.act_tools.triggered.connect(self.open_tools)
        self.addAction(self.act_tools)
        
        # Add stretch to push everything to the left
        spacer = QWidget()
        spacer.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        self.addWidget(spacer)
    
    def navigate(self):
        """Navigate to the address bar content"""
        text = self.addr.text().strip()
        if text:
            self.browser.navigate(text)
    
    def update_address(self, url):
        """Update address bar when URL changes"""
        if self.addr.text() != url:
            self.addr.setText(url)
    
    
    def toggle_sidebar(self):
        """Toggle sidebar visibility (VS Code style)"""
        if self.parent_window:
            # Find the dock widget
            dock_widgets = self.parent_window.findChildren(QDockWidget)
            for dock in dock_widgets:
                if "AI Assistant" in dock.windowTitle():
                    if dock.isVisible():
                        dock.hide()
                        self.act_sidebar_toggle.setToolTip("Show Sidebar")
                    else:
                        dock.show()
                        self.act_sidebar_toggle.setToolTip("Hide Sidebar")
                    break
    
    def open_tools(self):
        """Open tools menu"""
        from app.ui.widgets.tools_menu import ToolsMenu
        menu = ToolsMenu(self.state, self.browser, self)
        menu.exec(self.mapToGlobal(self.rect().bottomRight()))

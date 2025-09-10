from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QPushButton, 
                               QListWidget, QListWidgetItem, QLabel, QSplitter)
from PySide6.QtCore import Qt
from app.ui.widgets.settings_dialog import SettingsDialog
from app.ui.widgets.chat_panel import ChatPanel
from app.core.icons import icon_manager

class SideBar(QWidget):
    def __init__(self, state, browser):
        super().__init__()
        self.state = state
        self.browser = browser
        
        self.setup_ui()
        self.connect_signals()
        self.load_threads()
    
    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        
        # Chat header with title and action buttons
        header_widget = QWidget()
        header_widget.setStyleSheet("""
            QWidget {
                background-color: #2d2d2d;
                border-bottom: 1px solid #404040;
            }
        """)
        header_layout = QHBoxLayout(header_widget)
        header_layout.setContentsMargins(16, 12, 16, 12)
        header_layout.setSpacing(8)
        
        # Chat title
        title_label = QLabel("AI Assistant")
        title_label.setStyleSheet("""
            QLabel {
                font-size: 16px;
                font-weight: 600;
                color: #ffffff;
            }
        """)
        header_layout.addWidget(title_label)
        
        header_layout.addStretch()
        
        # Chat history dropdown button
        self.history_btn = QPushButton()
        self.history_btn.setIcon(icon_manager.get_icon("chevron-down", 16, "#cccccc"))
        self.history_btn.setToolTip("Chat History")
        self.history_btn.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                border: 1px solid #404040;
                border-radius: 6px;
                padding: 6px;
                color: #cccccc;
            }
            QPushButton:hover {
                background-color: #404040;
                border-color: #555555;
            }
            QPushButton:pressed {
                background-color: #007AFF;
                border-color: #007AFF;
                color: #ffffff;
            }
        """)
        self.history_btn.clicked.connect(self.toggle_chat_history)
        header_layout.addWidget(self.history_btn)
        
        # New chat button (small icon)
        self.new_chat_btn = QPushButton()
        self.new_chat_btn.setIcon(icon_manager.get_icon("plus", 16, "#ffffff"))
        self.new_chat_btn.setToolTip("New Chat")
        self.new_chat_btn.setStyleSheet("""
            QPushButton {
                background-color: #007AFF;
                border: none;
                border-radius: 6px;
                padding: 6px;
                color: #ffffff;
            }
            QPushButton:hover {
                background-color: #0056CC;
            }
            QPushButton:pressed {
                background-color: #004499;
            }
        """)
        self.new_chat_btn.clicked.connect(self.create_new_thread)
        header_layout.addWidget(self.new_chat_btn)
        
        # Settings button
        self.settings_btn = QPushButton()
        self.settings_btn.setIcon(icon_manager.get_icon("settings", 16, "#cccccc"))
        self.settings_btn.setToolTip("Settings")
        self.settings_btn.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                border: 1px solid #404040;
                border-radius: 6px;
                padding: 6px;
                color: #cccccc;
            }
            QPushButton:hover {
                background-color: #404040;
                border-color: #555555;
            }
            QPushButton:pressed {
                background-color: #007AFF;
                border-color: #007AFF;
                color: #ffffff;
            }
        """)
        self.settings_btn.clicked.connect(self.open_settings)
        header_layout.addWidget(self.settings_btn)
        
        layout.addWidget(header_widget)
        
        # Chat history dropdown (initially hidden)
        self.history_dropdown = QWidget()
        self.history_dropdown.setVisible(False)
        self.history_dropdown.setStyleSheet("""
            QWidget {
                background-color: #2d2d2d;
                border-bottom: 1px solid #404040;
            }
        """)
        history_layout = QVBoxLayout(self.history_dropdown)
        history_layout.setContentsMargins(16, 8, 16, 8)
        history_layout.setSpacing(4)
        
        # Thread list in dropdown
        self.threads_list = QListWidget()
        self.threads_list.setMaximumHeight(200)
        self.threads_list.itemClicked.connect(self.on_thread_selected)
        self.threads_list.setStyleSheet("""
            QListWidget {
                background-color: #1a1a1a;
                border: 1px solid #404040;
                border-radius: 8px;
                padding: 4px;
                font-size: 13px;
                color: #ffffff;
            }
            QListWidget::item {
                padding: 8px 12px;
                border-radius: 4px;
                margin: 2px;
                color: #ffffff;
            }
            QListWidget::item:hover {
                background-color: #404040;
            }
            QListWidget::item:selected {
                background-color: #007AFF;
                color: white;
            }
        """)
        history_layout.addWidget(self.threads_list)
        
        # Quick actions in dropdown
        actions_layout = QHBoxLayout()
        actions_layout.setSpacing(4)
        
        self.clear_btn = self.create_action_button("trash-2", "Clear")
        self.clear_btn.clicked.connect(self.clear_current_chat)
        actions_layout.addWidget(self.clear_btn)
        
        self.export_btn = self.create_action_button("download", "Export")
        self.export_btn.clicked.connect(self.export_chat)
        actions_layout.addWidget(self.export_btn)
        
        self.bookmark_btn = self.create_action_button("bookmark", "Bookmark")
        self.bookmark_btn.clicked.connect(self.bookmark_chat)
        actions_layout.addWidget(self.bookmark_btn)
        
        actions_layout.addStretch()
        history_layout.addLayout(actions_layout)
        
        layout.addWidget(self.history_dropdown)
        
        # Chat panel (main content)
        self.chat_panel = ChatPanel(self.state, self.browser)
        layout.addWidget(self.chat_panel)
    
    def connect_signals(self):
        self.state.chat_updated.connect(self.load_threads)
    
    def load_threads(self):
        """Load chat threads into the list"""
        self.threads_list.clear()
        
        for thread in self.state.chat_threads:
            item = QListWidgetItem(thread["title"])
            item.setData(Qt.UserRole, thread["id"])
            self.threads_list.addItem(item)
        
        # Select current thread
        if self.state.current_thread_id:
            for i in range(self.threads_list.count()):
                item = self.threads_list.item(i)
                if item.data(Qt.UserRole) == self.state.current_thread_id:
                    self.threads_list.setCurrentItem(item)
                    break
    
    def on_thread_selected(self, item):
        """Handle thread selection"""
        thread_id = item.data(Qt.UserRole)
        if thread_id != self.state.current_thread_id:
            self.state.current_thread_id = thread_id
            self.chat_panel.load_messages()
    
    def create_new_thread(self):
        """Create a new chat thread"""
        self.state.create_new_thread()
        # Select the new thread
        if self.threads_list.count() > 0:
            self.threads_list.setCurrentRow(0)
            self.on_thread_selected(self.threads_list.currentItem())
    
    def toggle_chat_history(self):
        """Toggle chat history dropdown"""
        is_visible = self.history_dropdown.isVisible()
        self.history_dropdown.setVisible(not is_visible)
        
        # Update icon based on state
        if is_visible:
            self.history_btn.setIcon(icon_manager.get_icon("chevron-down", 16, "#cccccc"))
        else:
            self.history_btn.setIcon(icon_manager.get_icon("chevron-up", 16, "#cccccc"))
    
    def create_action_button(self, icon_name, tooltip):
        """Create an action button with icon"""
        btn = QPushButton()
        btn.setIcon(icon_manager.get_icon(icon_name, 14, "#cccccc"))
        btn.setToolTip(tooltip)
        btn.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                border: 1px solid #404040;
                border-radius: 4px;
                padding: 6px 8px;
                color: #cccccc;
                font-size: 11px;
                text-align: left;
                margin: 1px;
            }
            QPushButton:hover {
                background-color: #404040;
                border-color: #555555;
                color: #ffffff;
            }
            QPushButton:pressed {
                background-color: #007AFF;
                border-color: #007AFF;
                color: #ffffff;
            }
        """)
        return btn
    
    def clear_current_chat(self):
        """Clear the current chat"""
        if self.state.current_thread_id:
            # Clear messages for current thread
            self.state.clear_thread_messages(self.state.current_thread_id)
            self.chat_panel.load_messages()
    
    def export_chat(self):
        """Export current chat"""
        if self.state.current_thread_id:
            # TODO: Implement chat export functionality
            print("Export chat functionality - TODO")
    
    def bookmark_chat(self):
        """Bookmark current chat"""
        if self.state.current_thread_id:
            # TODO: Implement bookmark functionality
            print("Bookmark chat functionality - TODO")
    
    def open_settings(self):
        """Open settings dialog"""
        dlg = SettingsDialog(self.state, self)
        dlg.exec()

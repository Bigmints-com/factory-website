from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QTextEdit, 
                               QLineEdit, QPushButton, QComboBox, QLabel, QScrollArea)
from PySide6.QtCore import Qt, QThread, Signal, QTimer
from PySide6.QtGui import QFont
import asyncio
from app.core.llm import LLMClient
from app.core.icons import icon_manager

class ChatWorker(QThread):
    message_updated = Signal(str)  # content chunk
    finished = Signal()
    
    def __init__(self, messages, llm_client, model):
        super().__init__()
        self.messages = messages
        self.llm_client = llm_client
        self.model = model
        self.current_content = ""
    
    def run(self):
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            async def stream_chat():
                async for chunk in self.llm_client.stream_chat(self.messages, self.model):
                    self.current_content += chunk
                    self.message_updated.emit(chunk)
            
            loop.run_until_complete(stream_chat())
            self.finished.emit()
            
        except Exception as e:
            self.message_updated.emit(f"Error: {str(e)}")
            self.finished.emit()
        finally:
            loop.close()

class ChatPanel(QWidget):
    def __init__(self, state, browser):
        super().__init__()
        self.state = state
        self.browser = browser
        self.llm_client = LLMClient(state.config)
        self.current_worker = None
        
        self.setup_ui()
        self.connect_signals()
    
    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        
        # Chat display with scroll area for better bubble layout
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
        
        # Chat container for bubbles
        self.chat_container = QWidget()
        self.chat_layout = QVBoxLayout(self.chat_container)
        self.chat_layout.setContentsMargins(16, 16, 16, 16)
        self.chat_layout.setSpacing(12)
        self.chat_layout.addStretch()  # Push bubbles to top
        
        scroll_area.setWidget(self.chat_container)
        layout.addWidget(scroll_area)
        
        # Store reference to scroll area for auto-scrolling
        self.scroll_area = scroll_area
        
        # Input area container
        input_container = QWidget()
        input_container.setStyleSheet("""
            QWidget {
                background-color: #2d2d2d;
                border-top: 1px solid #404040;
            }
        """)
        input_layout = QVBoxLayout(input_container)
        input_layout.setContentsMargins(16, 12, 16, 12)
        input_layout.setSpacing(8)
        
        # Model selector row
        model_layout = QHBoxLayout()
        model_layout.setContentsMargins(0, 0, 0, 0)
        
        model_label = QLabel("Model:")
        model_label.setStyleSheet("""
            QLabel {
                color: #cccccc;
                font-size: 12px;
                font-weight: 500;
            }
        """)
        model_layout.addWidget(model_label)
        
        self.model_combo = QComboBox()
        self.model_combo.addItems(self.state.models)
        self.model_combo.setCurrentText(self.state.default_model)
        self.model_combo.setMaximumWidth(150)
        self.model_combo.setStyleSheet("""
            QComboBox {
                background-color: #3a3a3a;
                border: 1px solid #555555;
                border-radius: 6px;
                padding: 6px 12px;
                font-size: 12px;
                color: #ffffff;
                min-width: 120px;
            }
            QComboBox:hover {
                border-color: #007AFF;
            }
            QComboBox::drop-down {
                border: none;
                width: 16px;
            }
            QComboBox::down-arrow {
                image: none;
                border-left: 4px solid transparent;
                border-right: 4px solid transparent;
                border-top: 4px solid #cccccc;
                margin-right: 4px;
            }
            QComboBox QAbstractItemView {
                background-color: #3a3a3a;
                border: 1px solid #555555;
                color: #ffffff;
                selection-background-color: #007AFF;
            }
        """)
        model_layout.addWidget(self.model_combo)
        model_layout.addStretch()
        
        input_layout.addLayout(model_layout)
        
        # Message input row
        message_layout = QHBoxLayout()
        message_layout.setContentsMargins(0, 0, 0, 0)
        message_layout.setSpacing(8)
        
        # Message input - Modern AI Chat style
        self.message_input = QLineEdit()
        self.message_input.setPlaceholderText("Ask me anything...")
        self.message_input.returnPressed.connect(self.send_message)
        self.message_input.setStyleSheet("""
            QLineEdit {
                background-color: #3a3a3a;
                border: 1px solid #555555;
                border-radius: 20px;
                padding: 12px 20px;
                font-size: 14px;
                color: #ffffff;
                font-family: "SF Pro Display", "Helvetica Neue", "Arial", sans-serif;
            }
            QLineEdit:focus {
                border-color: #007AFF;
                background-color: #4a4a4a;
            }
            QLineEdit::placeholder {
                color: #888888;
                font-style: italic;
            }
        """)
        message_layout.addWidget(self.message_input)
        
        # Send button - Modern AI Chat style
        self.send_btn = QPushButton()
        self.send_btn.setIcon(icon_manager.get_icon("send", 18, "#ffffff"))
        self.send_btn.setToolTip("Send message")
        self.send_btn.clicked.connect(self.send_message)
        self.send_btn.setStyleSheet("""
            QPushButton {
                background-color: #007AFF;
                color: white;
                border: none;
                border-radius: 20px;
                padding: 12px 16px;
                font-weight: 500;
                font-size: 14px;
                min-width: 50px;
            }
            QPushButton:hover {
                background-color: #0056CC;
            }
            QPushButton:pressed {
                background-color: #004499;
            }
            QPushButton:disabled {
                background-color: #555555;
                color: #888888;
            }
        """)
        message_layout.addWidget(self.send_btn)
        
        input_layout.addLayout(message_layout)
        layout.addWidget(input_container)
    
    def connect_signals(self):
        self.state.chat_updated.connect(self.load_messages)
        self.state.settings_changed.connect(self.update_models)
    
    def update_models(self):
        """Update model list when settings change"""
        current = self.model_combo.currentText()
        self.model_combo.clear()
        self.model_combo.addItems(self.state.models)
        
        # Try to restore previous selection
        if current in self.state.models:
            self.model_combo.setCurrentText(current)
        elif self.state.models:
            self.model_combo.setCurrentText(self.state.models[0])
        else:
            self.model_combo.setCurrentText("No models available")
    
    def load_messages(self):
        """Load and display messages for current thread"""
        if not self.state.current_thread_id:
            return
        
        # Clear existing messages
        for i in reversed(range(self.chat_layout.count())):
            child = self.chat_layout.itemAt(i).widget()
            if child and child != self.chat_layout.itemAt(i).spacerItem():
                child.setParent(None)
        
        messages = self.state.get_messages(self.state.current_thread_id)
        
        # Add messages as bubbles
        for message in messages:
            self.add_message_bubble(message)
        
        # Auto-scroll to bottom
        self.scroll_to_bottom()
    
    def add_message_bubble(self, message):
        """Add a message bubble to the chat"""
        from PySide6.QtWidgets import QWidget, QHBoxLayout, QVBoxLayout, QLabel
        from PySide6.QtCore import Qt
        from PySide6.QtGui import QFont
        
        role = message["role"]
        content = message["content"]
        timestamp = message.get("timestamp", "")
        
        # Create message bubble widget
        bubble_widget = QWidget()
        bubble_layout = QHBoxLayout(bubble_widget)
        bubble_layout.setContentsMargins(0, 0, 0, 0)
        bubble_layout.setSpacing(12)
        
        # Avatar
        avatar_label = QLabel()
        avatar_label.setFixedSize(36, 36)
        avatar_label.setAlignment(Qt.AlignCenter)
        avatar_label.setStyleSheet("""
            QLabel {
                border-radius: 18px;
                font-size: 16px;
                font-weight: 600;
                color: white;
            }
        """)
        
        if role == "user":
            avatar_label.setText("U")
            avatar_label.setStyleSheet(avatar_label.styleSheet() + "background-color: #007AFF;")
            bubble_layout.addStretch()  # Push user messages to right
        elif role == "assistant":
            avatar_label.setText("AI")
            avatar_label.setStyleSheet(avatar_label.styleSheet() + "background-color: #30D158;")
        elif role == "tool":
            avatar_label.setText("⚙️")
            avatar_label.setStyleSheet(avatar_label.styleSheet() + "background-color: #FF9F0A;")
        
        bubble_layout.addWidget(avatar_label)
        
        # Message content
        content_widget = QWidget()
        content_layout = QVBoxLayout(content_widget)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(4)
        
        # Content text
        content_label = QLabel()
        content_label.setWordWrap(True)
        content_label.setTextFormat(Qt.RichText)
        content_label.setText(self.format_message_content(content))
        content_label.setStyleSheet("""
            QLabel {
                background-color: #2d2d2d;
                border: 1px solid #404040;
                border-radius: 12px;
                padding: 12px 16px;
                font-size: 14px;
                color: #ffffff;
                max-width: 300px;
            }
        """)
        
        if role == "user":
            content_label.setStyleSheet("""
                QLabel {
                    background-color: #007AFF;
                    border: none;
                    border-radius: 12px;
                    padding: 12px 16px;
                    font-size: 14px;
                    color: #ffffff;
                    max-width: 300px;
                }
            """)
        elif role == "tool":
            content_label.setStyleSheet("""
                QLabel {
                    background-color: #1a1a1a;
                    border: 1px solid #FF9F0A;
                    border-radius: 12px;
                    padding: 12px 16px;
                    font-size: 14px;
                    color: #FF9F0A;
                    max-width: 300px;
                }
            """)
        
        content_layout.addWidget(content_label)
        
        # Timestamp
        if timestamp:
            timestamp_label = QLabel(timestamp)
            timestamp_label.setStyleSheet("""
                QLabel {
                    font-size: 11px;
                    color: #888888;
                    padding: 0 4px;
                }
            """)
            if role == "user":
                timestamp_label.setAlignment(Qt.AlignRight)
            content_layout.addWidget(timestamp_label)
        
        bubble_layout.addWidget(content_widget)
        
        if role != "user":
            bubble_layout.addStretch()  # Push assistant messages to left
        
        # Add to chat layout
        self.chat_layout.addWidget(bubble_widget)
    
    def scroll_to_bottom(self):
        """Scroll to bottom of chat"""
        if hasattr(self, 'scroll_area'):
            scrollbar = self.scroll_area.verticalScrollBar()
            scrollbar.setValue(scrollbar.maximum())
    
    def format_message_content(self, content):
        """Format message content with basic markdown-like styling"""
        # Simple formatting for now - can be enhanced later
        content = content.replace('\n', '<br>')
        content = content.replace('**', '<b>').replace('**', '</b>')
        content = content.replace('*', '<i>').replace('*', '</i>')
        content = content.replace('`', '<code>').replace('`', '</code>')
        return content
    
    def send_message(self):
        """Send message to LLM"""
        text = self.message_input.text().strip()
        if not text or self.current_worker:
            return
        
        # Clear input
        self.message_input.clear()
        
        # Add user message
        self.state.add_message(self.state.current_thread_id, "user", text)
        
        # Add user message bubble
        user_message = {
            "role": "user",
            "content": text,
            "timestamp": "now"
        }
        self.add_message_bubble(user_message)
        self.scroll_to_bottom()
        
        # Start LLM response
        self.start_llm_response()
    
    def start_llm_response(self):
        """Start LLM response streaming"""
        if not self.state.current_thread_id:
            return
        
        # Get messages for current thread
        messages = self.state.get_messages(self.state.current_thread_id)
        
        # Start worker thread
        self.current_worker = ChatWorker(messages, self.llm_client, self.model_combo.currentText())
        self.current_worker.message_updated.connect(self.append_response_chunk)
        self.current_worker.finished.connect(self.finish_response)
        self.current_worker.start()
        
        # Add thinking indicator
        thinking_message = {
            "role": "assistant",
            "content": "Thinking...",
            "timestamp": "now"
        }
        self.add_message_bubble(thinking_message)
        self.scroll_to_bottom()
    
    def append_response_chunk(self, chunk):
        """Append chunk to current response"""
        # This is a simplified version - in a real implementation,
        # you'd want to update the last message bubble
        pass
    
    def finish_response(self):
        """Finish LLM response"""
        self.current_worker = None
        # Reload messages to show the complete response
        self.load_messages()

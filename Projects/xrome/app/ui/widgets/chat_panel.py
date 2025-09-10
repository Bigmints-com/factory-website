from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QTextEdit, 
                               QLineEdit, QPushButton, QComboBox, QLabel, QScrollArea, QSizePolicy)
from PySide6.QtCore import Qt, QThread, Signal, QTimer, QEvent
from PySide6.QtGui import QFont
import asyncio
import re
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
        loop = None
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            async def stream_response():
                # Get page data for context
                page_data = None
                if hasattr(self, 'browser') and self.browser:
                    try:
                        page_data = await self.browser.extract_page_content_async()
                        print(f"DEBUG: Page data extracted: {page_data}")  # Debug output
                    except Exception as e:
                        print(f"DEBUG: Page extraction failed: {e}")  # Debug output
                        # Provide basic context even if extraction fails
                        page_data = {
                            "url": getattr(self.browser.state, 'current_url', ''),
                            "title": getattr(self.browser.state, 'title', ''),
                            "textContent": f"Current website: {getattr(self.browser.state, 'title', 'Unknown')} at {getattr(self.browser.state, 'current_url', 'Unknown')}"
                        }
                
                async for chunk in self.llm_client.stream_response(self.messages, page_data, self.model):
                    self.current_content += chunk
                    self.message_updated.emit(chunk)
            
            loop.run_until_complete(stream_response())
            self.finished.emit()
            
        except Exception as e:
            print(f"ChatWorker error: {str(e)}")
            self.message_updated.emit(f"Error: {str(e)}")
            self.finished.emit()
        finally:
            if loop and not loop.is_closed():
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
        self.setup_responsive_behavior()
    
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
        
        # Chat container for bubbles with responsive design
        self.chat_container = QWidget()
        self.chat_container.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        self.chat_container.setStyleSheet("""
            QWidget {
                background-color: #1a1a1a;
            }
        """)
        
        # Use full width directly without wrapper constraints
        self.chat_layout = QVBoxLayout(self.chat_container)
        self.chat_layout.setContentsMargins(8, 16, 8, 16)  # Minimal margins
        self.chat_layout.setSpacing(16)
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
        
        # Create message bubble widget with full responsive design
        bubble_widget = QWidget()
        bubble_widget.setStyleSheet("""
            QWidget {
                background-color: transparent;
            }
        """)
        bubble_widget.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        
        # Create the main layout for the bubble - ensure full width usage
        bubble_layout = QHBoxLayout(bubble_widget)
        bubble_layout.setContentsMargins(0, 0, 0, 0)
        bubble_layout.setSpacing(16)
        # Layout will use full available width by default
        
        # Avatar
        avatar_label = QLabel()
        avatar_label.setFixedSize(32, 32)
        avatar_label.setAlignment(Qt.AlignCenter)
        avatar_label.setStyleSheet("""
            QLabel {
                border-radius: 16px;
                font-size: 14px;
                font-weight: 600;
                color: white;
            }
        """)
        
        # Content text with full responsive design
        content_label = QLabel()
        content_label.setWordWrap(True)
        content_label.setTextFormat(Qt.RichText)
        content_label.setText(self.format_message_content(content))
        content_label.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        # Force full width usage
        content_label.setMinimumWidth(200)
        content_label.setMaximumWidth(16777215)
        # Ensure the label expands to fill available space
        content_label.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        
        if role == "user":
            avatar_label.setText("U")
            avatar_label.setStyleSheet(avatar_label.styleSheet() + "background-color: #007AFF;")
            # User messages: avatar on right, content on left - content takes full width
            bubble_layout.addWidget(content_label, 1)  # Stretch factor 1 for full width
            bubble_layout.addWidget(avatar_label, 0)  # No stretch for avatar
        elif role == "assistant":
            avatar_label.setText("AI")
            avatar_label.setStyleSheet(avatar_label.styleSheet() + "background-color: #30D158;")
            # Assistant messages: avatar on left, content on right - content takes full width
            bubble_layout.addWidget(avatar_label, 0)  # No stretch for avatar
            bubble_layout.addWidget(content_label, 1)  # Stretch factor 1 for full width
        elif role == "tool":
            avatar_label.setText("⚙️")
            avatar_label.setStyleSheet(avatar_label.styleSheet() + "background-color: #FF9F0A;")
            # Tool messages: avatar on left, content on right - content takes full width
            bubble_layout.addWidget(avatar_label, 0)  # No stretch for avatar
            bubble_layout.addWidget(content_label, 1)  # Stretch factor 1 for full width
        
        # Apply styling to the content label
        content_label.setStyleSheet("""
            QLabel {
                background-color: #2d2d2d;
                border: 1px solid #404040;
                border-radius: 18px;
                padding: 24px 28px;
                font-size: 16px;
                color: #ffffff;
                line-height: 1.7;
                font-family: "SF Pro Display", "Helvetica Neue", "Arial", sans-serif;
            }
            QLabel h1 {
                font-size: 28px;
                font-weight: 700;
                color: #ffffff;
                margin: 20px 0 16px 0;
                line-height: 1.3;
            }
            QLabel h2 {
                font-size: 24px;
                font-weight: 600;
                color: #ffffff;
                margin: 18px 0 14px 0;
                line-height: 1.3;
            }
            QLabel h3 {
                font-size: 20px;
                font-weight: 600;
                color: #ffffff;
                margin: 16px 0 12px 0;
                line-height: 1.3;
            }
            QLabel h4 {
                font-size: 18px;
                font-weight: 600;
                color: #ffffff;
                margin: 14px 0 10px 0;
                line-height: 1.3;
            }
            QLabel p {
                margin: 8px 0;
                line-height: 1.7;
            }
            QLabel ul, QLabel ol {
                margin: 12px 0;
                padding-left: 24px;
            }
            QLabel li {
                margin: 6px 0;
                color: #ffffff;
                line-height: 1.6;
            }
            QLabel code {
                background-color: #404040;
                color: #ffffff;
                padding: 3px 8px;
                border-radius: 6px;
                font-family: "Monaco", "Menlo", "Consolas", "Courier New", monospace;
                font-size: 14px;
                font-weight: 500;
            }
            QLabel .code-block {
                background-color: #1a1a1a;
                border: 1px solid #404040;
                border-radius: 12px;
                margin: 16px 0;
                overflow: hidden;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            }
            QLabel .code-header {
                background-color: #2d2d2d;
                border-bottom: 1px solid #404040;
                padding: 12px 20px;
                font-size: 13px;
                color: #cccccc;
                font-family: "Monaco", "Menlo", "Consolas", "Courier New", monospace;
                font-weight: 500;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            QLabel pre {
                background-color: #1a1a1a;
                color: #ffffff;
                padding: 20px;
                margin: 0;
                overflow-x: auto;
                font-family: "Monaco", "Menlo", "Consolas", "Courier New", monospace;
                font-size: 14px;
                line-height: 1.5;
                white-space: pre;
            }
            QLabel blockquote {
                border-left: 4px solid #007AFF;
                background-color: #2d2d2d;
                margin: 16px 0;
                padding: 16px 20px;
                border-radius: 0 12px 12px 0;
                color: #cccccc;
                font-style: italic;
                line-height: 1.6;
            }
            QLabel strong {
                font-weight: 700;
                color: #ffffff;
            }
            QLabel em {
                font-style: italic;
                color: #cccccc;
            }
            QLabel a {
                color: #007AFF;
                text-decoration: none;
            }
            QLabel a:hover {
                text-decoration: underline;
            }
            QLabel table {
                border-collapse: collapse;
                margin: 16px 0;
                width: 100%;
            }
            QLabel th, QLabel td {
                border: 1px solid #404040;
                padding: 12px 16px;
                text-align: left;
            }
            QLabel th {
                background-color: #404040;
                font-weight: 600;
                color: #ffffff;
            }
            QLabel td {
                background-color: #2d2d2d;
                color: #ffffff;
            }
        """)
        
        if role == "user":
            content_label.setStyleSheet("""
                QLabel {
                    background-color: #007AFF;
                    border: none;
                    border-radius: 18px;
                    padding: 24px 28px;
                    font-size: 16px;
                    color: #ffffff;
                    line-height: 1.7;
                    font-family: "SF Pro Display", "Helvetica Neue", "Arial", sans-serif;
                }
                QLabel h1, QLabel h2, QLabel h3, QLabel h4 {
                    color: #ffffff;
                    font-weight: 700;
                }
                QLabel p {
                    color: #ffffff;
                    line-height: 1.7;
                }
                QLabel li {
                    color: #ffffff;
                    line-height: 1.6;
                }
                QLabel strong {
                    color: #ffffff;
                    font-weight: 700;
                }
                QLabel em {
                    color: #ffffff;
                    font-style: italic;
                }
                QLabel code {
                    background-color: rgba(255, 255, 255, 0.2);
                    color: #ffffff;
                    padding: 3px 8px;
                    border-radius: 6px;
                    font-family: "Monaco", "Menlo", "Consolas", "Courier New", monospace;
                    font-size: 14px;
                    font-weight: 500;
                }
            """)
        elif role == "tool":
            content_label.setStyleSheet("""
                QLabel {
                    background-color: #1a1a1a;
                    border: 1px solid #FF9F0A;
                    border-radius: 12px;
                    padding: 16px 20px;
                    font-size: 15px;
                    color: #FF9F0A;
                    line-height: 1.6;
                    max-width: 100%;
                    font-family: "SF Mono", "Monaco", "Inconsolata", "Roboto Mono", monospace;
                }
            """)
        
        # Content label is already added to bubble_layout above
        
        # Add timestamp if available
        if timestamp:
            timestamp_label = QLabel(timestamp)
            timestamp_label.setStyleSheet("""
                QLabel {
                    color: #888888;
                    font-size: 12px;
                    margin-top: 4px;
                }
            """)
            if role == "user":
                timestamp_label.setAlignment(Qt.AlignRight)
            bubble_layout.addWidget(timestamp_label)
        
        # Add to chat layout - ensure full width usage
        self.chat_layout.addWidget(bubble_widget, 0, Qt.AlignTop)
    
    def scroll_to_bottom(self):
        """Scroll to bottom of chat"""
        if hasattr(self, 'scroll_area'):
            scrollbar = self.scroll_area.verticalScrollBar()
            scrollbar.setValue(scrollbar.maximum())
    
    def format_message_content(self, content):
        """Format message content with simple text rendering"""
        if not content:
            return ""
        
        # Clean up any existing HTML tags that shouldn't be displayed
        content = self.clean_html_tags(content)
        
        # Fix concatenated text by adding proper spacing
        content = self.fix_concatenated_text(content)
        
        # Convert to HTML with basic formatting
        content = content.replace('\n', '<br>')
        
        return content
    
    def fix_concatenated_text(self, content):
        """Fix concatenated text by adding proper spacing"""
        import re
        if not content:
            return content
            
        # Very aggressive text fixing
        # Add spaces before capital letters that follow lowercase letters
        content = re.sub(r'([a-z])([A-Z])', r'\1 \2', content)
        
        # Add spaces around punctuation
        content = re.sub(r'([a-zA-Z])([.!?])', r'\1 \2', content)
        content = re.sub(r'([a-zA-Z])([,:;])', r'\1 \2', content)
        content = re.sub(r'([a-zA-Z])([()])', r'\1 \2', content)
        content = re.sub(r'([()])([a-zA-Z])', r'\1 \2', content)
        
        # Fix specific common patterns
        content = re.sub(r"Idon't", "I don't", content)
        content = re.sub(r"I'm", "I'm", content)
        content = re.sub(r"I'll", "I'll", content)
        content = re.sub(r"I've", "I've", content)
        content = re.sub(r"Ican't", "I can't", content)
        content = re.sub(r"Ican", "I can", content)
        content = re.sub(r"Iam", "I am", content)
        content = re.sub(r"Iwill", "I will", content)
        content = re.sub(r"Ihave", "I have", content)
        content = re.sub(r"Iwould", "I would", content)
        content = re.sub(r"Ishould", "I should", content)
        content = re.sub(r"Icould", "I could", content)
        
        # Fix more patterns
        content = re.sub(r"([a-z])([A-Z][a-z]+)", r"\1 \2", content)
        content = re.sub(r"([a-z]+)([A-Z][a-z]+)", r"\1 \2", content)
        
        # Clean up multiple spaces
        content = re.sub(r'\s+', ' ', content)
        content = content.strip()
        
        return content
    
    def detect_and_format_content(self, content):
        """Detect and format different content types"""
        import re
        
        # Detect code blocks
        if '```' in content:
            content = self.format_code_blocks(content)
        
        # Detect lists
        if re.search(r'^\s*[-*+]\s', content, re.MULTILINE):
            content = self.format_lists(content)
        
        # Detect URLs
        content = self.format_urls(content)
        
        # Detect JSON/structured data
        if content.strip().startswith('{') or content.strip().startswith('['):
            content = self.format_json(content)
        
        return content
    
    def format_code_blocks(self, content):
        """Format code blocks with proper syntax highlighting"""
        import re
        # Handle ```language blocks
        def format_code_block(match):
            language = match.group(1) or 'text'
            code = match.group(2).strip()
            return f'<div class="code-block"><div class="code-header">{language}</div><pre>{code}</pre></div>'
        
        return re.sub(r'```(\w+)?\n(.*?)```', format_code_block, content, flags=re.DOTALL)
    
    def format_lists(self, content):
        """Format markdown lists"""
        import re
        lines = content.split('\n')
        in_list = False
        result = []
        
        for line in lines:
            if re.match(r'^\s*[-*+]\s', line):
                if not in_list:
                    result.append('<ul>')
                    in_list = True
                item = re.sub(r'^\s*[-*+]\s', '', line)
                result.append(f'<li>{item}</li>')
            else:
                if in_list:
                    result.append('</ul>')
                    in_list = False
                result.append(line)
        
        if in_list:
            result.append('</ul>')
        
        return '\n'.join(result)
    
    def format_urls(self, content):
        """Format URLs as clickable links"""
        import re
        url_pattern = r'https?://[^\s<>"{}|\\^`\[\]]+'
        return re.sub(url_pattern, r'<a href="\g<0>">\g<0></a>', content)
    
    def format_json(self, content):
        """Format JSON with syntax highlighting"""
        try:
            import json
            parsed = json.loads(content)
            formatted = json.dumps(parsed, indent=2)
            return f'<div class="code-block"><div class="code-header">JSON</div><pre>{formatted}</pre></div>'
        except:
            return content
    
    def clean_html_tags(self, content):
        """Remove unwanted HTML tags that shouldn't be displayed"""
        import re
        # Remove common unwanted HTML tags
        content = re.sub(r'</?div[^>]*>', '', content)
        content = re.sub(r'</?span[^>]*>', '', content)
        content = re.sub(r'</?p[^>]*>', '', content)
        content = re.sub(r'class="[^"]*"', '', content)
        content = re.sub(r'<div class="timestamp">[^<]*</div>', '', content)
        return content
    
    def escape_html(self, text):
        """Escape HTML special characters"""
        return (text.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace('"', "&quot;")
                    .replace("'", "&#x27;"))
    
    def convert_markdown_to_html(self, content):
        """Convert markdown to HTML with proper formatting"""
        
        # Code blocks (```code```)
        content = re.sub(r'```(\w+)?\n(.*?)```', self.format_code_block, content, flags=re.DOTALL)
        
        # Inline code (`code`)
        content = re.sub(r'`([^`]+)`', r'<code>\1</code>', content)
        
        # Headers
        content = re.sub(r'^#### (.*?)$', r'<h4>\1</h4>', content, flags=re.MULTILINE)
        content = re.sub(r'^### (.*?)$', r'<h3>\1</h3>', content, flags=re.MULTILINE)
        content = re.sub(r'^## (.*?)$', r'<h2>\1</h2>', content, flags=re.MULTILINE)
        content = re.sub(r'^# (.*?)$', r'<h1>\1</h1>', content, flags=re.MULTILINE)
        
        # Bold text (**text** or __text__)
        content = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', content)
        content = re.sub(r'__(.*?)__', r'<strong>\1</strong>', content)
        
        # Italic text (*text* or _text_)
        content = re.sub(r'\*(.*?)\*', r'<em>\1</em>', content)
        content = re.sub(r'_(.*?)_', r'<em>\1</em>', content)
        
        # Strikethrough (~~text~~)
        content = re.sub(r'~~(.*?)~~', r'<s>\1</s>', content)
        
        # Links [text](url)
        content = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', content)
        
        # Tables
        content = self.format_tables(content)
        
        # Lists
        content = self.format_lists(content)
        
        # Blockquotes
        content = re.sub(r'^> (.*?)$', r'<blockquote>\1</blockquote>', content, flags=re.MULTILINE)
        
        # Horizontal rules
        content = re.sub(r'^---$', r'<hr>', content, flags=re.MULTILINE)
        
        # Paragraphs (wrap consecutive lines in <p> tags)
        content = self.format_paragraphs(content)
        
        return content
    
    def format_paragraphs(self, content):
        """Format paragraphs properly"""
        lines = content.split('\n')
        formatted_lines = []
        in_paragraph = False
        
        for line in lines:
            stripped = line.strip()
            
            # Skip empty lines
            if not stripped:
                if in_paragraph:
                    formatted_lines.append('</p>')
                    in_paragraph = False
                formatted_lines.append('')
                continue
            
            # Skip if it's already a block element
            if (stripped.startswith('<h') or stripped.startswith('<ul') or 
                stripped.startswith('<ol') or stripped.startswith('<li') or
                stripped.startswith('<blockquote') or stripped.startswith('<pre') or
                stripped.startswith('<code') or stripped.startswith('<table') or
                stripped.startswith('<hr') or stripped.startswith('<div')):
                if in_paragraph:
                    formatted_lines.append('</p>')
                    in_paragraph = False
                formatted_lines.append(line)
                continue
            
            # Start or continue paragraph
            if not in_paragraph:
                formatted_lines.append('<p>')
                in_paragraph = True
            
            formatted_lines.append(line)
        
        # Close any open paragraph
        if in_paragraph:
            formatted_lines.append('</p>')
        
        return '\n'.join(formatted_lines)
    
    def format_tables(self, content):
        """Format markdown tables"""
        lines = content.split('\n')
        formatted_lines = []
        i = 0
        
        while i < len(lines):
            line = lines[i].strip()
            
            # Check if this line starts a table
            if '|' in line and not line.startswith('<'):
                table_lines = []
                j = i
                
                # Collect all table lines
                while j < len(lines) and '|' in lines[j].strip():
                    table_lines.append(lines[j].strip())
                    j += 1
                
                # Check if we have at least 2 lines (header + separator)
                if len(table_lines) >= 2:
                    # Format the table
                    table_html = self.create_table_html(table_lines)
                    formatted_lines.append(table_html)
                    i = j
                    continue
            
            formatted_lines.append(lines[i])
            i += 1
        
        return '\n'.join(formatted_lines)
    
    def create_table_html(self, table_lines):
        """Create HTML table from markdown table lines"""
        if len(table_lines) < 2:
            return '\n'.join(table_lines)
        
        # Parse header
        header_cells = [cell.strip() for cell in table_lines[0].split('|')[1:-1]]
        
        # Skip separator line
        data_lines = table_lines[2:] if len(table_lines) > 2 else []
        
        html = ['<table>']
        
        # Header
        html.append('<thead><tr>')
        for cell in header_cells:
            html.append(f'<th>{cell}</th>')
        html.append('</tr></thead>')
        
        # Body
        if data_lines:
            html.append('<tbody>')
            for line in data_lines:
                cells = [cell.strip() for cell in line.split('|')[1:-1]]
                html.append('<tr>')
                for cell in cells:
                    html.append(f'<td>{cell}</td>')
                html.append('</tr>')
            html.append('</tbody>')
        
        html.append('</table>')
        return '\n'.join(html)
    
    def setup_responsive_behavior(self):
        """Setup responsive behavior for the chat interface"""
        # Connect to parent widget resize events
        if self.parent():
            self.parent().installEventFilter(self)
    
    def eventFilter(self, obj, event):
        """Handle resize events for responsive design"""
        if event.type() == QEvent.Resize:
            self.update_responsive_layout()
        return super().eventFilter(obj, event)
    
    def update_responsive_layout(self):
        """Update layout based on current window size"""
        if hasattr(self, 'responsive_wrapper'):
            # Get the current width of the chat panel
            current_width = self.width()
            
            # Adjust maximum width based on available space
            if current_width < 600:
                # Mobile/small screen
                self.responsive_wrapper.setMaximumWidth(current_width - 48)  # Account for margins
                self.responsive_wrapper.setMinimumWidth(250)
            elif current_width < 1000:
                # Medium screen
                self.responsive_wrapper.setMaximumWidth(800)
                self.responsive_wrapper.setMinimumWidth(400)
            else:
                # Large screen
                self.responsive_wrapper.setMaximumWidth(1000)
                self.responsive_wrapper.setMinimumWidth(600)
    
    def format_code_block(self, match):
        """Format code block with syntax highlighting"""
        language = match.group(1) or ''
        code = match.group(2).strip()
        
        return f'''
        <div class="code-block">
            <div class="code-header">
                <span class="code-language">{language or 'code'}</span>
            </div>
            <pre><code>{code}</code></pre>
        </div>
        '''
    
    def format_lists(self, content):
        """Format markdown lists"""
        lines = content.split('\n')
        in_ul = False
        in_ol = False
        formatted_lines = []
        
        for line in lines:
            stripped = line.strip()
            
            # Unordered list
            if re.match(r'^[-*+] ', stripped):
                if not in_ul:
                    if in_ol:
                        formatted_lines.append('</ol>')
                        in_ol = False
                    formatted_lines.append('<ul>')
                    in_ul = True
                item_text = stripped[2:].strip()
                formatted_lines.append(f'<li>{item_text}</li>')
            
            # Ordered list
            elif re.match(r'^\d+\. ', stripped):
                if not in_ol:
                    if in_ul:
                        formatted_lines.append('</ul>')
                        in_ul = False
                    formatted_lines.append('<ol>')
                    in_ol = True
                item_text = re.sub(r'^\d+\. ', '', stripped).strip()
                formatted_lines.append(f'<li>{item_text}</li>')
            
            # Regular line
            else:
                if in_ul:
                    formatted_lines.append('</ul>')
                    in_ul = False
                if in_ol:
                    formatted_lines.append('</ol>')
                    in_ol = False
                formatted_lines.append(line)
        
        # Close any open lists
        if in_ul:
            formatted_lines.append('</ul>')
        if in_ol:
            formatted_lines.append('</ol>')
        
        return '\n'.join(formatted_lines)
    
    def send_message(self):
        """Send message to LLM"""
        text = self.message_input.text().strip()
        if not text or self.current_worker:
            return
        
        # Clear input
        self.message_input.clear()
        
        # Add user message
        self.state.add_message(self.state.current_thread_id, "user", text)
        
        # Reload messages to show the user message
        self.load_messages()
        
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
        self.current_worker.browser = self.browser  # Pass browser reference
        self.current_worker.message_updated.connect(self.append_response_chunk)
        self.current_worker.finished.connect(self.finish_response)
        self.current_worker.start()
        
        # Add loading indicator
        self.add_loading_indicator()
    
    def append_response_chunk(self, chunk):
        """Append chunk to current response"""
        if self.current_worker:
            # Apply text formatting to the accumulated content
            formatted_content = self.fix_concatenated_text(self.current_worker.current_content)
            
            # Update the thinking message with the formatted content
            thinking_message = {
                "role": "assistant", 
                "content": formatted_content,
                "timestamp": "now"
            }
            # Replace the last message (thinking indicator) with updated content
            self.replace_last_message(thinking_message)
    
    def replace_last_message(self, message):
        """Replace the last message bubble with new content"""
        # Remove the last message bubble
        if self.chat_layout.count() > 1:  # More than just the spacer
            last_item = self.chat_layout.itemAt(self.chat_layout.count() - 2)  # -2 because last is spacer
            if last_item and last_item.widget():
                last_item.widget().setParent(None)
        
        # Add the new message
        self.add_message_bubble(message)
        self.scroll_to_bottom()
    
    def add_loading_indicator(self):
        """Add animated loading indicator"""
        from PySide6.QtWidgets import QWidget, QHBoxLayout, QVBoxLayout, QLabel
        from PySide6.QtCore import Qt, QTimer
        from PySide6.QtGui import QFont
        
        # Create loading bubble
        loading_widget = QWidget()
        loading_widget.setStyleSheet("""
            QWidget {
                background-color: transparent;
            }
        """)
        loading_widget.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        
        # Create layout
        loading_layout = QHBoxLayout(loading_widget)
        loading_layout.setContentsMargins(0, 0, 0, 0)
        loading_layout.setSpacing(16)
        
        # Avatar
        avatar_label = QLabel("AI")
        avatar_label.setFixedSize(32, 32)
        avatar_label.setAlignment(Qt.AlignCenter)
        avatar_label.setStyleSheet("""
            QLabel {
                border-radius: 16px;
                font-size: 14px;
                font-weight: 600;
                color: white;
                background-color: #30D158;
            }
        """)
        
        # Loading content
        loading_content = QLabel()
        loading_content.setWordWrap(True)
        loading_content.setTextFormat(Qt.RichText)
        loading_content.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        loading_content.setMinimumWidth(200)
        loading_content.setMaximumWidth(16777215)
        loading_content.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        loading_content.setStyleSheet("""
            QLabel {
                background-color: #2d2d2d;
                border: 1px solid #404040;
                border-radius: 18px;
                padding: 24px 28px;
                font-size: 16px;
                color: #ffffff;
                line-height: 1.7;
                font-family: "SF Pro Display", "Helvetica Neue", "Arial", sans-serif;
            }
        """)
        
        # Add to layout
        loading_layout.addWidget(avatar_label)
        loading_layout.addWidget(loading_content, 1)  # Stretch factor 1 for full width
        loading_layout.addStretch()
        
        # Add to chat layout
        self.chat_layout.addWidget(loading_widget)
        
        # Store reference for updating
        self.loading_widget = loading_widget
        self.loading_content = loading_content
        
        # Start loading animation
        self.start_loading_animation()
        self.scroll_to_bottom()
    
    def start_loading_animation(self):
        """Start the loading animation"""
        self.loading_dots = 0
        self.loading_timer = QTimer()
        self.loading_timer.timeout.connect(self.update_loading_text)
        self.loading_timer.start(500)  # Update every 500ms
    
    def update_loading_text(self):
        """Update loading text with animated dots"""
        if hasattr(self, 'loading_content'):
            dots = "." * (self.loading_dots % 4)
            self.loading_content.setText(f"AI is thinking{dots}")
            self.loading_dots += 1
    
    def finish_response(self):
        """Finish LLM response"""
        # Stop loading animation
        if hasattr(self, 'loading_timer'):
            self.loading_timer.stop()
        
        # Remove loading indicator safely
        if hasattr(self, 'loading_widget') and self.loading_widget is not None:
            self.loading_widget.setParent(None)
            self.loading_widget = None
        
        # Save the final response to the database with formatting
        if self.current_worker and self.current_worker.current_content:
            formatted_content = self.fix_concatenated_text(self.current_worker.current_content)
            self.state.add_message(self.state.current_thread_id, "assistant", formatted_content)
        
        self.current_worker = None
        # Reload messages to show the complete response
        self.load_messages()

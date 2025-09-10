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
        
        # Get fresh models from Ollama
        models = self.state.models
        self.model_combo.addItems(models)
        
        if current in models:
            self.model_combo.setCurrentText(current)
        elif models:
            self.model_combo.setCurrentText(models[0])
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
            align-items: flex-start;
            gap: 12px;
        }
        .message.user {
            flex-direction: row-reverse;
        }
        .avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            font-weight: 600;
            flex-shrink: 0;
            margin-top: 4px;
        }
        .user .avatar {
            background-color: #007AFF;
            color: white;
        }
        .assistant .avatar {
            background-color: #30D158;
            color: white;
        }
        .tool .avatar {
            background-color: #FF9F0A;
            color: white;
        }
        .message-content {
            max-width: 75%;
            padding: 16px 20px;
            border-radius: 20px;
            font-size: 15px;
            line-height: 1.5;
            word-wrap: break-word;
            position: relative;
        }
        .user .message-content {
            background-color: #007AFF;
            color: white;
            border-bottom-right-radius: 6px;
        }
        .assistant .message-content {
            background-color: #2d2d2d;
            color: #ffffff;
            border: 1px solid #404040;
            border-bottom-left-radius: 6px;
        }
        .tool .message-content {
            background-color: #1e1e1e;
            color: #cccccc;
            border: 1px solid #404040;
            border-radius: 12px;
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', monospace;
            font-size: 13px;
            white-space: pre-wrap;
        }
        .timestamp {
            font-size: 12px;
            color: #888888;
            margin-top: 6px;
            text-align: right;
            font-weight: 400;
        }
        .user .timestamp {
            text-align: left;
        }
        .message-content h1, .message-content h2, .message-content h3 {
            margin: 12px 0 8px 0;
            color: #ffffff;
        }
        .message-content h1 {
            font-size: 20px;
            font-weight: 600;
        }
        .message-content h2 {
            font-size: 18px;
            font-weight: 600;
        }
        .message-content h3 {
            font-size: 16px;
            font-weight: 600;
        }
        .message-content ul, .message-content ol {
            margin: 8px 0;
            padding-left: 20px;
        }
        .message-content li {
            margin: 4px 0;
        }
        .message-content code {
            background-color: #3a3a3a;
            color: #ffffff;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', monospace;
            font-size: 13px;
        }
        .message-content pre {
            background-color: #2d2d2d;
            color: #ffffff;
            padding: 12px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 8px 0;
            border: 1px solid #404040;
        }
        .message-content blockquote {
            border-left: 4px solid #007AFF;
            margin: 8px 0;
            padding-left: 16px;
            color: #cccccc;
            font-style: italic;
        }
        .message-content strong {
            font-weight: 600;
            color: #ffffff;
        }
        .message-content em {
            font-style: italic;
            color: #cccccc;
        }
        .typing-indicator {
            display: inline-flex;
            gap: 4px;
            margin-left: 8px;
        }
        .typing-indicator span {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background-color: #888888;
            animation: typing 1.4s infinite ease-in-out;
        }
        .typing-indicator span:nth-child(1) { animation-delay: -0.32s; }
        .typing-indicator span:nth-child(2) { animation-delay: -0.16s; }
        @keyframes typing {
            0%, 80%, 100% { opacity: 0.3; }
            40% { opacity: 1; }
        }
        </style>
        """)
        
        for msg in messages:
            role = msg["role"]
            content = msg["content"]
            timestamp = msg.get("created_at", "")
            
            # Format content with proper markdown-like formatting
            formatted_content = self.format_message_content(content)
            
            if role == "user":
                self.chat_display.append(f"""
                <div class="message user">
                    <div class="avatar">U</div>
                    <div class="message-content">{formatted_content}</div>
                </div>
                <div class="timestamp">{timestamp}</div>
                """)
            elif role == "assistant":
                self.chat_display.append(f"""
                <div class="message assistant">
                    <div class="avatar">AI</div>
                    <div class="message-content">{formatted_content}</div>
                </div>
                <div class="timestamp">{timestamp}</div>
                """)
            elif role == "tool":
                self.chat_display.append(f"""
                <div class="message tool">
                    <div class="avatar">🔧</div>
                    <div class="message-content">{formatted_content}</div>
                </div>
                <div class="timestamp">{timestamp}</div>
                """)
        
        # Scroll to bottom
        self.chat_display.verticalScrollBar().setValue(
            self.chat_display.verticalScrollBar().maximum()
        )
    
    def escape_html(self, text):
        """Escape HTML special characters"""
        return (text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace('"', "&quot;")
                   .replace("'", "&#x27;"))
    
    def format_message_content(self, content):
        """Format message content with proper markdown-like formatting"""
        if not content:
            return ""
        
        # Escape HTML first
        content = self.escape_html(content)
        
        # Convert markdown-like formatting to HTML
        # Bold text (**text** or __text__)
        content = content.replace('**', '<strong>').replace('**', '</strong>')
        content = content.replace('__', '<strong>').replace('__', '</strong>')
        
        # Italic text (*text* or _text_)
        content = content.replace('*', '<em>').replace('*', '</em>')
        content = content.replace('_', '<em>').replace('_', '</em>')
        
        # Headers (# ## ###)
        content = content.replace('### ', '<h3>').replace('\n### ', '</h3>\n<h3>')
        content = content.replace('## ', '<h2>').replace('\n## ', '</h2>\n<h2>')
        content = content.replace('# ', '<h1>').replace('\n# ', '</h1>\n<h1>')
        
        # Add closing tags for headers at line breaks
        content = content.replace('\n', '</h1>\n').replace('</h1>\n<h1>', '\n<h1>')
        content = content.replace('\n', '</h2>\n').replace('</h2>\n<h2>', '\n<h2>')
        content = content.replace('\n', '</h3>\n').replace('</h3>\n<h3>', '\n<h3>')
        
        # Lists (- item or * item)
        lines = content.split('\n')
        in_list = False
        formatted_lines = []
        
        for line in lines:
            stripped = line.strip()
            if stripped.startswith('- ') or stripped.startswith('* '):
                if not in_list:
                    formatted_lines.append('<ul>')
                    in_list = True
                item_text = stripped[2:].strip()
                formatted_lines.append(f'<li>{item_text}</li>')
            elif stripped.startswith(('1. ', '2. ', '3. ', '4. ', '5. ', '6. ', '7. ', '8. ', '9. ')):
                if not in_list:
                    formatted_lines.append('<ol>')
                    in_list = True
                item_text = stripped[3:].strip()
                formatted_lines.append(f'<li>{item_text}</li>')
            else:
                if in_list:
                    formatted_lines.append('</ul>' if any(l.strip().startswith(('- ', '* ')) for l in lines[lines.index(line):]) else '</ul>')
                    in_list = False
                formatted_lines.append(line)
        
        if in_list:
            formatted_lines.append('</ul>')
        
        content = '\n'.join(formatted_lines)
        
        # Code blocks (```code```)
        import re
        content = re.sub(r'```(.*?)```', r'<pre><code>\1</code></pre>', content, flags=re.DOTALL)
        
        # Inline code (`code`)
        content = re.sub(r'`([^`]+)`', r'<code>\1</code>', content)
        
        # Blockquotes (> text)
        content = re.sub(r'^> (.+)$', r'<blockquote>\1</blockquote>', content, flags=re.MULTILINE)
        
        # Line breaks
        content = content.replace('\n', '<br>')
        
        return content
    
    def send_message(self):
        """Send message to LLM"""
        text = self.message_input.text().strip()
        if not text or self.current_worker:
            return
        
        self.message_input.clear()
        
        # Add user message
        self.state.add_message(self.state.current_thread_id, "user", text)
        
        # Get page data if available
        if self.state.current_url:
            # Extract page content asynchronously
            self.browser.extract_page_content_async(self.on_page_content_extracted)
        else:
            # No page context, proceed with empty page data
            self.prepare_and_send_llm_request(None)
    
    def on_page_content_extracted(self, page_data):
        """Handle extracted page content"""
        self.prepare_and_send_llm_request(page_data)
    
    def prepare_and_send_llm_request(self, page_data):
        """Prepare LLM request with page context and send"""
        # Prepare messages for LLM
        messages = []
        messages.append({
            "role": "system",
            "content": self.llm_client.create_system_message(page_data)
        })
        
        # Add conversation history
        chat_messages = self.state.get_messages(self.state.current_thread_id)
        for msg in chat_messages[-10:]:  # Last 10 messages
            if msg["role"] in ["user", "assistant"]:
                messages.append({
                    "role": msg["role"],
                    "content": msg["content"]
                })
        
        # Start streaming response
        self.start_llm_response(messages)
    
    def start_llm_response(self, messages):
        """Start LLM response streaming"""
        model = self.model_combo.currentText()
        
        self.current_worker = ChatWorker(messages, self.llm_client, model)
        self.current_worker.message_updated.connect(self.append_response_chunk)
        self.current_worker.finished.connect(self.finish_response)
        self.current_worker.start()
        
        # Show typing indicator with modern styling
        self.chat_display.append("""
        <div class="message assistant">
            <div class="avatar">AI</div>
            <div class="message-content">
                <em>Thinking...</em>
                <div class="typing-indicator">
                    <span>●</span><span>●</span><span>●</span>
                </div>
            </div>
        </div>
        """)
    
    def append_response_chunk(self, chunk):
        """Append chunk to current response"""
        # Remove the "Thinking..." text and start the actual response
        if "<em>Thinking...</em>" in self.chat_display.toPlainText():
            # Clear and reload all messages, then start streaming
            self.chat_display.clear()
            self.load_messages()
            
            # Start the streaming response message
            self.chat_display.append("""
            <div class="message assistant">
                <div class="avatar">AI</div>
                <div class="message-content" id="streaming-response">
            """)
        
        # Format the chunk before appending
        formatted_chunk = self.format_message_content(chunk)
        self.chat_display.append(formatted_chunk)
        self.chat_display.verticalScrollBar().setValue(
            self.chat_display.verticalScrollBar().maximum()
        )
    
    def finish_response(self):
        """Finish LLM response and save to database"""
        if self.current_worker:
            # Close the streaming response div
            self.chat_display.append("""
                </div>
            </div>
            <div class="timestamp">Just now</div>
            """)
            
            # Extract the full response from the HTML
            html_content = self.chat_display.toHtml()
            # Simple extraction - in a real implementation you'd parse the HTML properly
            # For now, we'll get the text content and save it
            response_text = self.chat_display.toPlainText()
            
            # Find the streaming response content
            if "streaming-response" in html_content:
                # Extract content between the streaming response div
                start_marker = 'id="streaming-response">'
                end_marker = '</div>'
                start_idx = html_content.find(start_marker)
                if start_idx != -1:
                    start_idx += len(start_marker)
                    end_idx = html_content.find(end_marker, start_idx)
                    if end_idx != -1:
                        response_text = html_content[start_idx:end_idx]
                        # Clean up HTML tags for storage
                        import re
                        response_text = re.sub(r'<[^>]+>', '', response_text)
            
            if response_text.strip():
                self.state.add_message(self.state.current_thread_id, "assistant", response_text.strip())
        
        self.current_worker = None

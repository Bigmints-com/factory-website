from PySide6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLineEdit, QPushButton, QComboBox, QLabel
from PySide6.QtWebEngineWidgets import QWebEngineView
from PySide6.QtCore import Qt, QThread, Signal, QTimer, QEvent, QUrl
from PySide6.QtGui import QFont
import asyncio
import re
import json
from app.core.llm import LLMClient
from app.core.icons import icon_manager

class ChatWorker(QThread):
    message_updated = Signal(str)  # content chunk
    finished = Signal()
    
    def __init__(self, llm_client, messages, page_data=None):
        super().__init__()
        self.llm_client = llm_client
        self.messages = messages
        self.page_data = page_data
        self.is_running = True
    
    def run(self):
        asyncio.run(self._run_async())
    
    async def _run_async(self):
        try:
            async for chunk in self.llm_client.stream_response(self.messages, self.page_data):
                if not self.is_running:
                    break
                self.message_updated.emit(chunk)
        except Exception as e:
            print(f"LLM streaming error: {e}")
        finally:
            self.finished.emit()
    
    def stop(self):
        self.is_running = False

class ChatWebView(QWidget):
    def __init__(self, state, browser):
        super().__init__()
        self.state = state
        self.browser = browser
        self.llm_client = LLMClient(state.config)
        self.current_worker = None
        self.messages = []
        
        self.setup_ui()
        self.connect_signals()
        self.load_chat_interface()
    
    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        
        # Web view for chat interface
        self.web_view = QWebEngineView()
        self.web_view.setStyleSheet("""
            QWebEngineView {
                background-color: #1a1a1a;
                border: none;
            }
        """)
        layout.addWidget(self.web_view)
        
        # Input area
        input_container = QWidget()
        input_container.setStyleSheet("""
            QWidget {
                background-color: #2d2d2d;
                border-top: 1px solid #404040;
            }
        """)
        input_layout = QVBoxLayout(input_container)
        input_layout.setContentsMargins(16, 16, 16, 16)
        input_layout.setSpacing(12)
        
        # Model selector
        model_layout = QHBoxLayout()
        model_layout.setSpacing(8)
        
        model_label = QLabel("Model:")
        model_label.setStyleSheet("""
            QLabel {
                color: #ffffff;
                font-size: 14px;
                font-weight: 500;
            }
        """)
        
        self.model_combo = QComboBox()
        self.model_combo.setStyleSheet("""
            QComboBox {
                background-color: #404040;
                border: 1px solid #555555;
                border-radius: 8px;
                padding: 8px 12px;
                color: #ffffff;
                font-size: 14px;
                min-width: 200px;
            }
            QComboBox::drop-down {
                border: none;
                width: 20px;
            }
            QComboBox::down-arrow {
                image: none;
                border-left: 5px solid transparent;
                border-right: 5px solid transparent;
                border-top: 5px solid #ffffff;
                margin-right: 8px;
            }
            QComboBox QAbstractItemView {
                background-color: #404040;
                border: 1px solid #555555;
                border-radius: 8px;
                color: #ffffff;
                selection-background-color: #007AFF;
            }
        """)
        
        model_layout.addWidget(model_label)
        model_layout.addWidget(self.model_combo)
        model_layout.addStretch()
        
        input_layout.addLayout(model_layout)
        
        # Message input
        message_layout = QHBoxLayout()
        message_layout.setSpacing(12)
        
        self.message_input = QLineEdit()
        self.message_input.setPlaceholderText("Ask me anything...")
        self.message_input.setStyleSheet("""
            QLineEdit {
                background-color: #404040;
                border: 1px solid #555555;
                border-radius: 12px;
                padding: 12px 16px;
                color: #ffffff;
                font-size: 16px;
                font-family: "SF Pro Display", "Helvetica Neue", "Arial", sans-serif;
            }
            QLineEdit:focus {
                border-color: #007AFF;
                outline: none;
            }
        """)
        
        self.send_btn = QPushButton()
        self.send_btn.setIcon(icon_manager.get_icon("send", 20, "#ffffff"))
        self.send_btn.setStyleSheet("""
            QPushButton {
                background-color: #007AFF;
                border: none;
                border-radius: 12px;
                padding: 12px;
                min-width: 48px;
                min-height: 48px;
            }
            QPushButton:hover {
                background-color: #0056CC;
            }
            QPushButton:pressed {
                background-color: #004499;
            }
        """)
        
        message_layout.addWidget(self.message_input)
        message_layout.addWidget(self.send_btn)
        
        input_layout.addLayout(message_layout)
        layout.addWidget(input_container)
    
    def connect_signals(self):
        self.send_btn.clicked.connect(self.send_message)
        self.message_input.returnPressed.connect(self.send_message)
        self.model_combo.currentTextChanged.connect(self.on_model_changed)
    
    def load_chat_interface(self):
        """Load the HTML chat interface"""
        html_content = self.get_chat_html()
        self.web_view.setHtml(html_content)
        self.update_models()
    
    def get_chat_html(self):
        """Generate the HTML chat interface with Tailwind CSS"""
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AI Chat</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <script>
                tailwind.config = {
                    theme: {
                        extend: {
                            colors: {
                                'dark-bg': '#1a1a1a',
                                'dark-surface': '#2d2d2d',
                                'dark-border': '#404040',
                                'dark-text': '#ffffff',
                                'dark-text-secondary': '#cccccc',
                                'primary': '#007AFF',
                                'success': '#30D158',
                                'warning': '#FF9F0A'
                            }
                        }
                    }
                }
            </script>
            <style>
                .message-bubble {
                    max-width: 600px;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                .user-message {
                    margin-left: auto;
                }
                .assistant-message {
                    margin-right: auto;
                }
                .code-block {
                    background-color: #1a1a1a;
                    border: 1px solid #404040;
                    border-radius: 12px;
                    overflow: hidden;
                }
                .code-header {
                    background-color: #2d2d2d;
                    border-bottom: 1px solid #404040;
                    padding: 12px 20px;
                    font-size: 13px;
                    color: #cccccc;
                    font-family: 'Monaco', 'Menlo', 'Consolas', 'Courier New', monospace;
                    font-weight: 500;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                .code-content {
                    background-color: #1a1a1a;
                    color: #ffffff;
                    padding: 20px;
                    font-family: 'Monaco', 'Menlo', 'Consolas', 'Courier New', monospace;
                    font-size: 14px;
                    line-height: 1.5;
                    white-space: pre;
                    overflow-x: auto;
                }
                .typing-indicator {
                    display: inline-block;
                    width: 8px;
                    height: 8px;
                    border-radius: 50%;
                    background-color: #007AFF;
                    animation: typing 1.4s infinite ease-in-out;
                }
                .typing-indicator:nth-child(2) {
                    animation-delay: 0.2s;
                }
                .typing-indicator:nth-child(3) {
                    animation-delay: 0.4s;
                }
                @keyframes typing {
                    0%, 60%, 100% {
                        transform: translateY(0);
                    }
                    30% {
                        transform: translateY(-10px);
                    }
                }
            </style>
        </head>
        <body class="bg-dark-bg text-dark-text font-sans">
            <div class="min-h-screen flex flex-col">
                <!-- Chat Container -->
                <div id="chat-container" class="flex-1 p-6 space-y-6 overflow-y-auto">
                    <!-- Messages will be added here -->
                </div>
                
                <!-- Welcome Message -->
                <div id="welcome-message" class="flex items-center justify-center h-full">
                    <div class="text-center">
                        <div class="text-4xl mb-4">🤖</div>
                        <h2 class="text-2xl font-semibold mb-2">AI Assistant</h2>
                        <p class="text-dark-text-secondary">Start a conversation by typing a message below</p>
                    </div>
                </div>
            </div>
            
            <script>
                class ChatInterface {
                    constructor() {
                        this.chatContainer = document.getElementById('chat-container');
                        this.welcomeMessage = document.getElementById('welcome-message');
                        this.currentMessageId = null;
                    }
                    
                    addMessage(role, content, timestamp = null) {
                        // Hide welcome message
                        if (this.welcomeMessage) {
                            this.welcomeMessage.style.display = 'none';
                        }
                        
                        const messageId = 'msg-' + Date.now();
                        const messageDiv = document.createElement('div');
                        messageDiv.id = messageId;
                        messageDiv.className = `flex ${role === 'user' ? 'user-message' : 'assistant-message'} mb-6`;
                        
                        const avatar = this.createAvatar(role);
                        const bubble = this.createBubble(role, content, timestamp);
                        
                        if (role === 'user') {
                            messageDiv.appendChild(bubble);
                            messageDiv.appendChild(avatar);
                        } else {
                            messageDiv.appendChild(avatar);
                            messageDiv.appendChild(bubble);
                        }
                        
                        this.chatContainer.appendChild(messageDiv);
                        this.scrollToBottom();
                        
                        return messageId;
                    }
                    
                    createAvatar(role) {
                        const avatar = document.createElement('div');
                        avatar.className = 'w-8 h-8 rounded-full flex items-center justify-center text-white font-semibold text-sm flex-shrink-0';
                        
                        if (role === 'user') {
                            avatar.style.backgroundColor = '#007AFF';
                            avatar.textContent = 'U';
                        } else if (role === 'assistant') {
                            avatar.style.backgroundColor = '#30D158';
                            avatar.textContent = 'AI';
                        } else if (role === 'tool') {
                            avatar.style.backgroundColor = '#FF9F0A';
                            avatar.textContent = '⚙️';
                        }
                        
                        return avatar;
                    }
                    
                    createBubble(role, content, timestamp) {
                        const bubble = document.createElement('div');
                        bubble.className = `message-bubble px-6 py-4 rounded-2xl ${
                            role === 'user' 
                                ? 'bg-primary text-white ml-4' 
                                : 'bg-dark-surface border border-dark-border mr-4'
                        }`;
                        
                        const formattedContent = this.formatContent(content);
                        bubble.innerHTML = formattedContent;
                        
                        if (timestamp) {
                            const timeDiv = document.createElement('div');
                            timeDiv.className = `text-xs mt-2 ${
                                role === 'user' ? 'text-blue-100' : 'text-dark-text-secondary'
                            }`;
                            timeDiv.textContent = timestamp;
                            bubble.appendChild(timeDiv);
                        }
                        
                        return bubble;
                    }
                    
                    formatContent(content) {
                        // Convert markdown to HTML
                        let html = content
                            // Code blocks
                            .replace(/```(\\w+)?\\n([\\s\\S]*?)```/g, (match, lang, code) => {
                                const language = lang || 'code';
                                return `
                                    <div class="code-block my-4">
                                        <div class="code-header">${language}</div>
                                        <div class="code-content">${this.escapeHtml(code.trim())}</div>
                                    </div>
                                `;
                            })
                            // Inline code
                            .replace(/`([^`]+)`/g, '<code class="bg-gray-600 text-white px-2 py-1 rounded text-sm font-mono">$1</code>')
                            // Headers
                            .replace(/^### (.*$)/gm, '<h3 class="text-lg font-semibold mt-4 mb-2">$1</h3>')
                            .replace(/^## (.*$)/gm, '<h2 class="text-xl font-semibold mt-4 mb-2">$1</h2>')
                            .replace(/^# (.*$)/gm, '<h1 class="text-2xl font-bold mt-4 mb-2">$1</h1>')
                            // Bold
                            .replace(/\\*\\*(.*?)\\*\\*/g, '<strong class="font-semibold">$1</strong>')
                            // Italic
                            .replace(/\\*(.*?)\\*/g, '<em class="italic">$1</em>')
                            // Lists
                            .replace(/^\\- (.*$)/gm, '<li class="ml-4">• $1</li>')
                            .replace(/^\\d+\\. (.*$)/gm, '<li class="ml-4">$1</li>')
                            // Line breaks
                            .replace(/\\n/g, '<br>');
                        
                        return html;
                    }
                    
                    escapeHtml(text) {
                        const div = document.createElement('div');
                        div.textContent = text;
                        return div.innerHTML;
                    }
                    
                    addTypingIndicator() {
                        const messageId = this.addMessage('assistant', '');
                        const bubble = document.querySelector(`#${messageId} .message-bubble`);
                        bubble.innerHTML = '<div class="flex space-x-1"><div class="typing-indicator"></div><div class="typing-indicator"></div><div class="typing-indicator"></div></div>';
                        this.currentMessageId = messageId;
                        return messageId;
                    }
                    
                    updateMessage(messageId, content) {
                        const message = document.getElementById(messageId);
                        if (message) {
                            const bubble = message.querySelector('.message-bubble');
                            bubble.innerHTML = this.formatContent(content);
                        }
                    }
                    
                    removeMessage(messageId) {
                        const message = document.getElementById(messageId);
                        if (message) {
                            message.remove();
                        }
                    }
                    
                    scrollToBottom() {
                        this.chatContainer.scrollTop = this.chatContainer.scrollHeight;
                    }
                    
                    clearMessages() {
                        this.chatContainer.innerHTML = '';
                        if (this.welcomeMessage) {
                            this.welcomeMessage.style.display = 'flex';
                        }
                    }
                }
                
                // Initialize chat interface
                window.chatInterface = new ChatInterface();
                
                // Expose methods to Python
                window.addMessage = (role, content, timestamp) => {
                    return window.chatInterface.addMessage(role, content, timestamp);
                };
                
                window.addTypingIndicator = () => {
                    return window.chatInterface.addTypingIndicator();
                };
                
                window.updateMessage = (messageId, content) => {
                    window.chatInterface.updateMessage(messageId, content);
                };
                
                window.removeMessage = (messageId) => {
                    window.chatInterface.removeMessage(messageId);
                };
                
                window.clearMessages = () => {
                    window.chatInterface.clearMessages();
                };
                
                window.scrollToBottom = () => {
                    window.chatInterface.scrollToBottom();
                };
            </script>
        </body>
        </html>
        """
    
    def update_models(self):
        """Update the model dropdown with available models"""
        self.model_combo.clear()
        models = self.state.models
        if models:
            self.model_combo.addItems(models)
            if self.state.default_model and self.state.default_model in models:
                self.model_combo.setCurrentText(self.state.default_model)
        else:
            self.model_combo.addItem("No models available")
    
    def send_message(self):
        """Send message to LLM"""
        text = self.message_input.text().strip()
        if not text or self.current_worker:
            return
        
        # Add user message to web interface
        self.add_message_to_web("user", text)
        
        # Clear input
        self.message_input.clear()
        
        # Start LLM response
        self.start_llm_response(text)
    
    def add_message_to_web(self, role, content, timestamp=None):
        """Add message to web interface"""
        script = f"""
        window.addMessage('{role}', `{content.replace('`', '\\`')}`, {f'`{timestamp}`' if timestamp else 'null'});
        """
        self.web_view.page().runJavaScript(script)
    
    def start_llm_response(self, user_message):
        """Start LLM response with typing indicator"""
        # Add user message to messages list
        self.messages.append({"role": "user", "content": user_message})
        
        # Add typing indicator
        script = """
        window.addTypingIndicator();
        """
        self.web_view.page().runJavaScript(script)
        
        # Start worker
        self.current_worker = ChatWorker(self.llm_client, self.messages)
        self.current_worker.message_updated.connect(self.append_response_chunk)
        self.current_worker.finished.connect(self.finish_response)
        self.current_worker.start()
    
    def append_response_chunk(self, chunk):
        """Append chunk to current response"""
        if not hasattr(self, 'current_response'):
            self.current_response = ""
            self.current_message_id = None
        
        self.current_response += chunk
        
        if not self.current_message_id:
            # Remove typing indicator and add new message
            script = """
            window.removeMessage(window.chatInterface.currentMessageId);
            """
            self.web_view.page().runJavaScript(script)
            
            # Add new message
            script = f"""
            window.chatInterface.currentMessageId = window.addMessage('assistant', `{self.current_response.replace('`', '\\`')}`);
            """
            self.web_view.page().runJavaScript(script)
        else:
            # Update existing message
            script = f"""
            window.updateMessage('{self.current_message_id}', `{self.current_response.replace('`', '\\`')}`);
            """
            self.web_view.page().runJavaScript(script)
    
    def finish_response(self):
        """Finish LLM response"""
        if hasattr(self, 'current_response'):
            # Add assistant message to messages list
            self.messages.append({"role": "assistant", "content": self.current_response})
            
            # Clean up
            delattr(self, 'current_response')
            self.current_message_id = None
        
        self.current_worker = None
    
    def on_model_changed(self, model_name):
        """Handle model selection change"""
        if model_name and model_name != "No models available":
            self.state.config.default_model = model_name
            self.state.save_config()

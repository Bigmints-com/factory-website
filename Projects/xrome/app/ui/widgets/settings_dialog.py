from PySide6.QtWidgets import (QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, 
                               QLineEdit, QComboBox, QPushButton, QLabel, QGroupBox)
from PySide6.QtCore import Qt

class SettingsDialog(QDialog):
    def __init__(self, state, parent=None):
        super().__init__(parent)
        self.state = state
        self.setWindowTitle("Settings")
        self.setModal(True)
        self.resize(500, 400)
        
        layout = QVBoxLayout(self)
        
        # LLM Settings - Ollama Configuration
        llm_group = QGroupBox("Ollama Configuration")
        llm_layout = QFormLayout(llm_group)
        
        self.llm_base = QLineEdit()
        self.llm_base.setText(state.config.get("llm_base", "http://localhost:11434"))
        self.llm_base.setPlaceholderText("http://localhost:11434")
        llm_layout.addRow("Ollama Server URL:", self.llm_base)
        
        # Hide API key for Ollama (not needed)
        self.llm_key = QLineEdit()
        self.llm_key.setText("")  # Ollama doesn't need API key
        self.llm_key.setVisible(False)
        
        # Models section with refresh button
        models_layout = QHBoxLayout()
        self.models_input = QLineEdit()
        models_str = ", ".join(state.config.get("models", []))
        self.models_input.setText(models_str)
        self.models_input.setPlaceholderText("Auto-detected from Ollama")
        self.models_input.setReadOnly(True)
        models_layout.addWidget(self.models_input)
        
        refresh_btn = QPushButton("🔄")
        refresh_btn.setToolTip("Refresh models from Ollama")
        refresh_btn.setMaximumWidth(40)
        refresh_btn.clicked.connect(self.refresh_models)
        models_layout.addWidget(refresh_btn)
        
        llm_layout.addRow("Available Models:", models_layout)
        
        self.default_model = QComboBox()
        self.default_model.addItems(state.config.get("models", []))
        self.default_model.setCurrentText(state.config.get("default_model", ""))
        llm_layout.addRow("Default Model:", self.default_model)
        
        # Add Ollama status
        status_label = QLabel("Make sure Ollama is running: ollama serve")
        status_label.setStyleSheet("color: #5f6368; font-style: italic;")
        llm_layout.addRow("Status:", status_label)
        
        layout.addWidget(llm_group)
        
        # General Settings
        general_group = QGroupBox("General")
        general_layout = QFormLayout(general_group)
        
        self.home_url = QLineEdit()
        self.home_url.setText(state.config.get("home_url", ""))
        general_layout.addRow("Home URL:", self.home_url)
        
        layout.addWidget(general_group)
        
        # Buttons
        button_layout = QHBoxLayout()
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_settings)
        button_layout.addWidget(save_btn)
        
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)
        
        layout.addLayout(button_layout)
    
    def save_settings(self):
        """Save settings to config"""
        # Update models list
        models = [m.strip() for m in self.models_input.text().split(",") if m.strip()]
        if models:
            self.state.config.set("models", models)
            self.state.config.set("default_model", self.default_model.currentText())
        
        # Update other settings
        self.state.config.set("llm_base", self.llm_base.text())
        self.state.config.set("llm_key", self.llm_key.text())
        self.state.config.set("home_url", self.home_url.text())
        
        self.state.settings_changed.emit()
        self.accept()
    
    def refresh_models(self):
        """Refresh models from Ollama server"""
        from app.core.llm import LLMClient
        llm_client = LLMClient(self.state.config)
        models = llm_client.get_available_models_sync()
        
        if models:
            self.models_input.setText(", ".join(models))
            self.default_model.clear()
            self.default_model.addItems(models)
            if models:
                self.default_model.setCurrentText(models[0])
        else:
            self.models_input.setText("No models found - make sure Ollama is running")
            self.models_input.setStyleSheet("color: #FF453A;")  # Red text for error

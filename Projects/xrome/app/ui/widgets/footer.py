from PySide6.QtWidgets import QStatusBar, QLabel, QProgressBar
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap, QPainter, QColor

class FooterBar(QStatusBar):
    def __init__(self, state, parent=None):
        super().__init__(parent)
        self.state = state
        
        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setMaximumWidth(200)
        self.progress_bar.setVisible(False)
        self.addWidget(self.progress_bar)
        
        # Status label
        self.status_label = QLabel("Ready")
        self.addWidget(self.status_label)
        
        # URL label
        self.url_label = QLabel("")
        self.addPermanentWidget(self.url_label)
        
        # Tool status pill
        self.tool_status = QLabel("")
        self.tool_status.setStyleSheet("""
            QLabel {
                background-color: #4CAF50;
                color: white;
                padding: 2px 8px;
                border-radius: 10px;
                font-size: 11px;
            }
        """)
        self.tool_status.setVisible(False)
        self.addPermanentWidget(self.tool_status)
        
        # Connect signals
        self.state.progress_changed.connect(self.update_progress)
        self.state.url_changed.connect(self.update_url)
        self.state.run_updated.connect(self.update_tool_status)
    
    def update_progress(self, progress):
        """Update progress bar"""
        if progress == 0 or progress == 100:
            self.progress_bar.setVisible(False)
        else:
            self.progress_bar.setVisible(True)
            self.progress_bar.setValue(progress)
    
    def update_url(self, url):
        """Update URL display"""
        # Show just the domain
        if url:
            try:
                from urllib.parse import urlparse
                parsed = urlparse(url)
                domain = parsed.netloc or parsed.path
                self.url_label.setText(f"🔒 {domain}")
            except:
                self.url_label.setText(f"🔒 {url[:50]}...")
        else:
            self.url_label.setText("")
    
    def update_tool_status(self, run_id):
        """Update tool status pill"""
        if run_id in self.state.runs:
            run = self.state.runs[run_id]
            if run["status"] == "running":
                self.tool_status.setText(f"🔧 {run['tool_name']}")
                self.tool_status.setVisible(True)
            elif run["status"] == "completed":
                self.tool_status.setText(f"✅ {run['tool_name']}")
                self.tool_status.setVisible(True)
                # Hide after 3 seconds
                from PySide6.QtCore import QTimer
                QTimer.singleShot(3000, lambda: self.tool_status.setVisible(False))
            elif run["status"] == "error":
                self.tool_status.setText(f"❌ {run['tool_name']}")
                self.tool_status.setVisible(True)
                # Hide after 5 seconds
                from PySide6.QtCore import QTimer
                QTimer.singleShot(5000, lambda: self.tool_status.setVisible(False))

from PySide6.QtWidgets import QMenu, QMessageBox
from PySide6.QtCore import QThread, Signal
import asyncio
import json
from app.tools.runner import run_tool

class ToolsWorker(QThread):
    finished = Signal(str, dict)  # run_id, result
    log_updated = Signal(str, str, str)  # run_id, level, message
    
    def __init__(self, tool_name, url, state):
        super().__init__()
        self.tool_name = tool_name
        self.url = url
        self.state = state
        self.run_id = None
    
    def run(self):
        try:
            # Create new event loop for this thread
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            self.run_id = self.state.start_run(self.tool_name, self.url)
            
            def emit(level, msg):
                self.log_updated.emit(self.run_id, level, msg)
            
            # Run the tool
            result = loop.run_until_complete(
                run_tool(self.tool_name, self.url, emit)
            )
            
            self.finished.emit(self.run_id, result)
            
        except Exception as e:
            if self.run_id:
                self.state.fail_run(self.run_id, str(e))
            self.finished.emit(self.run_id or "", {"error": str(e)})
        finally:
            loop.close()

class ToolsMenu(QMenu):
    def __init__(self, state, browser, parent=None):
        super().__init__(parent)
        self.state = state
        self.browser = browser
        self.workers = []
        
        # Add tool actions
        tools = [
            ("Analytics Audit", "analytics"),
            ("Usability Audit", "usability"),
            ("Accessibility Audit", "accessibility")
        ]
        
        for name, key in tools:
            action = self.addAction(name)
            action.triggered.connect(lambda checked, k=key: self.run_tool(k))
    
    def run_tool(self, tool_key):
        url = self.state.current_url
        if not url:
            QMessageBox.warning(self, "No URL", "Please navigate to a webpage first.")
            return
        
        # Create and start worker
        worker = ToolsWorker(tool_key, url, self.state)
        worker.finished.connect(self.on_tool_finished)
        worker.log_updated.connect(self.on_log_updated)
        worker.start()
        
        self.workers.append(worker)
    
    def on_log_updated(self, run_id, level, message):
        self.state.append_run_log(run_id, level, message)
    
    def on_tool_finished(self, run_id, result):
        if run_id:
            self.state.finish_run(run_id, result)
            self.state.append_chat_tool_result(run_id, json.dumps(result, indent=2))
        
        # Clean up worker
        for worker in self.workers[:]:
            if not worker.isRunning():
                self.workers.remove(worker)

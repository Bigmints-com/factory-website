from PySide6.QtCore import QObject, Signal, QTimer
from PySide6.QtWebEngineWidgets import QWebEngineView
from typing import Dict, List, Optional, Any
from datetime import datetime
import json
import sqlite3
from .config import Config

class AppState(QObject):
    # Signals
    url_changed = Signal(str)
    title_changed = Signal(str)
    progress_changed = Signal(int)
    chat_updated = Signal()
    run_updated = Signal(str)  # run_id
    settings_changed = Signal()
    
    def __init__(self):
        super().__init__()
        self.config = Config()
        self.current_url = ""
        self.title = ""
        self.progress = 0
        self.chat_threads = []
        self.current_thread_id = None
        self.runs = {}  # run_id -> run_data
        self.active_runs = set()
        
        self.init_database()
        self.load_chat_threads()
    
    def init_database(self):
        conn = sqlite3.connect(self.config.db_file)
        cursor = conn.cursor()
        
        # Chat threads table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS chat_threads (
                id TEXT PRIMARY KEY,
                title TEXT,
                created_at TIMESTAMP,
                updated_at TIMESTAMP
            )
        """)
        
        # Messages table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                thread_id TEXT,
                role TEXT,
                content TEXT,
                created_at TIMESTAMP,
                FOREIGN KEY (thread_id) REFERENCES chat_threads (id)
            )
        """)
        
        # Runs table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS runs (
                id TEXT PRIMARY KEY,
                tool_name TEXT,
                url TEXT,
                status TEXT,
                result TEXT,
                created_at TIMESTAMP,
                completed_at TIMESTAMP
            )
        """)
        
        conn.commit()
        conn.close()
    
    def load_chat_threads(self):
        conn = sqlite3.connect(self.config.db_file)
        cursor = conn.cursor()
        cursor.execute("SELECT id, title, created_at FROM chat_threads ORDER BY updated_at DESC")
        self.chat_threads = [{"id": row[0], "title": row[1], "created_at": row[2]} for row in cursor.fetchall()]
        conn.close()
        
        if not self.chat_threads:
            self.create_new_thread()
        else:
            self.current_thread_id = self.chat_threads[0]["id"]
        
        self.chat_updated.emit()
    
    def create_new_thread(self):
        thread_id = f"thread_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        title = "New Chat"
        
        conn = sqlite3.connect(self.config.db_file)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO chat_threads (id, title, created_at, updated_at) VALUES (?, ?, ?, ?)",
            (thread_id, title, datetime.now(), datetime.now())
        )
        conn.commit()
        conn.close()
        
        self.chat_threads.insert(0, {"id": thread_id, "title": title, "created_at": datetime.now().isoformat()})
        self.current_thread_id = thread_id
        self.chat_updated.emit()
    
    def get_messages(self, thread_id: str) -> List[Dict]:
        conn = sqlite3.connect(self.config.db_file)
        cursor = conn.cursor()
        cursor.execute(
            "SELECT role, content, created_at FROM messages WHERE thread_id = ? ORDER BY created_at",
            (thread_id,)
        )
        messages = [{"role": row[0], "content": row[1], "created_at": row[2]} for row in cursor.fetchall()]
        conn.close()
        return messages
    
    def add_message(self, thread_id: str, role: str, content: str):
        message_id = f"msg_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}"
        
        conn = sqlite3.connect(self.config.db_file)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO messages (id, thread_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
            (message_id, thread_id, role, content, datetime.now())
        )
        cursor.execute(
            "UPDATE chat_threads SET updated_at = ? WHERE id = ?",
            (datetime.now(), thread_id)
        )
        conn.commit()
        conn.close()
        
        self.chat_updated.emit()
    
    def set_current_url(self, url: str):
        self.current_url = url
        self.url_changed.emit(url)
    
    def set_title(self, title: str):
        self.title = title
        self.title_changed.emit(title)
    
    def set_progress(self, progress: int):
        self.progress = progress
        self.progress_changed.emit(progress)
    
    def start_run(self, tool_name: str, url: str) -> str:
        run_id = f"run_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}"
        self.runs[run_id] = {
            "id": run_id,
            "tool_name": tool_name,
            "url": url,
            "status": "running",
            "logs": [],
            "result": None,
            "created_at": datetime.now(),
            "completed_at": None
        }
        self.active_runs.add(run_id)
        self.run_updated.emit(run_id)
        return run_id
    
    def append_run_log(self, run_id: str, level: str, message: str):
        if run_id in self.runs:
            self.runs[run_id]["logs"].append({"level": level, "message": message, "timestamp": datetime.now()})
            self.run_updated.emit(run_id)
    
    def finish_run(self, run_id: str, result: Dict):
        if run_id in self.runs:
            self.runs[run_id]["status"] = "completed"
            self.runs[run_id]["result"] = result
            self.runs[run_id]["completed_at"] = datetime.now()
            self.active_runs.discard(run_id)
            self.run_updated.emit(run_id)
    
    def fail_run(self, run_id: str, error: str):
        if run_id in self.runs:
            self.runs[run_id]["status"] = "error"
            self.runs[run_id]["result"] = {"error": error}
            self.runs[run_id]["completed_at"] = datetime.now()
            self.active_runs.discard(run_id)
            self.run_updated.emit(run_id)
    
    def append_chat_tool_result(self, run_id: str, result_json: str):
        if self.current_thread_id and run_id in self.runs:
            self.add_message(self.current_thread_id, "tool", f"Tool Result ({self.runs[run_id]['tool_name']}):\n{result_json}")
    
    @property
    def models(self) -> List[str]:
        # Try to get models from Ollama first
        from .llm import LLMClient
        llm_client = LLMClient(self.config)
        ollama_models = llm_client.get_available_models_sync()
        
        if ollama_models:
            return ollama_models
        else:
            # Fallback to configured models if Ollama is not available
            return self.config.get("models", ["llama3.2", "llama3.1"])
    
    @property
    def default_model(self) -> str:
        models = self.models
        if models:
            return models[0]  # Use first available model
        return self.config.get("default_model", "llama3.2")
    
    def clear_thread_messages(self, thread_id: str):
        """Clear all messages for a specific thread"""
        conn = sqlite3.connect(self.config.db_file)
        cursor = conn.cursor()
        
        # Delete all messages for this thread
        cursor.execute("DELETE FROM messages WHERE thread_id = ?", (thread_id,))
        
        conn.commit()
        conn.close()
        
        # Emit signal to update UI
        self.chat_updated.emit()
    
    def save_config(self):
        """Save configuration to file"""
        import json
        config_data = {
            "llm_base": self.config.llm_base,
            "default_model": self.config.default_model,
            "models": self.config.models
        }
        with open("config.json", "w") as f:
            json.dump(config_data, f, indent=2)

from PySide6.QtWebEngineWidgets import QWebEngineView
from PySide6.QtCore import QUrl, Signal, QObject, QTimer, QEventLoop
from PySide6.QtWebEngineCore import QWebEnginePage
import asyncio
import json
from typing import Dict, Any, Optional

class BrowserView(QWebEngineView):
    def __init__(self, state):
        super().__init__()
        self.state = state
        self.urlChanged.connect(lambda u: self.state.set_current_url(u.toString()))
        self.titleChanged.connect(self.state.set_title)
        self.loadProgress.connect(self.state.set_progress)
    
    def navigate(self, text: str):
        """Navigate to URL or search query"""
        if not text.strip():
            return
            
        # Check if it looks like a URL (has domain extension or starts with common protocols)
        if ("://" in text or 
            "." in text and any(ext in text.lower() for ext in [".com", ".org", ".net", ".ai", ".io", ".co", ".edu", ".gov"])):
            
            if "://" in text:
                url = text
            else:
                # Auto-add https:// prefix for domain-like text
                url = f"https://{text}"
        else:
            # Search query
            url = f"https://www.google.com/search?q={text}"
        
        self.load(QUrl(url))
    
    def back(self):
        """Go back in history"""
        self.triggerPageAction(QWebEnginePage.Back)
    
    def forward(self):
        """Go forward in history"""
        self.triggerPageAction(QWebEnginePage.Forward)
    
    def reload(self):
        """Reload current page"""
        self.triggerPageAction(QWebEnginePage.Reload)
    
    def home(self):
        """Navigate to home page"""
        home_url = self.state.config.get("home_url", "https://example.com")
        self.navigate(home_url)
    
    def extract_lite(self) -> Dict[str, Any]:
        """Extract page data using JavaScript (synchronous version)"""
        # For now, return basic data. The async version will be implemented separately
        return {
            "url": self.state.current_url or "",
            "title": self.state.title or "",
            "meta": {},
            "textContent": "",
            "headings": [],
            "images": [],
            "forms": [],
            "links": [],
            "wordCount": 0
        }
    
    async def extract_page_content_async(self):
        """Extract page content asynchronously using JavaScript"""
        import asyncio
        from PySide6.QtCore import QEventLoop, QTimer
        
        # Create a simple extraction that works with Qt
        result = {
            "url": self.state.current_url or "",
            "title": self.state.title or "",
            "meta": {},
            "textContent": "",
            "headings": [],
            "images": [],
            "forms": [],
            "links": [],
            "wordCount": 0
        }
        
        # Try to extract content using the callback method
        try:
            # Use a simple approach - just get the current URL and title
            # This will be enhanced later with proper content extraction
            if self.state.current_url and self.state.current_url != "":
                result["textContent"] = f"Website: {self.state.title or 'Unknown'}\nURL: {self.state.current_url}\n\nNote: This is a browser-based AI assistant. I can see you're currently viewing {self.state.title or 'a webpage'} at {self.state.current_url}. I can help you analyze, summarize, or answer questions about this page's content. Please ask me what you'd like to know about this website!"
                result["wordCount"] = len(result["textContent"].split())
            else:
                result["textContent"] = "No webpage is currently loaded. Please navigate to a website first, then I can help you analyze its content."
        except Exception as e:
            result["textContent"] = f"Error extracting page content: {str(e)}"
        
        return result
    
    def extract_page_content_async_callback(self, callback):
        """Extract page content asynchronously using JavaScript (callback version)"""
        js_code = """
(() => {
  try {
    const meta = {};
    document.querySelectorAll('meta[name],meta[property]').forEach(m => {
      const key = m.name || m.property;
      meta[key] = m.content;
    });
    
    // Extract main content from various elements
    const contentSelectors = [
      'main', 'article', '.content', '.post', '.entry', 
      'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'div'
    ];
    
    let text = '';
    for (const selector of contentSelectors) {
      const elements = document.querySelectorAll(selector);
      for (const el of elements) {
        const textContent = el.textContent?.trim();
        if (textContent && textContent.length > 10) {
          text += textContent + ' ';
        }
      }
      if (text.length > 8000) break; // Limit content size
    }
    
    // Clean up the text
    text = text.replace(/\\s+/g, ' ').trim().slice(0, 8000);
    
    // Extract headings for structure
    const headings = [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')]
      .map(h => ({ level: parseInt(h.tagName[1]), text: h.textContent.trim() }))
      .slice(0, 20);
    
    // Extract images with alt text
    const images = [...document.querySelectorAll('img[alt]')]
      .map(img => ({
        src: img.src,
        alt: img.alt,
        title: img.title
      }))
      .slice(0, 20);
    
    // Extract forms
    const forms = [...document.querySelectorAll('form')]
      .map(form => ({
        action: form.action,
        method: form.method,
        inputs: [...form.querySelectorAll('input,textarea,select')]
          .map(input => ({
            type: input.type,
            name: input.name,
            placeholder: input.placeholder,
            required: input.required
          }))
      }))
      .slice(0, 10);
    
    // Extract links
    const links = [...document.querySelectorAll('a[href]')]
      .map(a => {
        try {
          return {
            text: a.textContent.trim().slice(0, 100),
            href: new URL(a.getAttribute('href'), location.href).href
          };
        } catch (e) {
          return null;
        }
      })
      .filter(Boolean)
      .slice(0, 50);
    
    return {
      url: location.href,
      title: document.title,
      meta: meta,
      textContent: text,
      headings: headings,
      images: images,
      forms: forms,
      links: links,
      wordCount: text.split(' ').length
    };
  } catch (e) {
    return { error: e.message };
  }
})()
"""
        
        def handle_result(result):
            try:
                if result:
                    page_data = json.loads(result) if isinstance(result, str) else result
                    callback(page_data)
                else:
                    callback({
                        "url": self.state.current_url or "",
                        "title": self.state.title or "",
                        "meta": {},
                        "textContent": "",
                        "headings": [],
                        "images": [],
                        "forms": [],
                        "links": [],
                        "wordCount": 0,
                        "error": "No content extracted"
                    })
            except Exception as e:
                callback({
                    "url": self.state.current_url or "",
                    "title": self.state.title or "",
                    "meta": {},
                    "textContent": "",
                    "headings": [],
                    "images": [],
                    "forms": [],
                    "links": [],
                    "wordCount": 0,
                    "error": str(e)
                })
        
        self.page().runJavaScript(js_code, handle_result)

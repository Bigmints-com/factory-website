import httpx
import json
from typing import AsyncGenerator, Dict, Any, Optional, List
from .config import Config

class LLMClient:
    def __init__(self, config: Config):
        self.config = config
        self.base_url = config.get("llm_base", "http://localhost:11434")
        self.api_key = config.get("llm_key", "")  # Not needed for Ollama
    
    async def stream_chat(self, messages: List[Dict[str, str]], model: str = None) -> AsyncGenerator[str, None]:
        model = model or self.config.get("default_model", "llama3.2")
        
        # Convert messages to Ollama format
        prompt = self._convert_messages_to_prompt(messages)
        
        data = {
            "model": model,
            "prompt": prompt,
            "stream": True
        }
        
        try:
            async with httpx.AsyncClient() as client:
                async with client.stream(
                    "POST",
                    f"{self.base_url}/api/generate",
                    json=data,
                    timeout=60.0
                ) as response:
                    if response.status_code != 200:
                        yield f"Error: HTTP {response.status_code} - {response.text}"
                        return
                    
                    async for line in response.aiter_lines():
                        if line.strip():
                            try:
                                chunk = json.loads(line)
                                if "response" in chunk:
                                    # Clean HTML tags from the response
                                    cleaned_response = self._clean_html_tags(chunk["response"])
                                    yield cleaned_response
                                if chunk.get("done", False):
                                    break
                            except json.JSONDecodeError:
                                continue
                                
        except Exception as e:
            yield f"Error: {str(e)}"
    
    async def stream_response(self, messages: List[Dict[str, str]], page_data: Dict = None, model: str = None) -> AsyncGenerator[str, None]:
        """Stream response with page context"""
        model = model or self.config.get("default_model", "llama3.2")
        
        # Convert messages to Ollama format
        prompt = self._convert_messages_to_prompt(messages)
        
        # Add system message with page context if available
        if page_data:
            system_message = self.create_system_message(page_data)
            # Prepend system context to the prompt to ensure it's processed
            prompt = f"System: {system_message}\n\nCRITICAL INSTRUCTIONS: You are a BROWSER-BASED AI assistant. You CAN see the current webpage. You MUST answer questions about the website you're viewing. Do NOT say you cannot access websites - you CAN and DO have access to this webpage.\n\n{prompt}"
            print(f"DEBUG: Full prompt being sent to LLM:\n{prompt[:500]}...")  # Debug output
        
        data = {
            "model": model,
            "prompt": prompt,
            "stream": True
        }
        
        try:
            async with httpx.AsyncClient() as client:
                async with client.stream(
                    "POST",
                    f"{self.base_url}/api/generate",
                    json=data,
                    timeout=60.0
                ) as response:
                    if response.status_code != 200:
                        yield f"Error: HTTP {response.status_code} - {response.text}"
                        return
                    
                    async for line in response.aiter_lines():
                        if line.strip():
                            try:
                                chunk = json.loads(line)
                                if "response" in chunk:
                                    # Clean HTML tags from the response
                                    cleaned_response = self._clean_html_tags(chunk["response"])
                                    yield cleaned_response
                                if chunk.get("done", False):
                                    break
                            except json.JSONDecodeError:
                                continue
                                
        except Exception as e:
            yield f"Error: {str(e)}"
    
    def _convert_messages_to_prompt(self, messages: List[Dict[str, str]]) -> str:
        """Convert OpenAI-style messages to Ollama prompt format"""
        prompt_parts = []
        
        for message in messages:
            role = message["role"]
            content = message["content"]
            
            if role == "system":
                prompt_parts.append(f"System: {content}")
            elif role == "user":
                prompt_parts.append(f"Human: {content}")
            elif role == "assistant":
                prompt_parts.append(f"Assistant: {content}")
        
        prompt_parts.append("Assistant:")
        return "\n\n".join(prompt_parts)
    
    def create_system_message(self, page_data: Optional[Dict] = None) -> str:
        if page_data and page_data.get('textContent'):
            # Rich page context available
            context = f"""You are a browser-based AI assistant. You CAN see the current webpage.

CURRENT PAGE:
URL: {page_data.get('url', 'Unknown')}
Title: {page_data.get('title', 'Unknown')}

PAGE CONTENT:
{page_data.get('textContent', '')[:4000]}

CRITICAL: You are NOT a regular AI. You are a BROWSER-BASED AI that can see webpages. When users ask about the site, you MUST provide specific insights about what you can see. You CAN analyze the content, design, functionality, and user experience. Do NOT say you cannot access websites - you CAN and DO have access to this webpage."""
            return context
        elif page_data:
            # Basic page data available
            return f"""You are a helpful AI assistant. Here's what I know about the current page:

URL: {page_data.get('url', 'Unknown')}
Title: {page_data.get('title', 'Unknown')}

Note: Full page content extraction is not available. You can still help with general questions about the page or provide assistance based on the URL and title."""
        else:
            return "You are a helpful AI assistant. I don't have context about any specific webpage right now, but I can help with general questions and provide assistance."
    
    def _format_headings(self, headings: list) -> str:
        """Format headings for better readability"""
        if not headings:
            return "No headings found"
        
        formatted = []
        for heading in headings:
            level = heading.get('level', 1)
            text = heading.get('text', '')
            indent = "  " * (level - 1)
            formatted.append(f"{indent}H{level}: {text}")
        
        return "\n".join(formatted)
    
    async def get_available_models(self) -> List[str]:
        """Fetch available models from Ollama server"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.base_url}/api/tags", timeout=10.0)
                if response.status_code == 200:
                    data = response.json()
                    models = []
                    for model in data.get("models", []):
                        model_name = model.get("name", "")
                        if model_name:
                            models.append(model_name)
                    return models
                else:
                    print(f"Error fetching models: HTTP {response.status_code}")
                    return []
        except Exception as e:
            print(f"Error connecting to Ollama: {e}")
            return []
    
    def get_available_models_sync(self) -> List[str]:
        """Synchronous version for use in UI"""
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(self.get_available_models())
        except RuntimeError:
            # If no event loop is running, create a new one
            return asyncio.run(self.get_available_models())
    
    def _clean_html_tags(self, text: str) -> str:
        """Clean HTML tags from text"""
        import re
        if not text:
            return text
        
        # Remove common HTML tags that shouldn't be displayed
        text = re.sub(r'</?div[^>]*>', '', text)
        text = re.sub(r'</?span[^>]*>', '', text)
        text = re.sub(r'</?p[^>]*>', '', text)
        text = re.sub(r'</?h[1-6][^>]*>', '', text)
        text = re.sub(r'</?br[^>]*>', '\n', text)
        text = re.sub(r'class="[^"]*"', '', text)
        text = re.sub(r'id="[^"]*"', '', text)
        text = re.sub(r'style="[^"]*"', '', text)
        
        # Clean up extra whitespace
        text = re.sub(r'\n\s*\n', '\n\n', text)
        text = text.strip()
        
        return text

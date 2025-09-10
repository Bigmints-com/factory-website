"""Tests for LLM functionality"""
import pytest
from unittest.mock import Mock, patch
from app.core.llm import LLMClient
from app.core.config import Config

def test_llm_client_creation():
    """Test LLM client creation"""
    config = Config()
    client = LLMClient(config)
    
    assert client.base_url == config.get("llm_base")
    assert client.api_key == config.get("llm_key")

def test_create_system_message_with_page_data():
    """Test system message creation with page data"""
    config = Config()
    client = LLMClient(config)
    
    page_data = {
        "url": "https://example.com",
        "title": "Example Page",
        "meta": {"description": "Test page"},
        "textSample": "Sample text content",
        "colors": ["#ffffff", "#000000"],
        "links": [{"text": "Link", "href": "https://example.com"}]
    }
    
    message = client.create_system_message(page_data)
    
    assert "https://example.com" in message
    assert "Example Page" in message
    assert "Sample text content" in message

def test_create_system_message_without_page_data():
    """Test system message creation without page data"""
    config = Config()
    client = LLMClient(config)
    
    message = client.create_system_message(None)
    
    assert "helpful assistant" in message.lower()
    assert "web pages" in message.lower()

@patch('httpx.AsyncClient')
async def test_stream_chat_mock(mock_client):
    """Test chat streaming with mocked HTTP client"""
    config = Config()
    config.set("llm_key", "test-key")
    client = LLMClient(config)
    
    # Mock the streaming response
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.aiter_lines.return_value = [
        'data: {"choices": [{"delta": {"content": "Hello"}}]}',
        'data: {"choices": [{"delta": {"content": " world"}}]}',
        'data: [DONE]'
    ]
    
    mock_client.return_value.__aenter__.return_value.stream.return_value.__aenter__.return_value = mock_response
    
    messages = [{"role": "user", "content": "Hello"}]
    chunks = []
    
    async for chunk in client.stream_chat(messages):
        chunks.append(chunk)
    
    assert chunks == ["Hello", " world"]

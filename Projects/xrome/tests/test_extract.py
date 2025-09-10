"""Tests for page extraction functionality"""
import pytest
from app.browser.view import BrowserView
from app.core.state import AppState

def test_extract_lite_basic():
    """Test basic page extraction"""
    state = AppState()
    browser = BrowserView(state)
    
    # Set some basic state
    state.set_current_url("https://example.com")
    state.set_title("Example Page")
    
    # Test extraction
    result = browser.extract_lite()
    
    assert "url" in result
    assert "title" in result
    assert "meta" in result
    assert "textSample" in result
    assert "colors" in result
    assert "links" in result
    
    assert result["url"] == "https://example.com"
    assert result["title"] == "Example Page"

def test_extract_lite_structure():
    """Test that extraction returns proper data structure"""
    state = AppState()
    browser = BrowserView(state)
    
    result = browser.extract_lite()
    
    # Check data types
    assert isinstance(result["url"], str)
    assert isinstance(result["title"], str)
    assert isinstance(result["meta"], dict)
    assert isinstance(result["textSample"], str)
    assert isinstance(result["colors"], list)
    assert isinstance(result["links"], list)

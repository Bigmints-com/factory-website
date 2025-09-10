import asyncio
from playwright.async_api import async_playwright
from typing import Callable, Dict, Any

_browser = None
_playwright = None

async def _ensure_browser():
    global _browser, _playwright
    if _browser is None:
        _playwright = await async_playwright().start()
        _browser = await _playwright.chromium.launch(headless=True)
    return _browser

async def run_tool(tool: str, url: str, emit: Callable[[str, str], None]) -> Dict[str, Any]:
    """Run a tool on the given URL and emit progress updates"""
    try:
        browser = await _ensure_browser()
        context = await browser.new_context()
        page = await context.new_page()
        
        emit("info", f"Opening {url}")
        await page.goto(url, wait_until="networkidle", timeout=30000)
        
        # Route to appropriate tool
        if tool == "analytics":
            from .analytics import run as task
        elif tool == "usability":
            from .usability import run as task
        elif tool == "accessibility":
            from .accessibility import run as task
        else:
            raise ValueError(f"Unknown tool: {tool}")
        
        emit("info", f"Running {tool} analysis...")
        result = await task(page, emit)
        
        await context.close()
        emit("info", f"{tool.title()} analysis completed")
        return result
        
    except Exception as e:
        emit("error", f"Tool execution failed: {str(e)}")
        raise

async def cleanup():
    """Clean up browser resources"""
    global _browser, _playwright
    if _browser:
        await _browser.close()
        _browser = None
    if _playwright:
        await _playwright.stop()
        _playwright = None

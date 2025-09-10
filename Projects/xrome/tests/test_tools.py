"""Tests for analysis tools"""
import pytest
from unittest.mock import Mock, AsyncMock
from app.tools.analytics import run as analytics_run
from app.tools.usability import run as usability_run
from app.tools.accessibility import run as accessibility_run

@pytest.mark.asyncio
async def test_analytics_tool():
    """Test analytics tool with mocked page"""
    mock_page = Mock()
    mock_page.content.return_value = """
    <html>
        <head>
            <script src="https://www.googletagmanager.com/gtag/js?id=G-ABC123"></script>
        </head>
        <body>
            <script>
                gtag('config', 'G-ABC123');
            </script>
        </body>
    </html>
    """
    
    # Mock page events
    requests = []
    def mock_request_handler(request):
        requests.append({
            "url": request.url,
            "method": request.method,
            "resource_type": request.resource_type
        })
    
    mock_page.on = Mock(side_effect=lambda event, handler: mock_request_handler if event == "request" else None)
    mock_page.wait_for_load_state = AsyncMock()
    
    # Mock evaluate for performance metrics
    mock_page.evaluate = AsyncMock(return_value={
        "load_time": 1000,
        "dom_content_loaded": 500,
        "first_paint": 200,
        "first_contentful_paint": 300
    })
    
    emit_calls = []
    def mock_emit(level, message):
        emit_calls.append((level, message))
    
    result = await analytics_run(mock_page, mock_emit)
    
    assert "vendors" in result
    assert "tracking_ids" in result
    assert "performance" in result
    assert result["vendors"]["google_analytics"] is True
    assert "G-ABC123" in result["tracking_ids"]["ga4"]

@pytest.mark.asyncio
async def test_usability_tool():
    """Test usability tool with mocked page"""
    mock_page = Mock()
    mock_page.viewport_size = {"width": 1920, "height": 1080}
    
    # Mock evaluate calls
    mock_page.evaluate = AsyncMock(side_effect=[
        # Heading structure
        {
            "structure": [
                {"tag": "H1", "text": "Main Title", "level": 1},
                {"tag": "H2", "text": "Subtitle", "level": 2}
            ],
            "hasH1": True,
            "total": 2
        },
        # Image analysis
        {
            "total": 3,
            "withAlt": 2,
            "withoutAlt": 1,
            "decorative": 0,
            "missingAlt": [{"src": "image.jpg", "width": 100, "height": 100}]
        },
        # Form analysis
        {
            "total": 2,
            "withLabels": 1,
            "withoutLabels": 1,
            "missingLabels": [{"type": "text", "name": "email"}]
        },
        # Touch targets
        {
            "total": 5,
            "tooSmall": 1,
            "smallTargets": [{"tag": "A", "text": "Link", "width": 20, "height": 20}]
        },
        # Color analysis
        {
            "total": 10,
            "checked": 10,
            "lowContrast": 0
        },
        # Responsive checks
        {
            "hasViewport": True,
            "viewportContent": "width=device-width, initial-scale=1.0",
            "mediaQueries": 3,
            "hasResponsiveImages": True
        },
        # Link analysis
        {
            "total": 10,
            "internal": 5,
            "external": 3,
            "mailto": 1,
            "tel": 1,
            "javascript": 0
        }
    ])
    
    emit_calls = []
    def mock_emit(level, message):
        emit_calls.append((level, message))
    
    result = await usability_run(mock_page, mock_emit)
    
    assert "issues" in result
    assert "recommendations" in result
    assert "score" in result
    assert isinstance(result["issues"], list)
    assert isinstance(result["recommendations"], list)
    assert 0 <= result["score"] <= 100

@pytest.mark.asyncio
async def test_accessibility_tool():
    """Test accessibility tool with mocked page"""
    mock_page = Mock()
    
    # Mock evaluate calls
    mock_page.evaluate = AsyncMock(side_effect=[
        # ARIA analysis
        {
            "total": 100,
            "withAria": 5,
            "ariaLabels": 2,
            "ariaDescribedBy": 1,
            "ariaHidden": 0,
            "invalidAria": 0,
            "issues": []
        },
        # Heading analysis
        {
            "structure": [
                {"tag": "H1", "text": "Main Title", "level": 1, "id": "main-title"},
                {"tag": "H2", "text": "Subtitle", "level": 2, "id": None}
            ],
            "hasH1": True,
            "total": 2,
            "issues": []
        },
        # Image analysis
        {
            "total": 3,
            "withAlt": 2,
            "withoutAlt": 1,
            "decorative": 0,
            "missingAlt": [{"src": "image.jpg", "width": 100, "height": 100}],
            "longAlt": 0
        },
        # Form analysis
        {
            "total": 2,
            "withLabels": 1,
            "withoutLabels": 1,
            "withAriaLabel": 0,
            "withPlaceholder": 0,
            "missingLabels": [{"type": "text", "name": "email", "required": True}],
            "requiredWithoutAria": 1
        },
        # Keyboard analysis
        {
            "total": 10,
            "withTabIndex": 2,
            "tabIndexZero": 1,
            "tabIndexPositive": 1,
            "tabIndexNegative": 0,
            "issues": []
        },
        # Contrast analysis
        {
            "total": 20,
            "checked": 20,
            "potentialIssues": 0
        },
        # Focus analysis
        {
            "total": 8,
            "withFocusStyles": 6,
            "withoutFocusStyles": 2
        },
        # Language analysis
        {
            "hasLang": True,
            "langValue": "en",
            "issues": []
        }
    ])
    
    emit_calls = []
    def mock_emit(level, message):
        emit_calls.append((level, message))
    
    result = await accessibility_run(mock_page, mock_emit)
    
    assert "issues" in result
    assert "warnings" in result
    assert "recommendations" in result
    assert "score" in result
    assert "wcag_level" in result
    assert isinstance(result["issues"], list)
    assert isinstance(result["warnings"], list)
    assert isinstance(result["recommendations"], list)
    assert 0 <= result["score"] <= 100
    assert result["wcag_level"] in ["A", "AA", "F"]

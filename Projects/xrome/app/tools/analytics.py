import re
from typing import Dict, Any, List
from playwright.async_api import Page

async def run(page: Page, emit) -> Dict[str, Any]:
    """Run analytics audit on the page"""
    emit("info", "Scanning for analytics tools...")
    
    # Track network requests
    requests = []
    page.on("request", lambda request: requests.append({
        "url": request.url,
        "method": request.method,
        "resource_type": request.resource_type
    }))
    
    # Wait for page to fully load
    await page.wait_for_load_state("networkidle")
    
    # Get page content
    html = await page.content()
    
    # Check for analytics vendors
    vendors = {
        "google_analytics": False,
        "google_tag_manager": False,
        "facebook_pixel": False,
        "mixpanel": False,
        "amplitude": False,
        "clarity": False,
        "hotjar": False,
        "segment": False,
        "adobe_analytics": False,
        "matomo": False
    }
    
    # Check URLs for analytics services
    analytics_urls = {
        "google_analytics": ["google-analytics.com", "googletagmanager.com", "gtag/js"],
        "google_tag_manager": ["googletagmanager.com"],
        "facebook_pixel": ["connect.facebook.net", "facebook.com/tr"],
        "mixpanel": ["api.mixpanel.com"],
        "amplitude": ["api.amplitude.com"],
        "clarity": ["clarity.ms"],
        "hotjar": ["hotjar.com", "script.hotjar.com"],
        "segment": ["segment.io", "cdn.segment.com"],
        "adobe_analytics": ["omtrdc.net", "adobe.com/analytics"],
        "matomo": ["matomo.org", "piwik.org"]
    }
    
    for vendor, patterns in analytics_urls.items():
        for pattern in patterns:
            if any(pattern in req["url"] for req in requests):
                vendors[vendor] = True
                break
    
    # Extract tracking IDs
    tracking_ids = {
        "ga4": [],
        "gtm": [],
        "facebook_pixel": [],
        "mixpanel": [],
        "amplitude": []
    }
    
    # GA4 IDs (G-XXXXXXXXXX)
    ga4_matches = re.findall(r'G-[A-Z0-9]{6,12}', html)
    tracking_ids["ga4"] = list(set(ga4_matches))
    
    # GTM IDs (GTM-XXXXXXX)
    gtm_matches = re.findall(r'GTM-[A-Z0-9]+', html)
    tracking_ids["gtm"] = list(set(gtm_matches))
    
    # Facebook Pixel ID
    fb_matches = re.findall(r'fbq\s*\(\s*[\'"]init[\'"]\s*,\s*[\'"]?(\d+)[\'"]?', html)
    tracking_ids["facebook_pixel"] = list(set(fb_matches))
    
    # Mixpanel token
    mixpanel_matches = re.findall(r'mixpanel\.init\s*\(\s*[\'"]([^\'"]+)[\'"]', html)
    tracking_ids["mixpanel"] = list(set(mixpanel_matches))
    
    # Amplitude API key
    amplitude_matches = re.findall(r'amplitude\.init\s*\(\s*[\'"]([^\'"]+)[\'"]', html)
    tracking_ids["amplitude"] = list(set(amplitude_matches))
    
    # Count total requests by type
    request_stats = {}
    for req in requests:
        req_type = req["resource_type"]
        request_stats[req_type] = request_stats.get(req_type, 0) + 1
    
    # Check for common analytics patterns in HTML
    html_patterns = {
        "gtag": "gtag" in html.lower(),
        "ga_gtag": "gtag(" in html,
        "ga_analytics": "ga(" in html,
        "fbq": "fbq(" in html,
        "mixpanel": "mixpanel" in html.lower(),
        "amplitude": "amplitude" in html.lower(),
        "clarity": "clarity" in html.lower(),
        "hotjar": "hotjar" in html.lower()
    }
    
    # Performance metrics
    performance = await page.evaluate("""
        () => {
            const navigation = performance.getEntriesByType('navigation')[0];
            const paint = performance.getEntriesByType('paint');
            
            return {
                load_time: navigation ? navigation.loadEventEnd - navigation.loadEventStart : 0,
                dom_content_loaded: navigation ? navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart : 0,
                first_paint: paint.find(p => p.name === 'first-paint')?.startTime || 0,
                first_contentful_paint: paint.find(p => p.name === 'first-contentful-paint')?.startTime || 0
            };
        }
    """)
    
    emit("info", f"Found {len(requests)} network requests")
    emit("info", f"Detected {sum(vendors.values())} analytics vendors")
    
    return {
        "vendors": vendors,
        "tracking_ids": tracking_ids,
        "html_patterns": html_patterns,
        "request_stats": request_stats,
        "total_requests": len(requests),
        "performance": performance,
        "sample_requests": requests[:50]  # First 50 requests for debugging
    }

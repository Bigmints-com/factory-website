from typing import Dict, Any
from playwright.async_api import Page

async def run(page: Page, emit) -> Dict[str, Any]:
    """Run usability audit on the page"""
    emit("info", "Analyzing page usability...")
    
    # Get page dimensions
    viewport = await page.viewport_size()
    
    # Check for common usability issues
    issues = []
    recommendations = []
    
    # 1. Check for proper heading hierarchy
    heading_structure = await page.evaluate("""
        () => {
            const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
            const structure = [];
            let prevLevel = 0;
            let hasH1 = false;
            
            for (const h of headings) {
                const level = parseInt(h.tagName[1]);
                structure.push({
                    tag: h.tagName,
                    text: h.textContent.trim().substring(0, 100),
                    level: level
                });
                
                if (level === 1) hasH1 = true;
                
                // Check for skipped levels
                if (level > prevLevel + 1) {
                    structure[structure.length - 1].skipped = true;
                }
                prevLevel = level;
            }
            
            return {
                structure: structure,
                hasH1: hasH1,
                total: headings.length
            };
        }
    """)
    
    if not heading_structure["hasH1"]:
        issues.append("Missing H1 heading")
        recommendations.append("Add a descriptive H1 heading to improve SEO and accessibility")
    
    # 2. Check for alt text on images
    image_analysis = await page.evaluate("""
        () => {
            const images = document.querySelectorAll('img');
            const results = {
                total: images.length,
                withAlt: 0,
                withoutAlt: 0,
                decorative: 0,
                missingAlt: []
            };
            
            for (const img of images) {
                const alt = img.getAttribute('alt');
                if (alt === null) {
                    results.withoutAlt++;
                    results.missingAlt.push({
                        src: img.src.substring(0, 100),
                        width: img.width,
                        height: img.height
                    });
                } else if (alt === '') {
                    results.decorative++;
                } else {
                    results.withAlt++;
                }
            }
            
            return results;
        }
    """)
    
    if image_analysis["withoutAlt"] > 0:
        issues.append(f"{image_analysis['withoutAlt']} images missing alt text")
        recommendations.append("Add descriptive alt text to all images for better accessibility")
    
    # 3. Check for form labels
    form_analysis = await page.evaluate("""
        () => {
            const inputs = document.querySelectorAll('input, textarea, select');
            const results = {
                total: inputs.length,
                withLabels: 0,
                withoutLabels: 0,
                missingLabels: []
            };
            
            for (const input of inputs) {
                const id = input.id;
                const label = id ? document.querySelector(`label[for="${id}"]`) : null;
                const ariaLabel = input.getAttribute('aria-label');
                const placeholder = input.getAttribute('placeholder');
                
                if (label || ariaLabel || (placeholder && input.type !== 'password')) {
                    results.withLabels++;
                } else {
                    results.withoutLabels++;
                    results.missingLabels.push({
                        type: input.type || input.tagName,
                        name: input.name || 'unnamed'
                    });
                }
            }
            
            return results;
        }
    """)
    
    if form_analysis["withoutLabels"] > 0:
        issues.append(f"{form_analysis['withoutLabels']} form inputs missing labels")
        recommendations.append("Add labels or aria-labels to all form inputs")
    
    # 4. Check for clickable elements size (touch targets)
    touch_targets = await page.evaluate("""
        () => {
            const clickable = document.querySelectorAll('a, button, input[type="button"], input[type="submit"], [onclick], [role="button"]');
            const results = {
                total: clickable.length,
                tooSmall: 0,
                smallTargets: []
            };
            
            for (const el of clickable) {
                const rect = el.getBoundingClientRect();
                const minSize = 44; // 44px minimum for touch targets
                
                if (rect.width < minSize || rect.height < minSize) {
                    results.tooSmall++;
                    results.smallTargets.push({
                        tag: el.tagName,
                        text: el.textContent.trim().substring(0, 50),
                        width: Math.round(rect.width),
                        height: Math.round(rect.height)
                    });
                }
            }
            
            return results;
        }
    """)
    
    if touch_targets["tooSmall"] > 0:
        issues.append(f"{touch_targets['tooSmall']} clickable elements too small for touch")
        recommendations.append("Ensure clickable elements are at least 44x44 pixels for mobile usability")
    
    # 5. Check for color contrast (basic check)
    color_analysis = await page.evaluate("""
        () => {
            const textElements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, span, a, li');
            const results = {
                total: textElements.length,
                checked: 0,
                lowContrast: 0
            };
            
            // This is a simplified check - in reality you'd need a proper contrast calculation
            for (const el of textElements) {
                const style = getComputedStyle(el);
                const color = style.color;
                const bgColor = style.backgroundColor;
                
                // Basic check for very low contrast
                if (color === 'rgb(255, 255, 255)' && bgColor === 'rgb(255, 255, 255)') {
                    results.lowContrast++;
                } else if (color === 'rgb(0, 0, 0)' && bgColor === 'rgb(0, 0, 0)') {
                    results.lowContrast++;
                }
                
                results.checked++;
            }
            
            return results;
        }
    """)
    
    if color_analysis["lowContrast"] > 0:
        issues.append(f"{color_analysis['lowContrast']} elements may have low color contrast")
        recommendations.append("Check color contrast ratios to ensure text is readable")
    
    # 6. Check for responsive design indicators
    responsive_checks = await page.evaluate("""
        () => {
            const viewport = document.querySelector('meta[name="viewport"]');
            const mediaQueries = [];
            
            // Check for CSS media queries
            for (const sheet of document.styleSheets) {
                try {
                    for (const rule of sheet.cssRules) {
                        if (rule.type === CSSRule.MEDIA_RULE) {
                            mediaQueries.push(rule.media.mediaText);
                        }
                    }
                } catch (e) {
                    // Cross-origin stylesheets
                }
            }
            
            return {
                hasViewport: !!viewport,
                viewportContent: viewport ? viewport.content : null,
                mediaQueries: mediaQueries.length,
                hasResponsiveImages: document.querySelectorAll('img[srcset]').length > 0
            };
        }
    """)
    
    if not responsive_checks["hasViewport"]:
        issues.append("Missing viewport meta tag")
        recommendations.append("Add viewport meta tag for mobile responsiveness")
    
    # 7. Check for broken links (sample)
    broken_links = await page.evaluate("""
        () => {
            const links = document.querySelectorAll('a[href]');
            const results = {
                total: links.length,
                internal: 0,
                external: 0,
                mailto: 0,
                tel: 0,
                javascript: 0
            };
            
            for (const link of links) {
                const href = link.href;
                if (href.startsWith('mailto:')) {
                    results.mailto++;
                } else if (href.startsWith('tel:')) {
                    results.tel++;
                } else if (href.startsWith('javascript:')) {
                    results.javascript++;
                } else if (href.startsWith(window.location.origin)) {
                    results.internal++;
                } else {
                    results.external++;
                }
            }
            
            return results;
        }
    """)
    
    emit("info", f"Found {len(issues)} usability issues")
    emit("info", f"Generated {len(recommendations)} recommendations")
    
    return {
        "viewport": viewport,
        "issues": issues,
        "recommendations": recommendations,
        "heading_structure": heading_structure,
        "image_analysis": image_analysis,
        "form_analysis": form_analysis,
        "touch_targets": touch_targets,
        "color_analysis": color_analysis,
        "responsive_checks": responsive_checks,
        "link_analysis": broken_links,
        "score": max(0, 100 - len(issues) * 10)  # Simple scoring
    }

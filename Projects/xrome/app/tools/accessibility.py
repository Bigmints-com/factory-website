from typing import Dict, Any
from playwright.async_api import Page

async def run(page: Page, emit) -> Dict[str, Any]:
    """Run accessibility audit on the page"""
    emit("info", "Running accessibility analysis...")
    
    issues = []
    warnings = []
    recommendations = []
    
    # 1. Check for proper ARIA usage
    aria_analysis = await page.evaluate("""
        () => {
            const elements = document.querySelectorAll('*');
            const results = {
                total: elements.length,
                withAria: 0,
                ariaLabels: 0,
                ariaDescribedBy: 0,
                ariaHidden: 0,
                invalidAria: 0,
                issues: []
            };
            
            for (const el of elements) {
                const ariaAttrs = Array.from(el.attributes)
                    .filter(attr => attr.name.startsWith('aria-'));
                
                if (ariaAttrs.length > 0) {
                    results.withAria++;
                    
                    for (const attr of ariaAttrs) {
                        if (attr.name === 'aria-label') {
                            results.ariaLabels++;
                        } else if (attr.name === 'aria-describedby') {
                            results.ariaDescribedBy++;
                        } else if (attr.name === 'aria-hidden') {
                            results.ariaHidden++;
                        }
                    }
                    
                    // Check for invalid ARIA attributes
                    const validAriaAttrs = [
                        'aria-label', 'aria-labelledby', 'aria-describedby', 'aria-hidden',
                        'aria-expanded', 'aria-selected', 'aria-checked', 'aria-pressed',
                        'aria-disabled', 'aria-required', 'aria-invalid', 'aria-live',
                        'aria-atomic', 'aria-busy', 'aria-controls', 'aria-flowto',
                        'aria-owns', 'aria-activedescendant', 'aria-autocomplete',
                        'aria-haspopup', 'aria-level', 'aria-multiline', 'aria-multiselectable',
                        'aria-orientation', 'aria-readonly', 'aria-sort', 'aria-valuemax',
                        'aria-valuemin', 'aria-valuenow', 'aria-valuetext', 'aria-atomic',
                        'aria-busy', 'aria-live', 'aria-relevant', 'aria-atomic'
                    ];
                    
                    for (const attr of ariaAttrs) {
                        if (!validAriaAttrs.includes(attr.name)) {
                            results.invalidAria++;
                            results.issues.push({
                                element: el.tagName,
                                attribute: attr.name,
                                value: attr.value
                            });
                        }
                    }
                }
            }
            
            return results;
        }
    """)
    
    if aria_analysis["invalidAria"] > 0:
        issues.append(f"{aria_analysis['invalidAria']} invalid ARIA attributes found")
        recommendations.append("Remove or fix invalid ARIA attributes")
    
    # 2. Check for proper heading structure
    heading_analysis = await page.evaluate("""
        () => {
            const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
            const structure = [];
            let prevLevel = 0;
            let hasH1 = false;
            let issues = [];
            
            for (const h of headings) {
                const level = parseInt(h.tagName[1]);
                const text = h.textContent.trim();
                
                structure.push({
                    tag: h.tagName,
                    text: text.substring(0, 100),
                    level: level,
                    id: h.id || null
                });
                
                if (level === 1) {
                    if (hasH1) {
                        issues.push('Multiple H1 headings found');
                    }
                    hasH1 = true;
                }
                
                // Check for skipped levels
                if (level > prevLevel + 1 && prevLevel > 0) {
                    issues.push(`Heading level skipped from H${prevLevel} to H${level}`);
                }
                
                prevLevel = level;
            }
            
            if (!hasH1) {
                issues.push('No H1 heading found');
            }
            
            return {
                structure: structure,
                hasH1: hasH1,
                total: headings.length,
                issues: issues
            };
        }
    """)
    
    issues.extend(heading_analysis["issues"])
    if not heading_analysis["hasH1"]:
        recommendations.append("Add a descriptive H1 heading")
    if any("skipped" in issue for issue in heading_analysis["issues"]):
        recommendations.append("Maintain proper heading hierarchy (don't skip levels)")
    
    # 3. Check for alt text on images
    image_analysis = await page.evaluate("""
        () => {
            const images = document.querySelectorAll('img');
            const results = {
                total: images.length,
                withAlt: 0,
                withoutAlt: 0,
                decorative: 0,
                missingAlt: [],
                longAlt: 0
            };
            
            for (const img of images) {
                const alt = img.getAttribute('alt');
                const src = img.src;
                
                if (alt === null) {
                    results.withoutAlt++;
                    results.missingAlt.push({
                        src: src.substring(0, 100),
                        width: img.width,
                        height: img.height
                    });
                } else if (alt === '') {
                    results.decorative++;
                } else {
                    results.withAlt++;
                    if (alt.length > 125) {
                        results.longAlt++;
                    }
                }
            }
            
            return results;
        }
    """)
    
    if image_analysis["withoutAlt"] > 0:
        issues.append(f"{image_analysis['withoutAlt']} images missing alt text")
        recommendations.append("Add descriptive alt text to all images")
    
    if image_analysis["longAlt"] > 0:
        warnings.append(f"{image_analysis['longAlt']} images have very long alt text")
        recommendations.append("Keep alt text concise (under 125 characters)")
    
    # 4. Check for form accessibility
    form_analysis = await page.evaluate("""
        () => {
            const inputs = document.querySelectorAll('input, textarea, select');
            const results = {
                total: inputs.length,
                withLabels: 0,
                withoutLabels: 0,
                withAriaLabel: 0,
                withPlaceholder: 0,
                missingLabels: [],
                requiredWithoutAria: 0
            };
            
            for (const input of inputs) {
                const id = input.id;
                const label = id ? document.querySelector(`label[for="${id}"]`) : null;
                const ariaLabel = input.getAttribute('aria-label');
                const placeholder = input.getAttribute('placeholder');
                const required = input.hasAttribute('required');
                
                if (label) {
                    results.withLabels++;
                } else if (ariaLabel) {
                    results.withAriaLabel++;
                } else if (placeholder) {
                    results.withPlaceholder++;
                } else {
                    results.withoutLabels++;
                    results.missingLabels.push({
                        type: input.type || input.tagName,
                        name: input.name || 'unnamed',
                        required: required
                    });
                }
                
                if (required && !ariaLabel && !label) {
                    results.requiredWithoutAria++;
                }
            }
            
            return results;
        }
    """)
    
    if form_analysis["withoutLabels"] > 0:
        issues.append(f"{form_analysis['withoutLabels']} form inputs missing labels")
        recommendations.append("Add labels or aria-labels to all form inputs")
    
    if form_analysis["requiredWithoutAria"] > 0:
        issues.append(f"{form_analysis['requiredWithoutAria']} required inputs missing accessibility labels")
        recommendations.append("Add aria-required and proper labels to required form fields")
    
    # 5. Check for keyboard navigation
    keyboard_analysis = await page.evaluate("""
        () => {
            const interactive = document.querySelectorAll('a, button, input, select, textarea, [tabindex], [onclick]');
            const results = {
                total: interactive.length,
                withTabIndex: 0,
                tabIndexZero: 0,
                tabIndexPositive: 0,
                tabIndexNegative: 0,
                issues: []
            };
            
            for (const el of interactive) {
                const tabIndex = el.getAttribute('tabindex');
                if (tabIndex !== null) {
                    results.withTabIndex++;
                    const index = parseInt(tabIndex);
                    
                    if (index === 0) {
                        results.tabIndexZero++;
                    } else if (index > 0) {
                        results.tabIndexPositive++;
                    } else {
                        results.tabIndexNegative++;
                    }
                    
                    // Check for very high tabindex values
                    if (index > 100) {
                        results.issues.push('Very high tabindex value: ' + tabIndex);
                    }
                }
                
                // Check for elements that should be focusable but aren't
                if (el.tagName === 'A' && !el.href && !el.getAttribute('tabindex')) {
                    results.issues.push('Link without href should have tabindex');
                }
            }
            
            return results;
        }
    """)
    
    if keyboard_analysis["tabIndexPositive"] > 0:
        warnings.append(f"{keyboard_analysis['tabIndexPositive']} elements with positive tabindex")
        recommendations.append("Avoid positive tabindex values - use natural tab order")
    
    # 6. Check for color contrast (basic)
    contrast_analysis = await page.evaluate("""
        () => {
            const textElements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, span, a, li, button');
            const results = {
                total: textElements.length,
                checked: 0,
                potentialIssues: 0
            };
            
            for (const el of textElements) {
                const style = getComputedStyle(el);
                const color = style.color;
                const bgColor = style.backgroundColor;
                
                // Very basic check for obvious contrast issues
                if (color === bgColor) {
                    results.potentialIssues++;
                }
                
                results.checked++;
            }
            
            return results;
        }
    """)
    
    if contrast_analysis["potentialIssues"] > 0:
        warnings.append(f"{contrast_analysis['potentialIssues']} elements may have color contrast issues")
        recommendations.append("Use a color contrast checker to ensure WCAG compliance")
    
    # 7. Check for focus indicators
    focus_analysis = await page.evaluate("""
        () => {
            const focusable = document.querySelectorAll('a, button, input, select, textarea, [tabindex]');
            const results = {
                total: focusable.length,
                withFocusStyles: 0,
                withoutFocusStyles: 0
            };
            
            for (const el of focusable) {
                const style = getComputedStyle(el, ':focus');
                const outline = style.outline;
                const boxShadow = style.boxShadow;
                
                if (outline !== 'none' || boxShadow !== 'none') {
                    results.withFocusStyles++;
                } else {
                    results.withoutFocusStyles++;
                }
            }
            
            return results;
        }
    """)
    
    if focus_analysis["withoutFocusStyles"] > 0:
        warnings.append(f"{focus_analysis['withoutFocusStyles']} focusable elements lack visible focus indicators")
        recommendations.append("Add visible focus indicators for keyboard navigation")
    
    # 8. Check for language declaration
    lang_analysis = await page.evaluate("""
        () => {
            const html = document.documentElement;
            const lang = html.getAttribute('lang');
            
            return {
                hasLang: !!lang,
                langValue: lang,
                issues: lang ? [] : ['Missing lang attribute on html element']
            };
        }
    """)
    
    if not lang_analysis["hasLang"]:
        issues.append("Missing language declaration")
        recommendations.append("Add lang attribute to html element")
    
    emit("info", f"Found {len(issues)} accessibility issues")
    emit("info", f"Found {len(warnings)} accessibility warnings")
    emit("info", f"Generated {len(recommendations)} recommendations")
    
    # Calculate accessibility score
    total_checks = 8
    issue_penalty = len(issues) * 2
    warning_penalty = len(warnings)
    score = max(0, 100 - issue_penalty - warning_penalty)
    
    return {
        "issues": issues,
        "warnings": warnings,
        "recommendations": recommendations,
        "aria_analysis": aria_analysis,
        "heading_analysis": heading_analysis,
        "image_analysis": image_analysis,
        "form_analysis": form_analysis,
        "keyboard_analysis": keyboard_analysis,
        "contrast_analysis": contrast_analysis,
        "focus_analysis": focus_analysis,
        "lang_analysis": lang_analysis,
        "score": score,
        "wcag_level": "AA" if score >= 80 else "A" if score >= 60 else "F"
    }

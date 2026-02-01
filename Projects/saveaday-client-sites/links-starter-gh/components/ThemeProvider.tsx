import React, { useEffect } from 'react';
import { ThemeConfig } from '../types';

interface ThemeProviderProps {
  theme: ThemeConfig;
  children: React.ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ theme, children }) => {
  useEffect(() => {
    // 1. Dynamic Font Loading
    if (theme.font && theme.font !== 'sans' && theme.font !== 'serif') {
      const fontId = 'dynamic-font-link';
      let link = document.getElementById(fontId) as HTMLLinkElement;
      
      if (!link) {
        link = document.createElement('link');
        link.id = fontId;
        link.rel = 'stylesheet';
        document.head.appendChild(link);
      }
      
      const formattedFont = theme.font.replace(/\s+/g, '+');
      link.href = `https://fonts.googleapis.com/css2?family=${formattedFont}:wght@400;500;600;700&display=swap`;
    }

    // 2. Dynamic CSS Variables
    const root = document.documentElement;
    
    // Set font family
    if (theme.font) {
      const fontFamily = theme.font === 'sans' ? 'Inter, sans-serif' : 
                         theme.font === 'serif' ? 'serif' : 
                         `"${theme.font}", sans-serif`;
      root.style.setProperty('--app-font', fontFamily);
    }

    // Handle background if it's a custom color or gradient
    if (theme.background && !theme.background.startsWith('bg-')) {
      root.style.setProperty('--app-background', theme.background);
    } else {
      root.style.removeProperty('--app-background');
    }

  }, [theme]);

  // Apply font family globally via a style tag if needed, or use the variable
  return (
    <div style={{ fontFamily: 'var(--app-font, Inter, sans-serif)' }}>
      {children}
    </div>
  );
};

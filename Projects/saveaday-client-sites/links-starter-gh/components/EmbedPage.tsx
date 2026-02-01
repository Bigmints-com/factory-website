
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ThemeConfig } from '../types';
import { ArrowLeft, Info } from 'lucide-react';
import { ThemeProvider } from './ThemeProvider';

interface EmbedPageProps {
  title: string;
  description: string;
  embedCode: string;
  theme: ThemeConfig;
  businessName: string;
}

export const EmbedPage: React.FC<EmbedPageProps> = ({ 
  title, 
  description, 
  embedCode, 
  theme,
  businessName 
}) => {
  const navigate = useNavigate();
  const [containerId] = useState(`embed-${Math.random().toString(36).substr(2, 9)}`);

  useEffect(() => {
    // Set dynamic SEO
    document.title = `${title} | ${businessName}`;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) {
      metaDesc.setAttribute('content', description);
    }

    // Execute scripts in embed code
    const container = document.getElementById(containerId);
    if (container && embedCode) {
      container.innerHTML = embedCode;
      const scripts = container.getElementsByTagName('script');
      for (let i = 0; i < scripts.length; i++) {
        const script = document.createElement('script');
        if (scripts[i].src) {
          script.src = scripts[i].src;
          // Preserve data attributes
          const attrs = scripts[i].attributes;
          for (let j = 0; j < attrs.length; j++) {
            if (attrs[j].name.startsWith('data-')) {
              script.setAttribute(attrs[j].name, attrs[j].value);
            }
          }
        } else {
          script.textContent = scripts[i].textContent;
        }
        document.body.appendChild(script);
      }
    }
  }, [title, businessName, description, embedCode, containerId]);

  const isCustomBg = theme?.background && !theme.background.startsWith('bg-');

  return (
    <ThemeProvider theme={theme}>
      <div 
        className={`min-h-screen w-full flex flex-col py-8 px-4 sm:px-6 transition-all duration-700 ${!isCustomBg ? theme.background : ''}`}
        style={isCustomBg ? { background: 'var(--app-background)' } : {}}
      >
        <div className="max-w-3xl w-full mx-auto flex-1">
          {/* Header */}
          <div className="mb-8">
            <button
              onClick={() => navigate('/')}
              className="flex items-center gap-2 text-slate-600 hover:text-slate-900 transition-colors mb-4 group"
            >
              <ArrowLeft className="w-5 h-5 group-hover:-translate-x-1 transition-transform" />
              <span className="font-semibold">Back</span>
            </button>
            <h1 className="text-3xl font-extrabold text-slate-900 mb-2 tracking-tight">
              {title}
            </h1>
            <p className="text-slate-600 font-medium">
              {description}
            </p>
          </div>

          {/* Embed Container */}
          <div className="bg-white border border-slate-200 rounded-2xl p-4 sm:p-8 shadow-sm min-h-[500px]">
            <div id={containerId} className="w-full"></div>
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-12 text-center pb-8">
          <p className="text-xs text-slate-400 uppercase tracking-widest font-bold opacity-60">
            © 2026 {businessName}
          </p>
        </footer>

        {/* Info Button */}
        <a 
          href="https://saveaday.ai" 
          target="_blank" 
          rel="noopener noreferrer"
          className="fixed bottom-6 right-6 p-3 bg-white/80 backdrop-blur-sm border border-slate-200 rounded-full shadow-lg hover:shadow-xl hover:scale-110 transition-all group z-50"
          title="Powered by SaveADay"
        >
          <Info className="w-5 h-5 text-indigo-600 group-hover:text-indigo-700" />
        </a>
      </div>
    </ThemeProvider>
  );
};

'use client';

import { useState, useEffect } from 'react';
import Script from 'next/script';

declare global {
  interface Window {
    showLeadFormModal?: () => void;
    __leadFormModalRegistry?: Record<string, { open: () => void; close: () => void }>;
  }
}

interface LeadFormPreviewButtonProps {
  embedToken?: string;
  leadFormId?: string;
}

export function LeadFormPreviewButton({ embedToken, leadFormId }: LeadFormPreviewButtonProps) {
  const [appUrl, setAppUrl] = useState('http://localhost:3000');
  const [isReady, setIsReady] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setAppUrl(window.location.origin);
    }
  }, []);

  useEffect(() => {
    if (!embedToken) return;

    const checkScript = () => {
      if (typeof window === 'undefined') return false;
      
      if (window.showLeadFormModal) {
        setIsReady(true);
        return true;
      }
      
      const registry = window.__leadFormModalRegistry;
      if (registry && registry[embedToken] && registry[embedToken].open) {
        setIsReady(true);
        return true;
      }
      
      return false;
    };
    
    if (checkScript()) return;
    
    const interval = setInterval(() => {
      if (checkScript()) {
        clearInterval(interval);
      }
    }, 100);
    
    const timeout = setTimeout(() => {
      clearInterval(interval);
    }, 5000);
    
    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, [embedToken]);

  const handlePreview = () => {
    if (typeof window === 'undefined') return;
    
    if (window.showLeadFormModal) {
      try {
        window.showLeadFormModal();
        return;
      } catch (error) {
        console.error('Error calling showLeadFormModal:', error);
      }
    }
    
    const registry = window.__leadFormModalRegistry;
    if (registry && embedToken && registry[embedToken] && registry[embedToken].open) {
      try {
        registry[embedToken].open();
        return;
      } catch (error) {
        console.error('Error calling registry.open:', error);
      }
    }
    
    alert('Preview is not ready. Please ensure the lead form is saved and active.');
  };

  if (!embedToken) {
    return (
      <button
        type="button"
        disabled
        className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-400 shadow-sm cursor-not-allowed"
        title="Save the lead form first to preview"
      >
        Preview
      </button>
    );
  }

  return (
    <>
      <Script
        src={`${appUrl}/embed/${embedToken}.js`}
        data-leadform-token={embedToken}
        strategy="afterInteractive"
        onLoad={() => {
          setTimeout(() => {
            if (window.showLeadFormModal || (window.__leadFormModalRegistry && window.__leadFormModalRegistry[embedToken])) {
              setIsReady(true);
            } else {
              setTimeout(() => {
                if (window.showLeadFormModal || (window.__leadFormModalRegistry && window.__leadFormModalRegistry[embedToken])) {
                  setIsReady(true);
                }
              }, 1000);
            }
          }, 500);
        }}
      />
      <button
        type="button"
        onClick={handlePreview}
        disabled={!isReady}
        className="rounded-md border border-blue-600 bg-blue-50 px-4 py-2 text-sm font-medium text-blue-700 shadow-sm transition hover:bg-blue-100 disabled:opacity-50 disabled:cursor-not-allowed"
        title={!isReady ? 'Loading preview...' : 'Preview the lead form modal'}
      >
        {isReady ? 'Preview' : 'Loading...'}
      </button>
    </>
  );
}

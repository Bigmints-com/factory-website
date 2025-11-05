'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Script from 'next/script';

declare global {
  interface Window {
    showLeadFormModal?: () => void;
    __leadFormModalRegistry?: Record<string, { open: () => void; close: () => void }>;
  }
}

// Update this token with a valid leadForm embed token from your dashboard
// To get a token: 1. Login to dashboard, 2. Create or open a leadForm, 3. Copy the embed token
const LEADFORM_TOKEN = '7fce994a363f8f3abef1249f';

export default function Home() {
  // Use current origin for the script URL (works in dev and production)
  const [appUrl, setAppUrl] = useState('http://localhost:3000');
  const [isReady, setIsReady] = useState(false);
  
  useEffect(() => {
    // Get the actual origin from the browser
    if (typeof window !== 'undefined') {
      setAppUrl(window.location.origin);
    }
  }, []);
  
  useEffect(() => {
    // Poll for script availability
    const checkScript = () => {
      if (typeof window === 'undefined') return false;
      
      // Check direct function
      if (window.showLeadFormModal) {
        setIsReady(true);
        return true;
      }
      
      // Check registry
      const registry = window.__leadFormModalRegistry;
      if (registry && registry[LEADFORM_TOKEN] && registry[LEADFORM_TOKEN].open) {
        setIsReady(true);
        return true;
      }
      
      return false;
    };
    
    // Check immediately
    if (checkScript()) return;
    
    // Poll every 100ms for up to 5 seconds
    const interval = setInterval(() => {
      if (checkScript()) {
        clearInterval(interval);
      }
    }, 100);
    
    const timeout = setTimeout(() => {
      clearInterval(interval);
      console.warn('LeadForm script did not load within 5 seconds');
    }, 5000);
    
    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, []);
  
  const handleJoinLeadForm = () => {
    if (typeof window === 'undefined') return;
    
    console.log('Join LeadForm clicked');
    
    // Try direct function first
    if (window.showLeadFormModal) {
      try {
        window.showLeadFormModal();
        return;
      } catch (error) {
        console.error('Error calling showLeadFormModal:', error);
      }
    }
    
    // Try registry
    const registry = window.__leadFormModalRegistry;
    if (registry && registry[LEADFORM_TOKEN] && registry[LEADFORM_TOKEN].open) {
      try {
        registry[LEADFORM_TOKEN].open();
        return;
      } catch (error) {
        console.error('Error calling registry.open:', error);
      }
    }
    
    // If still not available, show helpful message
    console.error('LeadForm modal not available');
    console.log('window.showLeadFormModal:', window.showLeadFormModal);
    console.log('Registry:', registry);
    alert('LeadForm modal is not ready. Please check:\n1. The leadForm exists and is active\n2. The script loaded successfully\n3. Check browser console for errors');
  };
  
  return (
    <>
      <Script
        src={`${appUrl}/embed/${LEADFORM_TOKEN}.js`}
        data-leadform-token={LEADFORM_TOKEN}
        strategy="afterInteractive"
        onLoad={() => {
          console.log('LeadForm script loaded, waiting for initialization...');
          console.log('Script URL:', `${appUrl}/embed/${LEADFORM_TOKEN}.js`);
          // Give it a moment to initialize
          setTimeout(() => {
            if (window.showLeadFormModal || (window.__leadFormModalRegistry && window.__leadFormModalRegistry[LEADFORM_TOKEN])) {
              console.log('LeadForm modal ready!');
              setIsReady(true);
            } else {
              console.warn('Script loaded but modal function not available yet');
              // Try again after another second
              setTimeout(() => {
                if (window.showLeadFormModal || (window.__leadFormModalRegistry && window.__leadFormModalRegistry[LEADFORM_TOKEN])) {
                  console.log('LeadForm modal ready (delayed)!');
                  setIsReady(true);
                }
              }, 1000);
            }
          }, 500);
        }}
        onError={() => {
          console.error('Failed to load leadForm script');
          console.error('LeadForm token:', LEADFORM_TOKEN);
          console.error('Script URL:', `${appUrl}/embed/${LEADFORM_TOKEN}.js`);
          console.error('Please verify:');
          console.error('1. The leadForm exists and is active');
          console.error('2. The embed token is correct');
          console.error('3. Try visiting the script URL directly in your browser');
        }}
      />
      <div className="flex min-h-screen w-full flex-col bg-gray-50 text-gray-900 font-mono">
      <div className="mx-auto flex w-full max-w-6xl flex-1 flex-col px-6 py-16">
        <header className="flex items-center justify-between">
          <span className="text-lg font-medium text-gray-900">
            LeadForm Platform
          </span>
          <div className="flex items-center gap-4">
            <Link
              href="/login"
              className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition hover:bg-gray-50"
            >
              Log in
            </Link>
            <Link
              href="/register"
              className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
            >
              Get Started
            </Link>
          </div>
        </header>

        <main className="mt-24 space-y-24">
          {/* Hero Section */}
          <div className="flex flex-col gap-10 lg:flex-row lg:items-center lg:justify-between">
            <div className="max-w-2xl space-y-6">
              <h1 className="text-4xl font-semibold leading-tight text-gray-900 sm:text-5xl">
                Build your leadForm in minutes, not days
              </h1>
              <p className="text-lg text-gray-600">
                Collect signups for your product launch with a beautiful, customizable leadForm. 
                Set up in minutes and let it run in the background—reclaim your time for the work 
                that matters most.
              </p>
              <div className="flex flex-wrap gap-4">
                <Link
                  href="/register"
                  className="rounded-md bg-blue-600 px-6 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
                >
                  Get started free
                </Link>
                <Link
                  href="/login"
                  className="rounded-md border border-gray-300 bg-white px-6 py-3 text-sm font-medium text-gray-700 shadow-sm transition hover:bg-gray-50"
                >
                  Sign in
                </Link>
                <button
                  onClick={handleJoinLeadForm}
                  disabled={!isReady}
                  className="rounded-md border border-blue-600 bg-blue-50 px-6 py-3 text-sm font-medium text-blue-700 shadow-sm transition hover:bg-blue-100 disabled:opacity-50 disabled:cursor-not-allowed"
                  title={!isReady ? 'Waiting for leadForm script to load...' : 'Join the leadForm'}
                >
                  {isReady ? 'Join LeadForm' : 'Loading...'}
                </button>
              </div>
            </div>
          </div>

          {/* Features Section */}
          <section className="space-y-8">
            <div className="text-center space-y-2">
              <h2 className="text-3xl font-semibold text-gray-900">Simple, powerful leadForm management</h2>
              <p className="text-gray-600">Everything you need to grow your audience before launch</p>
            </div>
            <div className="grid gap-6 md:grid-cols-3">
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Customize everything</h3>
                <p className="text-sm text-gray-600">
                  Match your brand with custom colors, messages, and button text. Make your leadForm 
                  feel like part of your product.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Quick setup</h3>
                <p className="text-sm text-gray-600">
                  Get your leadForm running in minutes. Copy and paste a simple script into your 
                  website—no technical knowledge required.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Stay organized</h3>
                <p className="text-sm text-gray-600">
                  View all your signups in one place. Export your data, manage duplicates, and 
                  track your growth—all without manual tracking. Save hours every week.
                </p>
              </div>
            </div>
          </section>

          {/* Integrations Section */}
          <section className="space-y-8">
            <div className="text-center space-y-2">
              <h2 className="text-3xl font-semibold text-gray-900">Integrate with your workflows</h2>
              <p className="text-gray-600">Connect your leadForm to the tools you use every day</p>
            </div>
            <div className="grid gap-6 md:grid-cols-2">
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Connect to your tools</h3>
                <p className="text-sm text-gray-600 mb-4">
                  Pull your signup data into spreadsheets, dashboards, or any tool you use. 
                  Export everything with a simple request—no complex setup required.
                </p>
                <ul className="space-y-2 text-sm text-gray-600">
                  <li className="flex items-start gap-2">
                    <svg className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Find specific signups with simple search</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <svg className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Download your data as CSV or Excel</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <svg className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Works with your existing tools</span>
                  </li>
                </ul>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Automate with agents</h3>
                <p className="text-sm text-gray-600 mb-4">
                  Get instant notifications when someone joins. Send welcome emails, update your CRM, 
                  or trigger any workflow automatically—no manual steps needed. Let the repeat work 
                  close itself while you focus on what only you can do.
                </p>
                <ul className="space-y-2 text-sm text-gray-600">
                  <li className="flex items-start gap-2">
                    <svg className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Instant alerts when someone signs up</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <svg className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Keeps trying if something goes wrong</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <svg className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Choose which events to listen for</span>
                  </li>
                </ul>
              </div>
            </div>
          </section>

          {/* FAQ Section */}
          <section className="space-y-8">
            <div className="text-center space-y-2">
              <h2 className="text-3xl font-semibold text-gray-900">Frequently asked questions</h2>
              <p className="text-gray-600">Everything you need to know about getting started</p>
            </div>
            <div className="space-y-4">
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">How does it work?</h3>
                <p className="text-sm text-gray-600">
                  Create your leadForm, customize the look and feel, then add a simple script to your website. 
                  Visitors can sign up with their name and email, and you'll see all signups in your dashboard.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Do I need to know how to code?</h3>
                <p className="text-sm text-gray-600">
                  Not at all! Just copy and paste our script into your website. If you can add a script tag 
                  to your HTML, you can set up your leadForm in a few minutes.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">How much does it cost?</h3>
                <p className="text-sm text-gray-600">
                  The first 1,000 signups are completely free. After that, pay only for what you use—just $1 
                  for every 10 additional signups. Or save 20% with our prepaid plan.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Can I export my data?</h3>
                <p className="text-sm text-gray-600">
                  Yes! Export all your signups as CSV or JSON anytime. Your data belongs to you, and you can 
                  download it whenever you need.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">What if someone signs up twice?</h3>
                <p className="text-sm text-gray-600">
                  We automatically detect duplicate email addresses. You can choose to reject duplicates, 
                  update existing entries, or allow multiple signups—it's up to you.
                </p>
              </div>
              <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Can I use this on multiple websites?</h3>
                <p className="text-sm text-gray-600">
                  Absolutely! Create separate leadforms for different projects, or use the same leadForm 
                  across multiple sites. Each leadForm has its own embed code.
                </p>
              </div>
            </div>
          </section>
        </main>

        {/* Footer */}
        <footer className="mt-24 border-t border-gray-200 bg-white py-8">
          <div className="mx-auto max-w-6xl px-6">
            <div className="flex flex-wrap items-center justify-center gap-4 text-sm text-gray-600">
              <Link href="#" className="hover:text-gray-900">
                About
              </Link>
              <span>&copy; {new Date().getFullYear()} LeadForm Platform</span>
              <Link href="#" className="hover:text-gray-900">
                Contact
              </Link>
              <a href="https://saveaday.ai" target="_blank" rel="noopener noreferrer" className="hover:text-gray-900">
                saveaday.ai
              </a>
            </div>
          </div>
        </footer>
      </div>
      </div>
    </>
  );
}

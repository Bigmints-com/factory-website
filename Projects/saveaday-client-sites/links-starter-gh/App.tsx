
import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { PAGE_DATA, CATALOGUE_DATA, SURVEY_DATA, LEAD_FORM_DATA } from './constants';
import { LinkPage } from './types';
import { LinkCard } from './components/LinkCard';
import { CataloguePage } from './components/CataloguePage';
import { GoogleAnalytics } from './components/GoogleAnalytics';
import { Mail, Phone, MapPin, Share2, Package, Info, Clock } from 'lucide-react';

import { ThemeProvider } from './components/ThemeProvider';
import { TimingsModal } from './components/TimingsModal';

const ProfilePage: React.FC = () => {
  const [pageData] = useState<LinkPage>(PAGE_DATA);
  const [imgError, setImgError] = useState(false);
  const [isTimingsOpen, setIsTimingsOpen] = useState(false);
  
  const isCustomBg = pageData?.theme?.background && !pageData.theme.background.startsWith('bg-');

  // Inject survey and lead form embed scripts
  useEffect(() => {
    const scripts: HTMLScriptElement[] = [];

    // Inject survey embed script
    if (SURVEY_DATA?.embedCode) {
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = SURVEY_DATA.embedCode;
      const scriptTag = tempDiv.querySelector('script');
      
      if (scriptTag) {
        const script = document.createElement('script');
        if (scriptTag.src) {
          script.src = scriptTag.src;
          // Copy all data attributes
          Array.from(scriptTag.attributes).forEach(attr => {
            if (attr.name.startsWith('data-')) {
              script.setAttribute(attr.name, attr.value);
            }
          });
        }
        document.body.appendChild(script);
        scripts.push(script);
      }
    }

    // Inject lead form embed script
    if (LEAD_FORM_DATA?.embedCode) {
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = LEAD_FORM_DATA.embedCode;
      const scriptTag = tempDiv.querySelector('script');
      
      if (scriptTag) {
        const script = document.createElement('script');
        if (scriptTag.src) {
          script.src = scriptTag.src;
          // Copy all data attributes
          Array.from(scriptTag.attributes).forEach(attr => {
            if (attr.name.startsWith('data-')) {
              script.setAttribute(attr.name, attr.value);
            }
          });
        }
        document.body.appendChild(script);
        scripts.push(script);
      }
    }

    // Cleanup on unmount
    return () => {
      scripts.forEach(script => {
        if (script.parentNode) {
          script.parentNode.removeChild(script);
        }
      });
    };
  }, []);

  // Set dynamic SEO
  React.useEffect(() => {
    document.title = pageData.profile.name;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) {
      metaDesc.setAttribute('content', pageData.profile.bio);
    } else {
      const meta = document.createElement('meta');
      meta.name = 'description';
      meta.content = pageData.profile.bio;
      document.head.appendChild(meta);
    }
  }, [pageData]);

  const { profile, links, theme } = pageData;

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: profile.name,
        text: profile.bio,
        url: window.location.origin,
      }).catch(console.error);
    } else {
        navigator.clipboard.writeText(window.location.origin);
        alert('Link copied to clipboard!');
    }
  };

  const getOpenStatus = () => {
    if (!profile.businessHours) return null;
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const now = new Date();
    const dayName = days[now.getDay()];
    const todayHours = profile.businessHours.find(h => h.day === dayName);

    if (!todayHours || !todayHours.isOpen) return { isOpen: false, text: 'Closed' };

    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const [startH, startM] = todayHours.start.split(':').map(Number);
    const [endH, endM] = todayHours.end.split(':').map(Number);
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;

    // Handle overnight hours if needed (e.g. 22:00 - 02:00)
    if (endMinutes < startMinutes) {
      if (currentMinutes >= startMinutes || currentMinutes < endMinutes) {
         return { isOpen: true, text: 'Open Now' };
      }
    } else {
      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
         return { isOpen: true, text: 'Open Now' };
      }
    }
    
    return { isOpen: false, text: 'Closed' };
  };

  const openStatus = getOpenStatus();

  return (
    <ThemeProvider theme={theme}>
      <div 
        className={`min-h-screen w-full flex flex-col items-center py-8 px-4 sm:px-6 transition-all duration-700 ${!isCustomBg ? theme.background : ''}`}
        style={isCustomBg ? { background: 'var(--app-background)' } : {}}
      >
        <div className="max-w-xl w-full">
          {/* Share Button */}
          <div className="flex justify-end mb-2">
            <button 
              onClick={handleShare}
              className="p-2.5 bg-white/90 backdrop-blur-sm border border-slate-200 rounded-full hover:bg-white hover:shadow-lg transition-all active:scale-90"
              aria-label="Share profile"
            >
              <Share2 className="w-4 h-4 text-slate-600" />
            </button>
          </div>

          {/* Profile Header */}
          <div className="flex flex-col items-center mb-6 text-center">
            {profile.logo && !imgError && (
              <div className="relative mb-4">
                <div className="absolute inset-0 bg-indigo-500 rounded-full blur-2xl opacity-10 animate-pulse"></div>
                <img 
                  src={profile.logo} 
                  alt={profile.name} 
                  onError={() => setImgError(true)}
                  className="relative w-24 h-24 rounded-full border-2 border-white/50 shadow-xl object-contain bg-white p-3"
                />
              </div>
            )}
            <h1 className="text-2xl font-extrabold text-slate-900 mb-2 tracking-tight">
              {profile.name}
            </h1>
            <p className="text-slate-600 max-w-sm font-medium leading-relaxed px-4 text-sm">
              {profile.bio}
            </p>
          </div>

          {/* Info Row: Address & Timings */}
          <div className="flex flex-wrap items-center justify-center gap-x-4 gap-y-2 mb-6 text-sm text-slate-600 px-4">
            {profile.address && (
              <div className="flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-slate-400" />
                <span>{profile.address}</span>
              </div>
            )}
            
            {profile.address && profile.businessHours && (
              <span className="hidden sm:inline text-slate-300">•</span>
            )}

            {profile.businessHours && (
              <button
                onClick={() => setIsTimingsOpen(true)}
                className="flex items-center gap-1.5 hover:bg-slate-50 px-2 py-1 -my-1 rounded-full transition-colors cursor-pointer group"
              >
                <Clock className="w-3.5 h-3.5 text-slate-400 group-hover:text-indigo-600 transition-colors" />
                <span className="group-hover:text-slate-900 transition-colors">Timings:</span>
                {openStatus && (
                  <span className={`font-semibold ${openStatus.isOpen ? 'text-emerald-600' : 'text-rose-500'}`}>
                    {openStatus.text}
                  </span>
                )}
              </button>
            )}
          </div>

        {/* View Services Button */}
        {CATALOGUE_DATA && (
          <div className="mb-6 px-2">
            <Link
              to="/services"
              className="flex items-center justify-center gap-3 w-full p-4 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-2xl shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-[1.02]"
            >
              <Package className="w-5 h-5" />
              View Services
            </Link>
          </div>
        )}

        {/* Links Section */}
        <div className="space-y-4 px-2 mb-8">
          {links
            .filter(l => l.active)
            .sort((a, b) => a.order - b.order)
            .map(link => (
              <LinkCard key={link.id} link={link} theme={theme} />
            ))}
        </div>

        {/* Primary Actions Grid */}
        <div className={`grid ${profile.email ? 'grid-cols-2 sm:grid-cols-3' : 'grid-cols-2'} gap-3 px-2 mb-8`}>
            {profile.phone && (
              <a
                href={`tel:${profile.phone}`}
                className={`flex items-center justify-center gap-2 px-4 py-3 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 hover:border-indigo-200 hover:text-indigo-600 transition-all font-semibold text-slate-700 shadow-sm ${!profile.email ? 'col-span-1' : ''}`}
              >
                <Phone className="w-4 h-4" />
                <span>Call</span>
              </a>
            )}
            
            {profile.googleMaps && (
              <a
                href={profile.googleMaps}
                target="_blank"
                rel="noopener noreferrer"
                className={`flex items-center justify-center gap-2 px-4 py-3 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 hover:border-indigo-200 hover:text-indigo-600 transition-all font-semibold text-slate-700 shadow-sm ${!profile.email ? 'col-span-1' : ''}`}
              >
                <MapPin className="w-4 h-4" />
                <span>Directions</span>
              </a>
            )}

            {profile.email && (
               <a
                href={`mailto:${profile.email}`}
                className={`flex items-center justify-center gap-2 px-4 py-3 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 hover:border-indigo-200 hover:text-indigo-600 transition-all font-semibold text-slate-700 shadow-sm ${profile.phone && profile.googleMaps ? 'col-span-2 sm:col-span-1' : ''}`}
              >
                <Mail className="w-4 h-4" />
                <span>Email</span>
              </a>
            )}
        </div>

        {/* Secondary Actions - Embed Triggers */}
        {(SURVEY_DATA || LEAD_FORM_DATA) && (
          <div className="mt-8 px-2 flex justify-center gap-6 text-sm">
            {SURVEY_DATA && (
              <button
                data-saveaday-survey={(() => {
                  const tempDiv = document.createElement('div');
                  tempDiv.innerHTML = SURVEY_DATA.embedCode;
                  const script = tempDiv.querySelector('script');
                  return script?.getAttribute('data-survey-token') || SURVEY_DATA.id;
                })()}
                className="text-slate-500 hover:text-slate-700 underline underline-offset-4 transition-colors cursor-pointer bg-transparent border-none font-inherit"
              >
                {SURVEY_DATA.name}
              </button>
            )}
            {LEAD_FORM_DATA && (
              <button
                data-saveaday-leadform={(() => {
                  const tempDiv = document.createElement('div');
                  tempDiv.innerHTML = LEAD_FORM_DATA.embedCode;
                  const script = tempDiv.querySelector('script');
                  return script?.getAttribute('data-leadform-token') || LEAD_FORM_DATA.id;
                })()}
                className="text-slate-500 hover:text-slate-700 underline underline-offset-4 transition-colors cursor-pointer bg-transparent border-none font-inherit"
              >
                {LEAD_FORM_DATA.name}
              </button>
            )}
          </div>
        )}

        {/* Footer */}
        <footer className="mt-20 text-center pb-8">
          <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold opacity-60">
            © 2026 {profile.name}
          </p>
        </footer>
      </div>

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

      {/* Timings Modal */}
      {profile.businessHours && (
          <TimingsModal 
              businessHours={profile.businessHours}
              isOpen={isTimingsOpen}
              onClose={() => setIsTimingsOpen(false)}
              theme={theme}
          />
      )}
    </div>
    </ThemeProvider>
  );
};

const App: React.FC = () => {
  return (
    <Router>
      <GoogleAnalytics trackingId={PAGE_DATA.gaTrackingId} />
      <Routes>
        <Route path="/services" element={<CataloguePage catalogue={CATALOGUE_DATA} theme={PAGE_DATA.theme} businessName={PAGE_DATA.profile.name} />} />
        <Route path="/" element={<ProfilePage />} />
      </Routes>
    </Router>
  );
};


export default App;

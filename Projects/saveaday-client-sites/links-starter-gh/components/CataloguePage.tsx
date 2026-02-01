
import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Catalogue, ThemeConfig } from '../types';
import { ChevronDown, ChevronUp, ArrowLeft, Info } from 'lucide-react';
import { ThemeProvider } from './ThemeProvider';

interface CataloguePageProps {
  catalogue: Catalogue;
  theme: ThemeConfig;
  businessName: string;
}

export const CataloguePage: React.FC<CataloguePageProps> = ({ catalogue, theme, businessName }) => {
  const navigate = useNavigate();
  const { slug } = useParams<{ slug: string }>();
  const [expandedCategories, setExpandedCategories] = useState<Set<number>>(new Set([0]));

  useEffect(() => {
    // Set dynamic SEO
    document.title = `Services | ${businessName}`;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) {
      metaDesc.setAttribute('content', `Explore our range of beauty services at ${businessName}`);
    }
  }, [businessName]);

  const toggleCategory = (index: number) => {
    const newExpanded = new Set(expandedCategories);
    if (newExpanded.has(index)) {
      newExpanded.delete(index);
    } else {
      newExpanded.add(index);
    }
    setExpandedCategories(newExpanded);
  };

  const formatPrice = (price: number) => {
    return `AED ${price.toFixed(0)}`;
  };

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
              <span className="font-semibold">Back to Profile</span>
            </button>
            <h1 className="text-3xl font-extrabold text-slate-900 mb-2 tracking-tight">
              Our Services
            </h1>
            <p className="text-slate-600 font-medium">
              Browse our complete catalogue of services
            </p>
          </div>

          {/* Categories */}
          <div className="space-y-4">
            {catalogue.categories.map((category, categoryIndex) => (
              <div 
                key={categoryIndex}
                className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-shadow"
              >
                {/* Category Header */}
                <button
                  onClick={() => toggleCategory(categoryIndex)}
                  className="w-full flex items-center justify-between p-5 hover:bg-slate-50 transition-colors text-left"
                >
                  <h2 className="text-lg sm:text-xl font-bold text-slate-900 flex-1 pr-4">
                    {category.title}
                  </h2>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <span className="text-xs sm:text-sm text-slate-500 font-medium whitespace-nowrap">
                      {category.items.length} {category.items.length === 1 ? 'service' : 'services'}
                    </span>
                    {expandedCategories.has(categoryIndex) ? (
                      <ChevronUp className="w-5 h-5 text-slate-400" />
                    ) : (
                      <ChevronDown className="w-5 h-5 text-slate-400" />
                    )}
                  </div>
                </button>

                {/* Category Items */}
                {expandedCategories.has(categoryIndex) && (
                  <div className="border-t border-slate-200">
                    {category.items.map((item, itemIndex) => (
                      <div 
                        key={itemIndex}
                        className="p-5 border-b border-slate-100 last:border-b-0 hover:bg-slate-50 transition-colors"
                      >
                        <div className="flex justify-between items-start mb-2">
                          <h3 className="font-semibold text-slate-900 text-lg">
                            {item.title}
                          </h3>
                          {!item.variants && (
                            <span className="font-bold text-indigo-600 text-lg whitespace-nowrap ml-4">
                              {formatPrice(item.price)}
                            </span>
                          )}
                        </div>
                        <p className="text-slate-600 text-sm mb-3">
                          {item.description}
                        </p>
                        
                        {/* Variants */}
                        {item.variants && item.variants.length > 0 && (
                          <div className="mt-3 space-y-2">
                            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                              Options:
                            </p>
                            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                              {item.variants.map((variant, variantIndex) => (
                                <div 
                                  key={variantIndex}
                                  className="flex flex-col items-center justify-center p-3 bg-slate-50 border border-slate-200 rounded-lg"
                                >
                                  <span className="text-xs font-medium text-slate-600 mb-1">
                                    {variant.label}
                                  </span>
                                  <span className="font-bold text-indigo-600 text-sm">
                                    {formatPrice(variant.price)}
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Footer */}
          <footer className="mt-12 text-center pb-8">
            <p className="text-xs text-slate-400 uppercase tracking-widest font-bold opacity-60">
              © 2026 {businessName}
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
      </div>
    </ThemeProvider>
  );
};


import React from 'react';
import { LinkItem, ThemeConfig } from '../types';
import { IconRenderer } from './IconRenderer';

interface LinkCardProps {
  link: LinkItem;
  theme: ThemeConfig;
}

export const LinkCard: React.FC<LinkCardProps> = ({ link, theme }) => {
  if (!link.active) return null;

  const getButtonStyle = () => {
    switch (theme.buttonStyle) {
      case 'pill': return 'rounded-full';
      case 'rounded': return 'rounded-2xl';
      case 'square': return 'rounded-none';
      default: return 'rounded-2xl';
    }
  };

  // Handle formatting for different link types
  const getHref = () => {
    if (link.type === 'whatsapp' && !link.url.startsWith('http')) {
      // Remove any non-numeric characters for the WhatsApp link
      const cleanPhone = link.url.replace(/\D/g, '');
      return `https://wa.me/${cleanPhone}`;
    }
    return link.url;
  };

  const getIconName = () => {
    const type = link.type.toLowerCase();
    if (type === 'whatsapp') return 'message-circle';
    if (type === 'social') return link.icon?.toLowerCase() || 'link';
    return link.type.toLowerCase();
  };

  return (
    <a
      href={getHref()}
      target="_blank"
      rel="noopener noreferrer"
      className={`
        flex items-center justify-between w-full p-4 mb-4 
        bg-white border border-slate-200 
        hover:scale-[1.01] hover:shadow-md hover:border-indigo-400
        transition-all duration-200 group
        ${getButtonStyle()}
      `}
    >
      <div className="flex items-center gap-3">
        <div className="p-2 bg-indigo-50 rounded-lg group-hover:bg-indigo-100 transition-colors">
          <IconRenderer 
            icon={getIconName()} 
            className="w-5 h-5 text-indigo-600" 
          />
        </div>
        <span className="font-semibold text-slate-800">{link.label}</span>
      </div>
      <div className="opacity-0 group-hover:opacity-100 transition-opacity">
        <IconRenderer icon="external-link" className="w-4 h-4 text-slate-400" />
      </div>
    </a>
  );
};

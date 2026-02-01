

import React from 'react';
import { 
  Instagram, 
  Facebook, 
  Youtube, 
  Linkedin, 
  Twitter, 
  Globe, 
  MessageCircle, 
  Mail, 
  Phone,
  Link as LinkIcon,
  ExternalLink
} from 'lucide-react';

interface IconRendererProps {
  icon?: string;
  iconName?: string;
  className?: string;
}

export const IconRenderer: React.FC<IconRendererProps> = ({ icon, iconName, className }) => {
  const name = (icon || iconName || '').toLowerCase();
  
  switch (name) {
    case 'instagram': return <Instagram className={className} />;
    case 'facebook': return <Facebook className={className} />;
    case 'youtube': return <Youtube className={className} />;
    case 'linkedin': return <Linkedin className={className} />;
    case 'twitter': return <Twitter className={className} />;
    case 'globe': return <Globe className={className} />;
    case 'whatsapp':
    case 'message-circle': return <MessageCircle className={className} />;
    case 'email': return <Mail className={className} />;
    case 'phone': return <Phone className={className} />;
    case 'external-link': return <ExternalLink className={className} />;
    case 'link':
    default: return <LinkIcon className={className} />;
  }
};

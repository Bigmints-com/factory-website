
export interface BusinessHour {
  day: string;
  isOpen: boolean;
  start: string;
  end: string;
}

export interface Profile {
  name: string;
  bio: string;
  logo: string;
  address?: string;
  email?: string;
  phone?: string;
  googleMaps?: string;
  businessHours?: BusinessHour[];
}

export interface LinkItem {
  id: string;
  type: string;
  label: string;
  url: string;
  order: number;
  active: boolean;
  icon?: string;
}

export interface ThemeConfig {
  background: string;
  buttonStyle: 'pill' | 'rounded' | 'square';
  font: string;
}

export interface CatalogueVariant {
  label: string;
  price: number;
}

export interface CatalogueItem {
  title: string;
  description: string;
  price: number;
  variants?: CatalogueVariant[];
}

export interface CatalogueCategory {
  title: string;
  items: CatalogueItem[];
}

export interface Catalogue {
  id: string;
  ownerId: string;
  businessName: string;
  slug: string;
  status: string;
  theme: {
    primaryColor: string;
    font: string;
  };
  createdAt: {
    _seconds: number;
    _nanoseconds: number;
  };
  categories: CatalogueCategory[];
  updatedAt: {
    _seconds: number;
    _nanoseconds: number;
  };
}

export interface LinkPage {
  id: string;
  ownerId: string;
  slug: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  views: number;
  clicks: number;
  profile: Profile;
  links: LinkItem[];
  theme: ThemeConfig;
  catalogueId?: string;
  gaTrackingId?: string;
}

export interface ApiResponse {
  success: boolean;
  data: LinkPage[];
  count: number;
  hasMore: boolean;
}

export interface SurveyQuestion {
  id: string;
  text: string;
  type: 'rating' | 'yes_no' | 'text' | 'multiple_choice';
  required: boolean;
  options?: string[];
}

export interface Survey {
  id: string;
  name: string;
  description: string;
  questions: SurveyQuestion[];
  embedCode: string;
}

export interface LeadFormField {
  id: string;
  label: string;
  type: 'text' | 'email' | 'phone' | 'textarea' | 'select';
  required: boolean;
  options?: string[];
}

export interface LeadForm {
  id: string;
  name: string;
  description: string;
  fields: LeadFormField[];
  embedCode: string;
}

export interface WebhookPayloadData {
  linkPage: LinkPage;
  catalogue?: Catalogue;
  survey?: Survey;
  leadForm?: LeadForm;
}

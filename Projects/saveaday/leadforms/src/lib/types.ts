export type DuplicateStrategy = 'reject' | 'update' | 'allow';

export interface LeadFormStyling {
  brandColor: string;
  buttonText: string;
  successMessage: string;
}

export interface LeadFormPlaceholders {
  name: string;
  email: string;
}

export type LeadFormStatus = 'active' | 'inactive';

export interface LeadForm {
  id: string;
  ownerId: string;
  name: string;
  description: string;
  sourceOptions: string[];
  duplicateStrategy: DuplicateStrategy;
  status: LeadFormStatus;
  styling: LeadFormStyling;
  redirectUrl?: string;
  placeholders: LeadFormPlaceholders;
  embedToken: string;
  createdAt: string;
  updatedAt: string;
  submissionCount: number;
  lastSubmissionAt?: string;
}

export interface Submission {
  id: string;
  leadFormId: string;
  ownerId: string;
  name: string;
  email: string;
  source: string | null;
  emailHash: string;
  createdAt: string;
  updatedAt: string;
  isDuplicate: boolean;
  duplicateOf?: string;
  metadata: {
    ip?: string;
    userAgent?: string;
    referrer?: string;
  };
}

export type WebhookEventType =
  | 'submission.created'
  | 'submission.updated'
  | 'submission.deleted';

export interface Webhook {
  id: string;
  ownerId: string;
  leadFormId?: string;
  url: string;
  secret: string;
  events: WebhookEventType[];
  headers: Record<string, string>;
  active: boolean;
  retryLimit: number;
  createdAt: string;
  updatedAt: string;
}

export interface ApiToken {
  id: string;
  ownerId: string;
  token: string;
  createdAt: string;
  lastUsedAt?: string;
  active: boolean;
}

export interface DashboardStats {
  totalSubmissions: number;
  totalLeadForms: number;
  recentSubmissions: Submission[];
}

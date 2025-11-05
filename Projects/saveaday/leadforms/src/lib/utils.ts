import crypto from 'crypto';

export const hashEmail = (email: string): string =>
  crypto.createHash('sha256').update(email.trim().toLowerCase()).digest('hex');

export const generateApiToken = (): string =>
  `wl_${crypto.randomBytes(16).toString('hex')}`;

export const generateWebhookSecret = (): string =>
  crypto.randomBytes(32).toString('hex');

export const isoNow = (): string => new Date().toISOString();

export const randomEmbedToken = (): string =>
  crypto.randomBytes(12).toString('hex');

export const sleep = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));

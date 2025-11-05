import { adminDb } from '@/lib/firebaseAdmin';
import type { Webhook, WebhookEventType } from '@/lib/types';
import { generateWebhookSecret, isoNow } from '@/lib/utils';
import { DocumentData } from 'firebase-admin/firestore';

const collection = adminDb.collection('webhooks');

const mapWebhook = (id: string, data: DocumentData): Webhook => ({
  id,
  ownerId: data.ownerId,
  leadFormId: data.leadFormId ?? undefined,
  url: data.url,
  secret: data.secret,
  events: data.events,
  headers: data.headers ?? {},
  active: data.active ?? true,
  retryLimit: data.retryLimit ?? 3,
  createdAt: data.createdAt,
  updatedAt: data.updatedAt,
});

export const listWebhooks = async ({
  ownerId,
  leadFormId,
}: {
  ownerId: string;
  leadFormId?: string;
}): Promise<Webhook[]> => {
  let query = collection.where('ownerId', '==', ownerId);
  if (leadFormId) {
    query = query.where('leadFormId', '==', leadFormId);
  }
  const snapshot = await query.orderBy('createdAt', 'desc').get();
  return snapshot.docs.map((doc) => mapWebhook(doc.id, doc.data()));
};

export const createWebhook = async ({
  ownerId,
  leadFormId,
  url,
  events,
  headers,
  retryLimit,
}: {
  ownerId: string;
  leadFormId?: string;
  url: string;
  events: WebhookEventType[];
  headers?: Record<string, string>;
  retryLimit?: number;
}): Promise<Webhook> => {
  const now = isoNow();
  const docRef = collection.doc();
  const payload = {
    ownerId,
    leadFormId: leadFormId ?? null,
    url,
    events,
    headers: headers ?? {},
    retryLimit: retryLimit ?? 3,
    active: true,
    secret: generateWebhookSecret(),
    createdAt: now,
    updatedAt: now,
  };
  await docRef.set(payload);
  return mapWebhook(docRef.id, payload);
};

export const updateWebhook = async (
  ownerId: string,
  id: string,
  updates: Partial<{
    url: string;
    events: WebhookEventType[];
    headers: Record<string, string>;
    retryLimit: number;
    active: boolean;
  }>,
): Promise<Webhook | null> => {
  const existing = await getWebhook(ownerId, id);
  if (!existing) return null;
  const payload: Record<string, unknown> = {
    updatedAt: isoNow(),
  };
  if (updates.url !== undefined) payload.url = updates.url;
  if (updates.events !== undefined) payload.events = updates.events;
  if (updates.headers !== undefined) payload.headers = updates.headers;
  if (updates.retryLimit !== undefined) payload.retryLimit = updates.retryLimit;
  if (updates.active !== undefined) payload.active = updates.active;
  await collection.doc(id).update(payload);
  return (await getWebhook(ownerId, id))!;
};

export const deleteWebhook = async (ownerId: string, id: string) => {
  const existing = await getWebhook(ownerId, id);
  if (!existing) return;
  await collection.doc(id).delete();
};

export const getWebhook = async (
  ownerId: string,
  id: string,
): Promise<Webhook | null> => {
  const doc = await collection.doc(id).get();
  if (!doc.exists) return null;
  const data = doc.data() as DocumentData;
  if (data.ownerId !== ownerId) return null;
  return mapWebhook(doc.id, data);
};

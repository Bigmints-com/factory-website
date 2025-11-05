import { adminDb } from '@/lib/firebaseAdmin';
import type {
  DuplicateStrategy,
  LeadForm,
  LeadFormPlaceholders,
  LeadFormStyling,
  LeadFormStatus,
} from '@/lib/types';
import { isoNow, randomEmbedToken } from '@/lib/utils';
import { DocumentData, FieldValue } from 'firebase-admin/firestore';

const collection = adminDb.collection('leadforms');

const mapLeadForm = (docId: string, data: DocumentData): LeadForm => ({
  id: docId,
  ownerId: data.ownerId,
  name: data.name,
  description: data.description ?? '',
  sourceOptions: data.sourceOptions ?? [],
  duplicateStrategy: data.duplicateStrategy ?? 'reject',
  status: data.status ?? 'inactive',
  styling: data.styling,
  redirectUrl: data.redirectUrl ?? '',
  placeholders: data.placeholders,
  embedToken: data.embedToken,
  createdAt: data.createdAt,
  updatedAt: data.updatedAt,
  submissionCount: data.submissionCount ?? 0,
  lastSubmissionAt: data.lastSubmissionAt,
});

const defaultStyling: LeadFormStyling = {
  brandColor: '#2563eb',
  buttonText: 'Submit lead',
  successMessage: 'Thanks for sharing your details!',
};

const defaultPlaceholders: LeadFormPlaceholders = {
  name: 'Full name',
  email: 'you@example.com',
};

export const listLeadForms = async (ownerId: string): Promise<LeadForm[]> => {
  const snapshot = await collection
    .where('ownerId', '==', ownerId)
    .orderBy('createdAt', 'desc')
    .get();
  return snapshot.docs.map((doc) => mapLeadForm(doc.id, doc.data()));
};

export const getLeadFormById = async (
  ownerId: string,
  id: string,
): Promise<LeadForm | null> => {
  const doc = await collection.doc(id).get();
  if (!doc.exists) return null;
  const data = doc.data() as DocumentData;
  if (data.ownerId !== ownerId) return null;
  return mapLeadForm(doc.id, data);
};

export const getLeadFormByEmbedToken = async (
  token: string,
): Promise<LeadForm | null> => {
  try {
    console.log('[LeadFormRepo] Searching for leadForm with embedToken:', token);
  const snapshot = await collection
    .where('embedToken', '==', token)
    .limit(1)
    .get();
    console.log('[LeadFormRepo] Query result - empty:', snapshot.empty, 'docs:', snapshot.docs.length);
    if (snapshot.empty) {
      // Debug: list all leadforms to see what tokens exist
      const allLeadForms = await collection.limit(10).get();
      console.log('[LeadFormRepo] Found', allLeadForms.docs.length, 'leadforms. Embed tokens:', 
        allLeadForms.docs.map(doc => ({ id: doc.id, name: doc.data().name, embedToken: doc.data().embedToken }))
      );
      return null;
    }
  const doc = snapshot.docs[0];
    const leadForm = mapLeadForm(doc.id, doc.data());
    console.log('[LeadFormRepo] Found leadForm:', { id: leadForm.id, name: leadForm.name, status: leadForm.status, embedToken: leadForm.embedToken });
    return leadForm;
  } catch (error) {
    console.error('[LeadFormRepo] Error querying leadForm by embedToken:', error);
    throw error;
  }
};

export const createLeadForm = async ({
  ownerId,
  name,
  description,
  sourceOptions,
  duplicateStrategy,
  status,
  styling,
  redirectUrl,
  placeholders,
}: {
  ownerId: string;
  name: string;
  description?: string;
  sourceOptions: string[];
  duplicateStrategy: DuplicateStrategy;
  status: LeadFormStatus;
  styling?: Partial<LeadFormStyling>;
  redirectUrl?: string;
  placeholders?: Partial<LeadFormPlaceholders>;
}): Promise<LeadForm> => {
  const now = isoNow();
  const docRef = collection.doc();
  const payload = {
    ownerId,
    name,
    description: description ?? '',
    sourceOptions,
    duplicateStrategy,
    status,
    styling: { ...defaultStyling, ...styling },
    redirectUrl: redirectUrl ?? '',
    placeholders: { ...defaultPlaceholders, ...placeholders },
    embedToken: randomEmbedToken(),
    createdAt: now,
    updatedAt: now,
    submissionCount: 0,
    lastSubmissionAt: null,
  };
  await docRef.set(payload);
  return mapLeadForm(docRef.id, payload);
};

export const updateLeadForm = async (
  ownerId: string,
  id: string,
  updates: Partial<{
    name: string;
    description: string;
    sourceOptions: string[];
    duplicateStrategy: DuplicateStrategy;
    status: LeadFormStatus;
    styling: Partial<LeadFormStyling>;
    redirectUrl: string;
    placeholders: Partial<LeadFormPlaceholders>;
  }>,
): Promise<LeadForm | null> => {
  const existing = await getLeadFormById(ownerId, id);
  if (!existing) return null;
  const now = isoNow();
  const payload: Record<string, unknown> = {
    updatedAt: now,
  };
  if (updates.name !== undefined) payload.name = updates.name;
  if (updates.description !== undefined)
    payload.description = updates.description;
  if (updates.sourceOptions !== undefined)
    payload.sourceOptions = updates.sourceOptions;
  if (updates.duplicateStrategy !== undefined)
    payload.duplicateStrategy = updates.duplicateStrategy;
  if (updates.status !== undefined) payload.status = updates.status;
  if (updates.redirectUrl !== undefined)
    payload.redirectUrl = updates.redirectUrl;
  if (updates.styling !== undefined)
    payload.styling = { ...existing.styling, ...updates.styling };
  if (updates.placeholders !== undefined)
    payload.placeholders = { ...existing.placeholders, ...updates.placeholders };

  await collection.doc(id).update(payload);
  return (await getLeadFormById(ownerId, id))!;
};

export const deleteLeadForm = async (ownerId: string, id: string) => {
  const leadForm = await getLeadFormById(ownerId, id);
  if (!leadForm) return;
  const submissionsRef = collection.doc(id).collection('submissions');
  const submissions = await submissionsRef.get();

  const batch = adminDb.batch();
  submissions.forEach((doc) => batch.delete(doc.ref));
  batch.delete(collection.doc(id));
  await batch.commit();
};

export const incrementSubmissionCount = async (
  leadFormId: string,
  delta: number,
  lastSubmissionAt?: string,
) => {
  const payload: Record<string, unknown> = {
    submissionCount: FieldValue.increment(delta),
  };
  if (lastSubmissionAt) {
    payload.lastSubmissionAt = lastSubmissionAt;
  }
  await collection.doc(leadFormId).update(payload);
};

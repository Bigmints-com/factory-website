import { adminDb } from '@/lib/firebaseAdmin';
import type { Submission, LeadForm } from '@/lib/types';
import { hashEmail, isoNow } from '@/lib/utils';
import { incrementSubmissionCount } from './leadFormRepository';
import { DocumentData, FieldValue } from 'firebase-admin/firestore';

const collection = (leadFormId: string) =>
  adminDb.collection('leadforms').doc(leadFormId).collection('submissions');

export const mapSubmission = (docId: string, data: DocumentData): Submission => ({
  id: docId,
  leadFormId: data.leadFormId,
  ownerId: data.ownerId,
  name: data.name,
  email: data.email,
  source: data.source ?? null,
  emailHash: data.emailHash,
  createdAt: data.createdAt,
  updatedAt: data.updatedAt ?? data.createdAt,
  isDuplicate: data.isDuplicate ?? false,
  duplicateOf: data.duplicateOf ?? undefined,
  metadata: data.metadata ?? {},
});

export const listSubmissions = async ({
  ownerId,
  leadFormId,
  limit = 50,
}: {
  ownerId: string;
  leadFormId: string;
  limit?: number;
}): Promise<Submission[]> => {
  const snapshot = await collection(leadFormId)
    .where('ownerId', '==', ownerId)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => mapSubmission(doc.id, doc.data()));
};

export const getSubmission = async ({
  ownerId,
  leadFormId,
  submissionId,
}: {
  ownerId: string;
  leadFormId: string;
  submissionId: string;
}): Promise<Submission | null> => {
  const doc = await collection(leadFormId).doc(submissionId).get();
  if (!doc.exists) return null;
  const data = doc.data() as DocumentData;
  if (data.ownerId !== ownerId) return null;
  return mapSubmission(doc.id, data);
};

export const deleteSubmission = async ({
  ownerId,
  leadFormId,
  submissionId,
}: {
  ownerId: string;
  leadFormId: string;
  submissionId: string;
}) => {
  const existing = await getSubmission({ ownerId, leadFormId, submissionId });
  if (!existing) return;
  await collection(leadFormId).doc(submissionId).delete();
  await incrementSubmissionCount(leadFormId, -1);
};

export const listRecentSubmissions = async ({
  ownerId,
  limit,
}: {
  ownerId: string;
  limit: number;
}) => {
  const snapshot = await adminDb
    .collectionGroup('submissions')
    .where('ownerId', '==', ownerId)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => mapSubmission(doc.id, doc.data()));
};

interface CreateSubmissionInput {
  leadForm: LeadForm;
  name: string;
  email: string;
  source: string | null;
  metadata: Submission['metadata'];
}

interface CreateSubmissionResult {
  status: 'created' | 'updated' | 'duplicate-rejected';
  submission: Submission;
  duplicateOf?: Submission;
}

export const createSubmission = async ({
  leadForm,
  name,
  email,
  source,
  metadata,
}: CreateSubmissionInput): Promise<CreateSubmissionResult> => {
  const emailHash = hashEmail(email);
  const submissionsRef = collection(leadForm.id);
  const existingSnapshot = await submissionsRef
    .where('emailHash', '==', emailHash)
    .limit(1)
    .get();

  const now = isoNow();
  const basePayload = {
    leadFormId: leadForm.id,
    ownerId: leadForm.ownerId,
    name,
    email,
    source,
    emailHash,
    metadata,
  };

  if (!existingSnapshot.empty) {
    const existingDoc = existingSnapshot.docs[0];
    const existingData = mapSubmission(existingDoc.id, existingDoc.data());

    if (leadForm.duplicateStrategy === 'reject') {
      return {
        status: 'duplicate-rejected',
        submission: existingData,
        duplicateOf: existingData,
      };
    }

    if (leadForm.duplicateStrategy === 'update') {
      await submissionsRef.doc(existingDoc.id).update({
        ...basePayload,
        createdAt: existingData.createdAt,
        updatedAt: now,
        isDuplicate: false,
        duplicateOf: null,
      });
      return {
        status: 'updated',
        submission: {
          ...existingData,
          name,
          email,
          source,
          metadata,
          updatedAt: now,
        },
        duplicateOf: existingData,
      };
    }

    // Allow duplicates
    const docRef = submissionsRef.doc();
    const payload = {
      ...basePayload,
      createdAt: now,
      updatedAt: now,
      isDuplicate: true,
      duplicateOf: existingData.id,
    };
    await docRef.set(payload);
    await incrementSubmissionCount(leadForm.id, 1, now);
    return {
      status: 'created',
      submission: mapSubmission(docRef.id, payload),
      duplicateOf: existingData,
    };
  }

  const docRef = submissionsRef.doc();
  const payload = {
    ...basePayload,
    createdAt: now,
    updatedAt: now,
    isDuplicate: false,
    duplicateOf: null,
  };
  await docRef.set(payload);
  await incrementSubmissionCount(leadForm.id, 1, now);
  return {
    status: 'created',
    submission: mapSubmission(docRef.id, payload),
  };
};

export const updateSubmission = async ({
  ownerId,
  leadFormId,
  submissionId,
  name,
  email,
  source,
}: {
  ownerId: string;
  leadFormId: string;
  submissionId: string;
  name: string;
  email: string;
  source: string | null;
}) => {
  // Verify ownership
  const existing = await getSubmission({ ownerId, leadFormId, submissionId });
  if (!existing) {
    throw new Error('Submission not found');
  }

  const emailHash = hashEmail(email);
  await collection(leadFormId).doc(submissionId).update({
    name,
    email,
    source,
    emailHash,
    updatedAt: isoNow(),
  });
};

export const updateSubmissionMetadata = async ({
  leadFormId,
  submissionId,
  metadata,
}: {
  leadFormId: string;
  submissionId: string;
  metadata: Submission['metadata'];
}) => {
  await collection(leadFormId).doc(submissionId).update({
    metadata,
    updatedAt: isoNow(),
  });
};

export const recordPublicSubmissionAttempt = async (
  leadFormId: string,
  success: boolean,
) => {
  await adminDb
    .collection('leadFormMetrics')
    .doc(leadFormId)
    .set(
      success
        ? {
            successCount: FieldValue.increment(1),
            lastSuccessAt: isoNow(),
          }
        : {
            failureCount: FieldValue.increment(1),
            lastFailureAt: isoNow(),
          },
      { merge: true },
    );
};

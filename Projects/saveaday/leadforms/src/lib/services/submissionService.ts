import {
  createSubmission,
  deleteSubmission as deleteSubmissionRepo,
  getSubmission,
  listSubmissions,
} from '@/lib/repositories/submissionRepository';
import { getLeadFormById } from '@/lib/repositories/leadFormRepository';
import { deliverWebhookEvent } from '@/lib/services/webhookService';
import type { Submission } from '@/lib/types';

export const listLeadFormSubmissions = listSubmissions;

export const submitToLeadForm = async ({
  leadFormId,
  ownerId,
  name,
  email,
  source,
  metadata,
}: {
  leadFormId: string;
  ownerId: string;
  name: string;
  email: string;
  source: string | null;
  metadata: Submission['metadata'];
}) => {
  const leadForm = await getLeadFormById(ownerId, leadFormId);
  if (!leadForm) {
    throw new Error('Lead form not found');
  }

  const result = await createSubmission({
    leadForm,
    name,
    email,
    source,
    metadata,
  });

  if (result.status === 'created') {
    await deliverWebhookEvent({
      leadForm,
      submission: result.submission,
      event: 'submission.created',
    });
  } else if (result.status === 'updated') {
    await deliverWebhookEvent({
      leadForm,
      submission: result.submission,
      event: 'submission.updated',
    });
  }

  return result;
};

export const deleteSubmission = async ({
  leadFormId,
  ownerId,
  submissionId,
}: {
  leadFormId: string;
  ownerId: string;
  submissionId: string;
}) => {
  const leadForm = await getLeadFormById(ownerId, leadFormId);
  if (!leadForm) {
    throw new Error('Lead form not found');
  }
  const submission = await getSubmission({ leadFormId, ownerId, submissionId });
  if (!submission) {
    throw new Error('Submission not found');
  }
  await deleteSubmissionRepo({ leadFormId, ownerId, submissionId });
  await deliverWebhookEvent({
    leadForm,
    submission,
    event: 'submission.deleted',
  });
};

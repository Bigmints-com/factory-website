import { listWebhooks } from '@/lib/repositories/webhookRepository';
import type { Submission, LeadForm, WebhookEventType } from '@/lib/types';
import { isoNow, sleep } from '@/lib/utils';
import crypto from 'crypto';
import { adminDb } from '@/lib/firebaseAdmin';

interface DeliverWebhookParams {
  leadForm: LeadForm;
  submission: Submission;
  event: WebhookEventType;
}

export const deliverWebhookEvent = async ({
  leadForm,
  submission,
  event,
}: DeliverWebhookParams) => {
  const candidateWebhooks = await listWebhooks({
    ownerId: leadForm.ownerId,
  });

  const targets = candidateWebhooks.filter((webhook) => {
    if (!webhook.active) return false;
    if (!webhook.events.includes(event)) return false;
    if (webhook.leadFormId && webhook.leadFormId !== leadForm.id) return false;
    return true;
  });

  if (!targets.length) return;

  const payload = {
    event,
    timestamp: isoNow(),
    submissionId: submission.id,
    leadFormId: leadForm.id,
    data: {
      name: submission.name,
      email: submission.email,
      source: submission.source,
    },
    metadata: {
      submittedCount: submission.isDuplicate ? 2 : 1,
      isDuplicate: submission.isDuplicate,
    },
  };

  await Promise.all(
    targets.map(async (webhook) => {
      const signature = crypto
        .createHmac('sha256', webhook.secret)
        .update(JSON.stringify(payload))
        .digest('hex');

      let attempt = 0;
      let success = false;
      let error: string | null = null;
      const start = Date.now();

      while (!success && attempt < webhook.retryLimit) {
        attempt += 1;
        try {
          const response = await fetch(webhook.url, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-leadform-signature': signature,
              ...webhook.headers,
            },
            body: JSON.stringify(payload),
          });
          success = response.ok;
          if (!success) {
            error = `Status ${response.status}`;
            await sleep(2 ** attempt * 250);
          }
        } catch (err) {
          error = err instanceof Error ? err.message : 'Unknown error';
          await sleep(2 ** attempt * 250);
        }
      }

      await adminDb.collection('webhookDeliveries').add({
        webhookId: webhook.id,
        leadFormId: leadForm.id,
        submissionId: submission.id,
        event,
        success,
        error,
        attemptCount: attempt,
        durationMs: Date.now() - start,
        createdAt: isoNow(),
      });
    }),
  );
};

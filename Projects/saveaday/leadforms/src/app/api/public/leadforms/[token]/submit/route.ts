import { NextResponse } from 'next/server';
import { z } from 'zod';
import { getLeadFormByEmbedToken } from '@/lib/repositories/leadFormRepository';
import { createSubmission, recordPublicSubmissionAttempt } from '@/lib/repositories/submissionRepository';
import { deliverWebhookEvent } from '@/lib/services/webhookService';

const bodySchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, 'Name is required')
    .max(100, 'Name cannot exceed 100 characters'),
  email: z.string().email('Provide a valid email address'),
  source: z.string().optional().nullable(),
});

export const POST = async (
  request: Request,
  { params }: { params: Promise<{ token: string }> },
) => {
  const { token } = await params;
  const leadForm = await getLeadFormByEmbedToken(token);
  if (!leadForm || leadForm.status !== 'active') {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  const body = await request.json().catch(() => null);
  const parsed = bodySchema.safeParse(body);
  if (!parsed.success) {
    await recordPublicSubmissionAttempt(leadForm.id, false);
    return NextResponse.json(
      { error: 'Validation failed', details: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const forwarded = request.headers.get('x-forwarded-for');
  const ip = forwarded?.split(',')[0]?.trim() ?? undefined;
  const userAgent = request.headers.get('user-agent') ?? undefined;
  const referrer = request.headers.get('referer') ?? undefined;

  const result = await createSubmission({
    leadForm,
    name: parsed.data.name,
    email: parsed.data.email,
    source: parsed.data.source ?? null,
    metadata: {
      ip,
      userAgent,
      referrer,
    },
  });

  if (result.status === 'duplicate-rejected') {
    await recordPublicSubmissionAttempt(leadForm.id, false);
    return NextResponse.json(
      {
        error: 'duplicate',
        message: 'You have already submitted this lead form.',
        previousSubmission: {
          createdAt: result.submission.createdAt,
        },
      },
      { status: 409 },
    );
  }

  await recordPublicSubmissionAttempt(leadForm.id, true);

  await deliverWebhookEvent({
    leadForm,
    submission: result.submission,
    event: result.status === 'updated' ? 'submission.updated' : 'submission.created',
  });

  return NextResponse.json({
    success: true,
    status: result.status,
    successMessage: leadForm.styling.successMessage,
    redirectUrl: leadForm.redirectUrl ?? null,
  });
};

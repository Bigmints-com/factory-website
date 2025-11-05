'use server';

import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/authOptions';
import { updateSubmission } from '@/lib/repositories/submissionRepository';
import { getLeadFormById } from '@/lib/repositories/leadFormRepository';

export async function updateSubmissionAction(
  leadFormId: string,
  submissionId: string,
  data: { name: string; email: string; source: string | null },
) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    return { error: 'Unauthorized' };
  }

  // Verify the leadForm belongs to the user
  const leadForm = await getLeadFormById(session.user.id, leadFormId);
  if (!leadForm) {
    return { error: 'Lead form not found' };
  }

  try {
    await updateSubmission({
      ownerId: session.user.id,
      leadFormId,
      submissionId,
      name: data.name,
      email: data.email,
      source: data.source || null,
    });

    return { success: true };
  } catch (error) {
    console.error('Error updating submission:', error);
    return {
      error: error instanceof Error ? error.message : 'Failed to update submission',
    };
  }
}

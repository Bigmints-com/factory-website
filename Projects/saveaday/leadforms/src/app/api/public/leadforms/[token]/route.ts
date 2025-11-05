import { NextResponse } from 'next/server';
import { getLeadFormByEmbedToken } from '@/lib/repositories/leadFormRepository';

export const GET = async (
  _request: Request,
  { params }: { params: Promise<{ token: string }> },
) => {
  const { token } = await params;
  const leadForm = await getLeadFormByEmbedToken(token);
  if (!leadForm || leadForm.status !== 'active') {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json({
    id: leadForm.id,
    name: leadForm.name,
    description: leadForm.description,
    sourceOptions: leadForm.sourceOptions,
    styling: leadForm.styling,
    placeholders: leadForm.placeholders,
    successMessage: leadForm.styling.successMessage,
    buttonText: leadForm.styling.buttonText,
  });
};

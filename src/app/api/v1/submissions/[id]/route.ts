import { NextResponse } from 'next/server';
import { getUserForApiToken } from '@/lib/apiToken';
import { adminDb } from '@/lib/firebaseAdmin';

// Force dynamic rendering to prevent build-time analysis
export const dynamic = 'force-dynamic';

export const GET = async (
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) => {
  const { id } = await params;
  const authHeader = request.headers.get('authorization');
  const user = await getUserForApiToken(authHeader);
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const url = new URL(request.url);
  const leadFormId = url.searchParams.get('leadFormId');
  if (!leadFormId) {
    return NextResponse.json(
      { error: 'leadFormId query parameter required' },
      { status: 400 },
    );
  }

  const doc = await adminDb
    .collection('leadforms')
    .doc(leadFormId)
    .collection('submissions')
    .doc(id)
    .get();

  if (!doc.exists) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }
  const data = doc.data();
  if (data?.ownerId !== user.id) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json({
    success: true,
    data: {
      id: doc.id,
      ...data,
    },
  });
};

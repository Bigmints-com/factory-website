import { NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebaseAdmin';
import { getUserForApiToken } from '@/lib/apiToken';
import type { Submission } from '@/lib/types';

// Force dynamic rendering to prevent build-time analysis
export const dynamic = 'force-dynamic';

const toSubmission = (doc: FirebaseFirestore.QueryDocumentSnapshot): Submission => {
  const data = doc.data();
  return {
    id: doc.id,
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
  };
};

const toCsv = (submissions: Submission[]) => {
  const header = ['id', 'name', 'email', 'source', 'leadFormId', 'createdAt', 'referrer'];
  const rows = submissions.map((sub) => [
    sub.id,
    sub.name,
    sub.email,
    sub.source ?? '',
    sub.leadFormId,
    sub.createdAt,
    sub.metadata.referrer ?? '',
  ]);
  return [header, ...rows]
    .map((row) =>
      row
        .map((value) => {
          const safe = `${value ?? ''}`.replace(/"/g, '""');
          return `"${safe}"`;
        })
        .join(','),
    )
    .join('\n');
};

export const GET = async (request: Request) => {
  try {
    const url = new URL(request.url);
    const authHeader = request.headers.get('authorization');
    const user = await getUserForApiToken(authHeader);
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    console.log('[API] User ID from token:', user.id);
    console.log('[API] User email:', user.email);

    const leadFormId = url.searchParams.get('leadFormId');
    const startDate = url.searchParams.get('startDate');
    const endDate = url.searchParams.get('endDate');
    const search = url.searchParams.get('search')?.toLowerCase() ?? null;
    const format = url.searchParams.get('format');

    let limit = Number(url.searchParams.get('limit') ?? 50);
    if (Number.isNaN(limit) || limit < 1) limit = 50;
    limit = Math.min(limit, 1000);

    const offset = Number(url.searchParams.get('offset') ?? 0);

    // Debug: Log user ID and leadForm info
    console.log('[API] Querying submissions for user:', user.id);
    console.log('[API] LeadForm ID filter:', leadFormId);
    
    let query: FirebaseFirestore.Query = adminDb
      .collectionGroup('submissions')
      .where('ownerId', '==', user.id)
      .orderBy('createdAt', 'desc');

    if (leadFormId) {
      query = query.where('leadFormId', '==', leadFormId);
    }
    if (startDate) {
      query = query.where('createdAt', '>=', startDate);
    }
    if (endDate) {
      query = query.where('createdAt', '<=', endDate);
    }
    if (offset > 0) {
      query = query.offset(offset);
    }
    query = query.limit(limit);

    const snapshot = await query.get();
    console.log('[API] Query returned', snapshot.docs.length, 'documents');
    let submissions = snapshot.docs.map(toSubmission);
    console.log('[API] Mapped', submissions.length, 'submissions');

    if (search) {
      const lower = search.toLowerCase();
      submissions = submissions.filter(
        (sub) =>
          sub.email.toLowerCase().includes(lower) ||
          sub.name.toLowerCase().includes(lower),
      );
    }

    if (format === 'csv') {
      const csv = toCsv(submissions);
      return new Response(csv, {
        headers: {
          'Content-Type': 'text/csv',
        },
      });
    }

    return NextResponse.json({
      success: true,
      data: submissions,
      count: submissions.length,
      hasMore: submissions.length === limit,
    });
  } catch (error: any) {
    console.error('[API] Error fetching submissions:', error);
    
    // Check if it's a Firestore index error
    if (error?.code === 9 || error?.message?.includes('index')) {
      return NextResponse.json(
        {
          error: 'Database index required',
          message: 'A Firestore composite index is required for this query. Please create an index for submissions collection with fields: ownerId, createdAt (desc), leadFormId.',
          details: error.message,
        },
        { status: 500 }
      );
    }

    return NextResponse.json(
      {
        error: 'Internal server error',
        message: error?.message || 'An unexpected error occurred',
      },
      { status: 500 }
    );
  }
};

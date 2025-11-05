import { adminDb } from '@/lib/firebaseAdmin';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/authOptions';
import { getUserByEmail } from '@/lib/repositories/userRepository';
import { NextResponse } from 'next/server';

// Force dynamic rendering to prevent build-time analysis
export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.email) {
      return NextResponse.json({ 
        error: 'Unauthorized',
        message: 'Please log in and run this from the browser console. See fix-owner-id-script.js for instructions.'
      }, { status: 401 });
    }

    const body = await request.json().catch(() => ({}));
    const leadFormId = body.leadFormId || 'WLZDlKnPHSrdDgL7VeNF';

    // Get the correct user by email
    const user = await getUserByEmail(session.user.email);
    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const correctOwnerId = user.id;

    // Get leadForm
    const leadFormDoc = await adminDb.collection('leadforms').doc(leadFormId).get();
    if (!leadFormDoc.exists) {
      return NextResponse.json({ error: 'LeadForm not found' }, { status: 404 });
    }

    const leadFormData = leadFormDoc.data();
    const oldOwnerId = leadFormData?.ownerId;

    if (oldOwnerId === correctOwnerId) {
      return NextResponse.json({
        message: 'OwnerId is already correct',
        ownerId: correctOwnerId,
      });
    }

    // Update leadForm
    await leadFormDoc.ref.update({ ownerId: correctOwnerId });

    // Update all submissions
    const submissionsSnapshot = await adminDb
      .collection('leadforms')
      .doc(leadFormId)
      .collection('submissions')
      .where('ownerId', '==', oldOwnerId)
      .get();

    const batch = adminDb.batch();
    submissionsSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { ownerId: correctOwnerId });
    });
    await batch.commit();

    return NextResponse.json({
      success: true,
      leadFormId,
      oldOwnerId,
      correctOwnerId,
      submissionsUpdated: submissionsSnapshot.size,
      message: `Updated leadForm and ${submissionsSnapshot.size} submission(s)`,
    });
  } catch (error: any) {
    console.error('[Admin] Error fixing ownerId:', error);
    return NextResponse.json(
      { error: error?.message || 'Failed to fix ownerId' },
      { status: 500 }
    );
  }
}


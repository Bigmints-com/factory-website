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
        message: 'Please log in and run this from the browser console. See fix-leadForm-owner-ids-script.js for instructions.'
      }, { status: 401 });
    }

    // Get the correct user by email
    const user = await getUserByEmail(session.user.email);
    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const correctOwnerId = user.id;
    const sessionUserId = session.user.id;

    // If they're the same, no fix needed
    if (sessionUserId === correctOwnerId) {
      return NextResponse.json({
        message: 'No fix needed - ownerIds already match',
        ownerId: correctOwnerId,
      });
    }

    // Find all leadforms with the old ownerId
    const leadformsSnapshot = await adminDb
      .collection('leadforms')
      .where('ownerId', '==', sessionUserId)
      .get();

    if (leadformsSnapshot.empty) {
      // Try with the correct ownerId to see if they already exist
      const correctLeadFormsSnapshot = await adminDb
        .collection('leadforms')
        .where('ownerId', '==', correctOwnerId)
        .get();

      return NextResponse.json({
        message: `No leadforms found with old ownerId (${sessionUserId}). Found ${correctLeadFormsSnapshot.size} leadForm(s) with correct ownerId (${correctOwnerId}).`,
        oldOwnerId: sessionUserId,
        correctOwnerId,
        leadformsWithOldId: 0,
        leadformsWithCorrectId: correctLeadFormsSnapshot.size,
      });
    }

    // Update all leadforms
    const batch = adminDb.batch();
    leadformsSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { ownerId: correctOwnerId });
    });
    await batch.commit();

    // Also update all submissions in those leadforms
    let totalSubmissionsUpdated = 0;
    for (const leadFormDoc of leadformsSnapshot.docs) {
      const submissionsSnapshot = await adminDb
        .collection('leadforms')
        .doc(leadFormDoc.id)
        .collection('submissions')
        .where('ownerId', '==', sessionUserId)
        .get();

      const submissionBatch = adminDb.batch();
      submissionsSnapshot.docs.forEach(doc => {
        submissionBatch.update(doc.ref, { ownerId: correctOwnerId });
      });
      await submissionBatch.commit();
      totalSubmissionsUpdated += submissionsSnapshot.size;
    }

    return NextResponse.json({
      success: true,
      oldOwnerId: sessionUserId,
      correctOwnerId,
      leadformsUpdated: leadformsSnapshot.size,
      submissionsUpdated: totalSubmissionsUpdated,
      message: `Updated ${leadformsSnapshot.size} leadForm(s) and ${totalSubmissionsUpdated} submission(s)`,
    });
  } catch (error: any) {
    console.error('[Admin] Error fixing leadForm ownerIds:', error);
    return NextResponse.json(
      { error: error?.message || 'Failed to fix leadForm ownerIds' },
      { status: 500 }
    );
  }
}


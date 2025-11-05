import { authOptions } from '@/lib/authOptions';
import { listLeadForms } from '@/lib/repositories/leadFormRepository';
import { adminDb } from '@/lib/firebaseAdmin';
import { getServerSession } from 'next-auth';
import Link from 'next/link';
import { redirect } from 'next/navigation';

export default async function LeadFormsPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    redirect('/login');
  }

  console.log('[LeadFormsPage] Session user ID:', session.user.id);
  console.log('[LeadFormsPage] Session user email:', session.user.email);
  
  const leadForms = await listLeadForms(session.user.id);
  console.log('[LeadFormsPage] Found lead forms:', leadForms.length);
  
  // Debug: If no leadforms found, try to find by email (in case of ownerId mismatch)
  if (leadForms.length === 0 && session.user.email) {
    console.log('[LeadFormsPage] No lead forms found, checking for ownerId mismatch...');
    // Query all lead forms to see what ownerIds exist
    const allLeadFormsSnapshot = await adminDb.collection('leadforms').limit(10).get();
    const allLeadForms = allLeadFormsSnapshot.docs.map(doc => ({
      id: doc.id,
      name: doc.data().name,
      ownerId: doc.data().ownerId,
    }));
    console.log('[LeadFormsPage] Sample leadforms in database:', allLeadForms);
    
    // Try to find user by email
    const userSnapshot = await adminDb.collection('users')
      .where('email', '==', session.user.email)
      .limit(1)
      .get();
    if (!userSnapshot.empty) {
      const firestoreUserId = userSnapshot.docs[0].id;
      console.log('[LeadFormsPage] Firestore user ID:', firestoreUserId);
      if (firestoreUserId !== session.user.id) {
        console.log('[LeadFormsPage] OwnerId mismatch detected! Trying with Firestore user ID...');
        const leadFormsByFirestoreId = await listLeadForms(firestoreUserId);
        console.log('[LeadFormsPage] Lead forms found with Firestore ID:', leadFormsByFirestoreId.length);
        if (leadFormsByFirestoreId.length > 0) {
          // Use these lead forms instead
          return (
            <div className="space-y-8 font-mono">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-normal">Lead forms</h1>
                  <p className="text-sm text-gray-600">
                    Manage configurations, submissions, and embed tokens.
                  </p>
                  <p className="text-xs text-gray-600 mt-2">
                    Note: Fixed ownerId mismatch. Found {leadFormsByFirestoreId.length} lead form(s).
                  </p>
                </div>
                <Link
                  href="/leadforms/new"
                  className="border border-black bg-black px-4 py-2 text-sm font-normal text-white transition hover:bg-gray-800"
                >
                  Create lead form
                </Link>
              </div>

              <div className="space-y-1">
                {leadFormsByFirestoreId.map((leadForm) => (
                  <Link
                    key={leadForm.id}
                    href={`/leadforms/${leadForm.id}`}
                    className="flex items-center justify-between border-t border-b border-gray-300 py-6 transition hover:bg-gray-50"
                  >
                    <div className="space-y-1">
                      <h2 className="text-lg font-normal">{leadForm.name}</h2>
                      <p className="text-sm text-gray-600">
                        {leadForm.description || 'No description provided'}
                      </p>
                      <p className="text-xs text-gray-600">
                        {leadForm.submissionCount} submissions • Status:{' '}
                        <span className="font-normal">
                          {leadForm.status}
                        </span>
                      </p>
                    </div>
                    <span className="text-xs text-gray-600 font-mono">
                      {leadForm.embedToken}
                    </span>
                  </Link>
                ))}
              </div>
            </div>
          );
        }
      }
    }
  }

  return (
    <div className="space-y-6 font-mono">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-semibold">Lead forms</h1>
          <p className="mt-1 text-sm text-gray-600">
            Manage configurations, submissions, and embed tokens.
          </p>
        </div>
        <Link
          href="/leadforms/new"
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
        >
          Create lead form
        </Link>
      </div>

      <div className="space-y-3">
        {leadForms.length === 0 && (
          <div className="rounded-lg border border-gray-200 bg-white p-8 text-center text-sm text-gray-600 shadow-sm">
            You haven&apos;t created any lead forms yet. Kick things off by
            creating your first lead form configuration.
          </div>
        )}
        {leadForms.map((leadForm) => (
          <Link
            key={leadForm.id}
            href={`/leadforms/${leadForm.id}`}
            className="flex items-center justify-between rounded-lg border border-gray-200 bg-white p-6 shadow-sm transition hover:border-blue-300 hover:shadow-md"
          >
            <div className="space-y-2">
              <div className="flex items-center gap-3">
                <h2 className="text-lg font-semibold text-gray-900">{leadForm.name}</h2>
                <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                  leadForm.status === 'active'
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-amber-100 text-amber-800'
                }`}>
                  {leadForm.status}
                </span>
              </div>
              <p className="text-sm text-gray-600">
                {leadForm.description || 'No description provided'}
              </p>
              <p className="text-xs text-gray-500">
                {leadForm.submissionCount} submissions
              </p>
            </div>
            <span className="text-xs text-gray-500 font-mono">
              {leadForm.embedToken}
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}

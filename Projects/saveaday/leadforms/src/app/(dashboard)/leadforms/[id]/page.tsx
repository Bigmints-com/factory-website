import { SubmissionsTable } from '@/components/submissions-table';
import { authOptions } from '@/lib/authOptions';
import { getLeadFormById } from '@/lib/repositories/leadFormRepository';
import { listLeadFormSubmissions } from '@/lib/services/submissionService';
import { adminDb } from '@/lib/firebaseAdmin';
import { getUserByEmail } from '@/lib/repositories/userRepository';
import { getServerSession } from 'next-auth';
import { notFound, redirect } from 'next/navigation';
import Link from 'next/link';

export default async function LeadFormDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    redirect('/login');
  }

  let leadForm = await getLeadFormById(session.user.id, id);
  let ownerId = session.user.id;

  // If not found, try with Firestore user ID (in case of ownerId mismatch)
  if (!leadForm && session.user.email) {
    console.log('[LeadFormDetailPage] Lead form not found with session ID, trying Firestore user ID...');
    const user = await getUserByEmail(session.user.email);
    if (user && user.id !== session.user.id) {
      console.log('[LeadFormDetailPage] Trying with Firestore user ID:', user.id);
      leadForm = await getLeadFormById(user.id, id);
      if (leadForm) {
        ownerId = user.id;
        console.log('[LeadFormDetailPage] Found lead form with Firestore user ID');
      }
    }
  }

  if (!leadForm) {
    // Debug: Check if leadForm exists at all
    const leadFormDoc = await adminDb.collection('leadforms').doc(id).get();
    if (leadFormDoc.exists) {
      const data = leadFormDoc.data();
    console.log('[LeadFormDetailPage] Lead form exists but ownerId mismatch:', {
        leadFormId: id,
        leadFormOwnerId: data?.ownerId,
        sessionUserId: session.user.id,
        leadFormName: data?.name,
      });
    }
    notFound();
  }

  const submissions = await listLeadFormSubmissions({
    ownerId: ownerId,
    leadFormId: leadForm.id,
    limit: 25,
  });

  return (
    <div className="space-y-6 font-mono">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div>
            <h1 className="text-3xl font-semibold text-gray-900">{leadForm.name}</h1>
            <p className="mt-1 text-sm text-gray-600">
              View and manage submissions for this lead form.
            </p>
          </div>
          <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-medium ${
            leadForm.status === 'active'
              ? 'bg-emerald-100 text-emerald-800'
              : 'bg-amber-100 text-amber-800'
          }`}>
            {leadForm.status}
          </span>
        </div>
        <Link
          href={`/leadforms/${leadForm.id}/manage`}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
        >
          Manage
        </Link>
      </div>

      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <header className="mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Submissions</h2>
          <p className="mt-1 text-sm text-gray-600">
            Showing up to 25 latest submissions. Click "Manage" on any submission to view details and edit.
          </p>
        </header>

        <SubmissionsTable submissions={submissions} leadFormId={leadForm.id} />
      </section>
    </div>
  );
}

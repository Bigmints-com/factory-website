import { authOptions } from '@/lib/authOptions';
import { listLeadForms } from '@/lib/repositories/leadFormRepository';
import { listRecentSubmissions } from '@/lib/repositories/submissionRepository';
import { getUserById, getUserByEmail } from '@/lib/repositories/userRepository';
import { getServerSession } from 'next-auth';
import Link from 'next/link';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    redirect('/login');
  }

  // Try to get the correct user ID (handle ownerId mismatch)
  let ownerId = session.user.id;
  let userRecord = await getUserById(session.user.id);

  // If user not found or no data, try with Firestore user ID
  if ((!userRecord || !userRecord.apiToken) && session.user.email) {
    console.log('[Dashboard] User not found with session ID, trying Firestore user ID...');
    const userByEmail = await getUserByEmail(session.user.email);
    if (userByEmail && userByEmail.id !== session.user.id) {
      console.log('[Dashboard] Using Firestore user ID:', userByEmail.id);
      ownerId = userByEmail.id;
      userRecord = userByEmail;
    }
  }

  const [leadForms, recentSubmissions] = await Promise.all([
    listLeadForms(ownerId),
    listRecentSubmissions({ ownerId, limit: 10 }),
  ]);

  const totalSubmissions = leadForms.reduce(
    (sum, leadForm) => sum + (leadForm.submissionCount ?? 0),
    0,
  );

  return (
    <div className="space-y-8 font-mono">
      <header className="flex flex-col gap-2">
        <h1 className="text-3xl font-semibold">Overview</h1>
        <p className="text-sm text-gray-600">
          Track submission momentum and jump into your most active lead forms.
        </p>
      </header>

      <section className="grid gap-6 sm:grid-cols-3">
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
            Total submissions
          </p>
          <p className="mt-2 text-3xl font-semibold text-gray-900">{totalSubmissions}</p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
            Active lead forms
          </p>
          <p className="mt-2 text-3xl font-semibold text-emerald-600">
            {leadForms.filter((leadForm) => leadForm.status === 'active').length}
          </p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
            API token
          </p>
          <p className="mt-2 break-all text-sm font-mono tracking-wide text-gray-900">
            {userRecord?.apiToken ?? 'Generate from API settings'}
          </p>
        </div>
      </section>

      <section className="space-y-4">
        <header className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-normal">Most recent submissions</h2>
            <p className="text-sm text-gray-600">
              Latest activity across all lead forms.
            </p>
          </div>
          <Link
            href="/leadforms"
            className="text-sm text-gray-600 underline-offset-4 hover:underline"
          >
            View all lead forms
          </Link>
        </header>

        {recentSubmissions.length === 0 ? (
          <div className="rounded-lg border border-gray-200 bg-white p-6 text-sm text-gray-600 shadow-sm">
            No submissions yet. Share your embed to start collecting signups.
          </div>
        ) : (
          <div className="space-y-3">
            {recentSubmissions.map((submission) => (
              <div
                key={submission.id}
                className="flex flex-col gap-2 rounded-lg border border-gray-200 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900">{submission.name}</p>
                  <p className="text-xs text-gray-500">{submission.email}</p>
                </div>
                <div className="flex gap-6 text-xs text-gray-600">
                  <span>{submission.source ?? 'Lead source not provided'}</span>
                  <span>
                    {new Date(submission.createdAt).toLocaleString(undefined, {
                      dateStyle: 'medium',
                      timeStyle: 'short',
                    })}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

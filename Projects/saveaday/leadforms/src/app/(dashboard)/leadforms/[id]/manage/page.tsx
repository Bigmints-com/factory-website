import { LeadFormForm } from '@/components/leadform-form';
import {
  deleteLeadFormAction,
  updateLeadFormAction,
} from '@/lib/actions/leadFormActions';
import { authOptions } from '@/lib/authOptions';
import { getLeadFormById } from '@/lib/repositories/leadFormRepository';
import { getUserByEmail } from '@/lib/repositories/userRepository';
import { getServerSession } from 'next-auth';
import { notFound, redirect } from 'next/navigation';
import Link from 'next/link';
import { CodeBlock } from '@/components/code-block';

const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'https://your-domain.com';

export default async function LeadFormManagePage({
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

  // If not found, try with Firestore user ID (in case of ownerId mismatch)
  if (!leadForm && session.user.email) {
    console.log('[LeadFormManagePage] Lead form not found with session ID, trying Firestore user ID...');
    const user = await getUserByEmail(session.user.email);
    if (user && user.id !== session.user.id) {
      console.log('[LeadFormManagePage] Trying with Firestore user ID:', user.id);
      leadForm = await getLeadFormById(user.id, id);
      if (leadForm) {
        console.log('[LeadFormManagePage] Found lead form with Firestore user ID');
      }
    }
  }

  if (!leadForm) {
    notFound();
  }

  const updateAction = updateLeadFormAction.bind(null, leadForm.id);
  const deleteAction = deleteLeadFormAction.bind(null, leadForm.id);

  const embedSnippet = `<script src="${appUrl}/embed/${leadForm.embedToken}.js" data-leadform-token="${leadForm.embedToken}"></script>`;

  return (
    <div className="space-y-6 font-mono">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            href={`/leadforms/${leadForm.id}`}
            className="rounded-md p-2 text-gray-600 transition hover:bg-gray-100"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </Link>
          <div>
            <h1 className="text-3xl font-semibold text-gray-900">{leadForm.name}</h1>
            <p className="mt-1 text-sm text-gray-600">
              Manage configuration, embed snippet, and form experience.
            </p>
          </div>
        </div>
      </div>

      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <header className="mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Embed snippet</h2>
          <p className="mt-1 text-sm text-gray-600">
            Paste this script into your site and trigger{' '}
            <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800">showLeadFormModal()</code>{' '}
            to open the modal.
          </p>
        </header>
        <CodeBlock code={embedSnippet} />
      </section>

      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <header className="mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Lead form details</h2>
          <p className="mt-1 text-sm text-gray-600">
            Configure your lead form settings and appearance.
          </p>
        </header>
        <LeadFormForm
          action={updateAction}
          submitLabel="Save changes"
          initialValues={{
            name: leadForm.name,
            description: leadForm.description,
            sourceOptions: leadForm.sourceOptions,
            duplicateStrategy: leadForm.duplicateStrategy,
            status: leadForm.status,
            redirectUrl: leadForm.redirectUrl ?? '',
            brandColor: leadForm.styling.brandColor,
            buttonText: leadForm.styling.buttonText,
            successMessage: leadForm.styling.successMessage,
            namePlaceholder: leadForm.placeholders.name,
            emailPlaceholder: leadForm.placeholders.email,
            embedToken: leadForm.embedToken,
            leadFormId: leadForm.id,
          }}
          footerSlot={
            <form action={deleteAction} className="inline">
              <button
                type="submit"
                className="rounded-md border border-red-300 bg-white px-4 py-2 text-sm font-medium text-red-700 shadow-sm transition hover:bg-red-50"
              >
                Delete lead form
              </button>
            </form>
          }
        />
      </section>
    </div>
  );
}

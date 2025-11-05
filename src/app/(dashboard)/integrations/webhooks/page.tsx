import { createWebhookAction, deleteWebhookActionWithId, toggleWebhookActionWithId } from '@/lib/actions/webhookActions';
import { authOptions } from '@/lib/authOptions';
import { listLeadForms } from '@/lib/repositories/leadFormRepository';
import { listWebhooks } from '@/lib/repositories/webhookRepository';
import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';

export default async function WebhooksPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    redirect('/login');
  }

  const [leadForms, webhooks] = await Promise.all([
    listLeadForms(session.user.id),
    listWebhooks({ ownerId: session.user.id }),
  ]);

  return (
    <div className="space-y-6 font-mono">
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold">Webhooks</h1>
        <p className="text-sm text-gray-600">
          Send real-time notifications to your APIs or automation tools when submissions change.
        </p>
      </header>

      <section className="grid gap-8 lg:grid-cols-[2fr,3fr]">
        <form
          action={createWebhookAction}
          className="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
        >
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Create webhook</h2>
            <p className="text-sm text-gray-600">
              Configure an HTTPS endpoint and subscribe to submission events.
            </p>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="url">
              Endpoint URL
            </label>
            <input
              id="url"
              name="url"
              type="url"
              required
              placeholder="https://example.com/webhooks/lead-form"
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="leadFormId">
              Lead form (optional)
            </label>
            <select
              id="leadFormId"
              name="leadFormId"
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-sm text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All lead forms</option>
              {leadForms.map((leadForm) => (
                <option key={leadForm.id} value={leadForm.id}>
                  {leadForm.name}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-700">Events</p>
            <div className="flex flex-wrap gap-2 text-sm">
              {[
                { id: 'submission.created', label: 'Submission created' },
                { id: 'submission.updated', label: 'Submission updated' },
                { id: 'submission.deleted', label: 'Submission deleted' },
              ].map((event) => (
                <label
                  key={event.id}
                  className="flex items-center gap-2 rounded-md border border-gray-300 bg-white px-3 py-2 transition hover:bg-gray-50"
                >
                  <input
                    type="checkbox"
                    name="events"
                    value={event.id}
                    defaultChecked={event.id === 'submission.created'}
                    className="border-gray-300"
                  />
                  <span className="text-gray-900">{event.label}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="headers">
              Custom headers (optional)
            </label>
            <textarea
              id="headers"
              name="headers"
              rows={3}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono"
              placeholder={`Authorization: Bearer token\nX-Custom: value`}
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="retryLimit">
              Retry attempts
            </label>
            <input
              id="retryLimit"
              name="retryLimit"
              type="number"
              min={1}
              max={10}
              defaultValue={3}
              className="w-full border border-gray-300 bg-white px-4 py-3 text-sm text-black focus:border-black focus:outline-none"
            />
          </div>

          <div className="flex justify-end">
            <button
              type="submit"
                 className="rounded-md bg-blue-600 px-5 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
            >
              Create webhook
            </button>
          </div>
        </form>

        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-gray-900">Existing webhooks</h2>
          {webhooks.length === 0 ? (
            <p className="rounded-lg border border-gray-200 bg-white p-6 text-sm text-gray-600 shadow-sm">
              No webhooks yet. Create one to start streaming submission events.
            </p>
          ) : (
            <div className="space-y-1">
              {webhooks.map((webhook) => {
                return (
                  <div
                    key={webhook.id}
                    className="space-y-3 rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                  >
                    <div className="flex items-center justify-between gap-4">
                      <div>
                        <p className="text-sm font-medium text-gray-900">
                          {webhook.url}
                        </p>
                        <p className="text-xs text-gray-600">
                          {webhook.leadFormId
                            ? `Scope: ${leadForms.find((w) => w.id === webhook.leadFormId)?.name ?? 'Unknown'}`
                            : 'Scope: All lead forms'}
                        </p>
                      </div>
                      <form action={toggleWebhookActionWithId}>
                        <input type="hidden" name="webhookId" value={webhook.id} />
                        <input type="hidden" name="active" value={String(!webhook.active)} />
                        <button
                          type="submit"
                          className={`rounded-md px-4 py-2 text-xs font-medium shadow-sm transition ${
                            webhook.active
                              ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                              : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                          }`}
                        >
                          {webhook.active ? 'Active' : 'Inactive'}
                        </button>
                      </form>
                    </div>
                    <div className="text-xs text-gray-600 font-mono">
                      <p>Events: {webhook.events.join(', ')}</p>
                      <p>Retries: up to {webhook.retryLimit}</p>
                      <p>Secret: {webhook.secret}</p>
                    </div>
                    <div className="flex justify-start">
                      <form action={deleteWebhookActionWithId}>
                        <input type="hidden" name="webhookId" value={webhook.id} />
                        <button
                          type="submit"
                          className="rounded-md border border-red-300 bg-white px-3 py-1.5 text-xs font-medium text-red-700 shadow-sm transition hover:bg-red-50"
                        >
                          Delete
                        </button>
                      </form>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </section>
    </div>
  );
}

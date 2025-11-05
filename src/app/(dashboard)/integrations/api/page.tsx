import { regenerateApiTokenAction } from '@/lib/actions/apiTokenActions';
import { authOptions } from '@/lib/authOptions';
import { getUserById, getUserByEmail, upsertGoogleUser } from '@/lib/repositories/userRepository';
import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';
import { CodeBlock } from '@/components/code-block';
import { ApiTokenDisplay } from '@/components/api-token-display';

const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000';

export default async function ApiIntegrationPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    redirect('/login');
  }

  let user = await getUserById(session.user.id);
  
  // If user doesn't exist, try to find by email or create it
  if (!user && session.user.email) {
    const userByEmail = await getUserByEmail(session.user.email);
    if (userByEmail) {
      user = userByEmail;
    } else {
      // Create the user if it doesn't exist (shouldn't happen but handle gracefully)
      user = await upsertGoogleUser({
        email: session.user.email,
        name: session.user.name ?? undefined,
      });
    }
  }

  const apiToken = user?.apiToken ?? 'YOUR_TOKEN';

  return (
    <div className="space-y-6 font-mono">
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold">API access</h1>
        <p className="text-sm text-gray-600">
          Use your API token to query submissions programmatically. All requests must include the token via the Authorization header.
        </p>
      </header>

      {/* API Token Section */}
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <div className="flex items-start justify-between gap-6">
          <div className="flex-1 space-y-3">
            <h2 className="text-lg font-semibold text-gray-900">API token</h2>
            <p className="text-sm text-gray-600">
              Keep this token secure. It provides full access to your submissions. If compromised, regenerate it immediately.
            </p>
            <ApiTokenDisplay token={apiToken} />
          </div>
                 <form action={async () => { await regenerateApiTokenAction(); return; }} className="flex-shrink-0">
            <button
              type="submit"
              className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
            >
              Regenerate
            </button>
          </form>
        </div>
      </section>

      {/* Authentication */}
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Authentication</h2>
        <p className="text-sm text-gray-600 mb-4">
          Include your API token in the <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">Authorization</code> header for all requests:
        </p>
        <CodeBlock code={`Authorization: Bearer ${apiToken}`} />
        <div className="mt-4 space-y-2 text-sm text-gray-600">
          <p>• Token format: <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">Bearer &lt;token&gt;</code></p>
          <p>• Token must be included in every request</p>
          <p>• Invalid or missing tokens return <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">401 Unauthorized</code></p>
        </div>
      </section>

      {/* Endpoints */}
      <section className="space-y-6">
        <h2 className="text-xl font-semibold text-gray-900">Endpoints</h2>

        {/* List Submissions */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-1">List submissions</h3>
              <p className="text-sm font-mono text-gray-600">
                GET {appUrl}/api/v1/submissions
              </p>
            </div>

            <div className="space-y-3">
              <h4 className="text-sm font-semibold text-gray-900">Query Parameters</h4>
              <div className="space-y-2 text-sm text-gray-600">
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">leadFormId</code>
                  <span className="text-xs">(optional) Filter by specific leadForm ID</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">limit</code>
                  <span className="text-xs">(optional, default: 50, max: 1000) Number of results per page</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">offset</code>
                  <span className="text-xs">(optional, default: 0) Number of results to skip for pagination</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">startDate</code>
                  <span className="text-xs">(optional) ISO 8601 date string - filter submissions created on or after</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">endDate</code>
                  <span className="text-xs">(optional) ISO 8601 date string - filter submissions created on or before</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">search</code>
                  <span className="text-xs">(optional) Search by name or email (case-insensitive)</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">format</code>
                  <span className="text-xs">(optional) Response format: <code className="rounded-md bg-gray-100 px-1 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">json</code> (default) or <code className="rounded-md bg-gray-100 px-1 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">csv</code></span>
                </div>
              </div>
            </div>

            <div>
              <h4 className="text-sm font-semibold text-gray-900 mb-2">Response Format (JSON)</h4>
              <CodeBlock code={`{
  "success": true,
  "data": [
    {
      "id": "submission-id",
      "leadFormId": "leadForm-id",
      "ownerId": "user-id",
      "name": "John Doe",
      "email": "john@example.com",
      "source": "Website",
      "emailHash": "...",
      "createdAt": "2025-11-04T12:00:00.000Z",
      "updatedAt": "2025-11-04T12:00:00.000Z",
      "isDuplicate": false,
      "duplicateOf": null,
      "metadata": {
        "ip": "192.168.1.1",
        "userAgent": "Mozilla/5.0...",
        "referrer": "https://example.com"
      }
    }
  ],
  "count": 1,
  "hasMore": false
}`} />
            </div>

            <div className="space-y-4">
              <h4 className="text-sm font-semibold text-gray-900">Examples</h4>
              
              <div>
                <p className="text-xs font-medium text-gray-700 mb-2">cURL</p>
                <CodeBlock code={`curl -H "Authorization: Bearer ${apiToken}" \\
  "${appUrl}/api/v1/submissions?leadFormId=WLZDlKnPHSrdDgL7VeNF&limit=50"`} />
              </div>

              <div>
                <p className="text-xs font-medium text-gray-700 mb-2">JavaScript (fetch)</p>
                <CodeBlock code={`const response = await fetch(
  '${appUrl}/api/v1/submissions?leadFormId=WLZDlKnPHSrdDgL7VeNF&limit=50',
  {
    headers: {
      'Authorization': 'Bearer ${apiToken}'
    }
  }
);
const data = await response.json();`} />
              </div>

              <div>
                <p className="text-xs font-medium text-gray-700 mb-2">Python (requests)</p>
                <CodeBlock code={`import requests

response = requests.get(
    '${appUrl}/api/v1/submissions',
    headers={'Authorization': f'Bearer {api_token}'},
    params={
        'leadFormId': 'WLZDlKnPHSrdDgL7VeNF',
        'limit': 50
    }
)
data = response.json()`} />
              </div>

              <div>
                <p className="text-xs font-medium text-gray-700 mb-2">CSV Export</p>
                <CodeBlock code={`curl -H "Authorization: Bearer ${apiToken}" \\
  "${appUrl}/api/v1/submissions?leadFormId=WLZDlKnPHSrdDgL7VeNF&format=csv"`} />
              </div>
            </div>
          </div>
        </div>

        {/* Get Single Submission */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-1">Get single submission</h3>
              <p className="text-sm font-mono text-gray-600">
                GET {appUrl}/api/v1/submissions/&lt;submissionId&gt;?leadFormId=&lt;leadFormId&gt;
              </p>
            </div>

            <div className="space-y-3">
              <h4 className="text-sm font-semibold text-gray-900">Required Parameters</h4>
              <div className="space-y-2 text-sm text-gray-600">
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">submissionId</code>
                  <span className="text-xs">(path) The ID of the submission to retrieve</span>
                </div>
                <div className="flex gap-2">
                  <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300 flex-shrink-0">leadFormId</code>
                  <span className="text-xs">(query, required) The leadForm ID containing this submission</span>
                </div>
              </div>
            </div>

            <div>
              <h4 className="text-sm font-semibold text-gray-900 mb-2">Response Format</h4>
              <CodeBlock code={`{
  "success": true,
  "data": {
    "id": "submission-id",
    "leadFormId": "leadForm-id",
    "name": "John Doe",
    "email": "john@example.com",
    "source": "Website",
    "createdAt": "2025-11-04T12:00:00.000Z",
    "updatedAt": "2025-11-04T12:00:00.000Z",
    "isDuplicate": false,
    "metadata": { ... }
  }
}`} />
            </div>

            <div>
              <h4 className="text-sm font-semibold text-gray-900 mb-2">Example</h4>
              <CodeBlock code={`curl -H "Authorization: Bearer ${apiToken}" \\
  "${appUrl}/api/v1/submissions/2hZo65SAj9tZOqGdGJEv?leadFormId=WLZDlKnPHSrdDgL7VeNF"`} />
            </div>
          </div>
        </div>
      </section>

      {/* Best Practices */}
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Best Practices</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex items-start gap-3">
            <span className="text-gray-900 mt-0.5 font-medium">•</span>
            <div>
              <p className="font-medium text-gray-900 mb-1">Security</p>
              <p>Never expose your API token in client-side code or public repositories. Store it securely in environment variables or server-side configuration.</p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-gray-900 mt-0.5 font-medium">•</span>
            <div>
              <p className="font-medium text-gray-900 mb-1">Pagination</p>
              <p>Use <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">limit</code> and <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">offset</code> for large datasets. Check the <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">hasMore</code> field to determine if more results are available.</p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-gray-900 mt-0.5 font-medium">•</span>
            <div>
              <p className="font-medium text-gray-900 mb-1">Error Handling</p>
              <p>Always check response status codes. <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">401</code> means unauthorized, <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">404</code> means not found, <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">500</code> indicates a server error.</p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-gray-900 mt-0.5 font-medium">•</span>
            <div>
              <p className="font-medium text-gray-900 mb-1">Rate Limiting</p>
              <p>Be mindful of request frequency. Implement exponential backoff for retries and cache responses when appropriate.</p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-gray-900 mt-0.5 font-medium">•</span>
            <div>
              <p className="font-medium text-gray-900 mb-1">Date Filtering</p>
              <p>Use ISO 8601 format for date parameters (e.g., <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">2025-11-04T12:00:00.000Z</code>). Both <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">startDate</code> and <code className="rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-800 border border-gray-300">endDate</code> are inclusive.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Error Codes */}
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">HTTP Status Codes</h2>
        <div className="space-y-2 text-sm">
          <div className="flex items-center gap-3">
            <code className="rounded-md border border-gray-300 px-2 py-1 text-xs font-mono text-gray-900 bg-white">401</code>
            <span className="text-gray-600">Unauthorized - Invalid or missing API token</span>
          </div>
          <div className="flex items-center gap-3">
            <code className="rounded-md border border-gray-300 px-2 py-1 text-xs font-mono text-gray-900 bg-white">400</code>
            <span className="text-gray-600">Bad Request - Missing required parameters or invalid format</span>
          </div>
          <div className="flex items-center gap-3">
            <code className="rounded-md border border-gray-300 px-2 py-1 text-xs font-mono text-gray-900 bg-white">404</code>
            <span className="text-gray-600">Not Found - Submission or lead form not found</span>
          </div>
          <div className="flex items-center gap-3">
            <code className="rounded-md border border-gray-300 px-2 py-1 text-xs font-mono text-gray-900 bg-white">500</code>
            <span className="text-gray-600">Internal Server Error - Database error or server issue</span>
          </div>
        </div>
      </section>
    </div>
  );
}

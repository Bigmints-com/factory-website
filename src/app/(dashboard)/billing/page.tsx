import { authOptions } from '@/lib/authOptions';
import { listLeadForms } from '@/lib/repositories/leadFormRepository';
import { listRecentSubmissions } from '@/lib/repositories/submissionRepository';
import { getUserById, getUserByEmail } from '@/lib/repositories/userRepository';
import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';

const FREE_TIER_LIMIT = 1000;
const PRICE_PER_10_SUBMISSIONS = 1; // $1 per 10 submissions
const PREPAID_DISCOUNT = 0.2; // 20% discount

export default async function BillingPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    redirect('/login');
  }

  // Try to get the correct user ID (handle ownerId mismatch)
  let ownerId = session.user.id;
  let userRecord = await getUserById(session.user.id);

  // If user not found or no data, try with Firestore user ID
  if ((!userRecord || !userRecord.apiToken) && session.user.email) {
    const userByEmail = await getUserByEmail(session.user.email);
    if (userByEmail && userByEmail.id !== session.user.id) {
      ownerId = userByEmail.id;
      userRecord = userByEmail;
    }
  }

  // Get all lead forms to calculate total submissions
  const leadForms = await listLeadForms(ownerId);
  const totalSubmissions = leadForms.reduce(
    (sum, leadForm) => sum + (leadForm.submissionCount ?? 0),
    0,
  );

  // Calculate billing
  const freeSubmissions = Math.min(totalSubmissions, FREE_TIER_LIMIT);
  const paidSubmissions = Math.max(0, totalSubmissions - FREE_TIER_LIMIT);
  const paidUnits = Math.ceil(paidSubmissions / 10);
  const payAsYouGoCost = paidUnits * PRICE_PER_10_SUBMISSIONS;
  const prepaidCost = payAsYouGoCost * (1 - PREPAID_DISCOUNT);

  const usagePercentage = Math.min(100, (totalSubmissions / FREE_TIER_LIMIT) * 100);

  return (
    <div className="space-y-6 font-mono">
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold">Billing</h1>
        <p className="text-sm text-gray-600">
          Manage your subscription and view usage statistics.
        </p>
      </header>

      {/* Current Usage */}
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Current Usage</h2>
        <div className="space-y-4">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-700">
                Total Submissions
              </span>
              <span className="text-sm font-semibold text-gray-900">
                {totalSubmissions.toLocaleString()} / {FREE_TIER_LIMIT.toLocaleString()} free
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2.5">
              <div
                className={`h-2.5 rounded-full transition-all ${
                  usagePercentage >= 100
                    ? 'bg-red-500'
                    : usagePercentage >= 80
                    ? 'bg-amber-500'
                    : 'bg-emerald-500'
                }`}
                style={{ width: `${usagePercentage}%` }}
              />
            </div>
            <p className="text-xs text-gray-500 mt-1">
              {totalSubmissions >= FREE_TIER_LIMIT
                ? `${paidSubmissions.toLocaleString()} submissions over the free tier limit`
                : `${(FREE_TIER_LIMIT - totalSubmissions).toLocaleString()} free submissions remaining`}
            </p>
          </div>

          {totalSubmissions > FREE_TIER_LIMIT && (
            <div className="rounded-md border border-amber-200 bg-amber-50 p-4">
              <div className="flex items-start">
                <svg
                  className="h-5 w-5 text-amber-600 mt-0.5 mr-3"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                <div>
                  <h3 className="text-sm font-medium text-amber-800">
                    Free tier limit exceeded
                  </h3>
                  <p className="text-sm text-amber-700 mt-1">
                    You have {paidSubmissions.toLocaleString()} submissions over the free tier.
                    Choose a payment plan to continue collecting submissions.
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Billing Plans */}
      {totalSubmissions > FREE_TIER_LIMIT && (
        <section className="space-y-6">
          <h2 className="text-lg font-semibold text-gray-900">Choose a Payment Plan</h2>
          <div className="grid gap-6 md:grid-cols-2">
            {/* Pay-as-you-go */}
            <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Pay-as-you-go</h3>
                <span className="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">
                  Recommended
                </span>
              </div>
              <div className="mb-4">
                <div className="flex items-baseline">
                  <span className="text-3xl font-semibold text-gray-900">
                    ${payAsYouGoCost.toFixed(2)}
                  </span>
                  <span className="ml-2 text-sm text-gray-600">
                    for {paidUnits * 10} submissions
                  </span>
                </div>
                <p className="text-sm text-gray-500 mt-1">
                  ${PRICE_PER_10_SUBMISSIONS} per 10 submissions
                </p>
              </div>
              <ul className="space-y-2 mb-6">
                <li className="flex items-start text-sm text-gray-600">
                  <svg
                    className="h-5 w-5 text-emerald-500 mr-2 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Pay only for what you use
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <svg
                    className="h-5 w-5 text-emerald-500 mr-2 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  No upfront commitment
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <svg
                    className="h-5 w-5 text-emerald-500 mr-2 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Automatic billing
                </li>
              </ul>
              <button className="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700">
                Subscribe to Pay-as-you-go
              </button>
            </div>

            {/* Prepaid Plan */}
            <div className="rounded-lg border-2 border-blue-500 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Prepaid Plan</h3>
                <span className="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800">
                  20% OFF
                </span>
              </div>
              <div className="mb-4">
                <div className="flex items-baseline">
                  <span className="text-3xl font-semibold text-gray-900">
                    ${prepaidCost.toFixed(2)}
                  </span>
                  <span className="ml-2 text-sm text-gray-600">
                    for {paidUnits * 10} submissions
                  </span>
                </div>
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-sm text-gray-400 line-through">
                    ${payAsYouGoCost.toFixed(2)}
                  </span>
                  <span className="text-sm text-emerald-600 font-medium">
                    Save ${(payAsYouGoCost - prepaidCost).toFixed(2)}
                  </span>
                </div>
              </div>
              <ul className="space-y-2 mb-6">
                <li className="flex items-start text-sm text-gray-600">
                  <svg
                    className="h-5 w-5 text-emerald-500 mr-2 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  20% discount on all submissions
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <svg
                    className="h-5 w-5 text-emerald-500 mr-2 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Credits never expire
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <svg
                    className="h-5 w-5 text-emerald-500 mr-2 flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Best value for high volume
                </li>
              </ul>
              <button className="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700">
                Purchase Prepaid Credits
              </button>
            </div>
          </div>
        </section>
      )}

      {/* Free Tier Info */}
      {totalSubmissions <= FREE_TIER_LIMIT && (
        <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Current Plan</h2>
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-medium text-gray-900">Free Tier</h3>
              <p className="text-sm text-gray-600 mt-1">
                {FREE_TIER_LIMIT.toLocaleString()} free submissions included
              </p>
            </div>
            <span className="inline-flex items-center rounded-full bg-emerald-100 px-3 py-1 text-sm font-medium text-emerald-800">
              Active
            </span>
          </div>
        </section>
      )}

      {/* Billing History - Placeholder */}
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Billing History</h2>
        <div className="text-center py-8 text-sm text-gray-500">
          No billing history yet. Your invoices will appear here once you subscribe to a paid plan.
        </div>
      </section>
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { signIn } from 'next-auth/react';
import Link from 'next/link';

export default function VerifyEmailPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');
  const [error, setError] = useState<string | null>(null);
  
  // Firebase email links include these parameters
  const oobCode = searchParams?.get('oobCode');
  const mode = searchParams?.get('mode');
  const email = searchParams?.get('email');
  const action = searchParams?.get('action');

  useEffect(() => {
    const verifyEmail = async () => {
      // If we have email and action, we can verify without oobCode
      // This happens when Firebase redirects to our custom URL
      if (!email) {
        setStatus('error');
        setError('Missing email parameter. Please use the link from your email.');
        return;
      }

      // Log received parameters for debugging
      if (process.env.NODE_ENV === 'development') {
        console.log('[VerifyEmail] Received params:', { oobCode, mode, email, action });
      }

      try {
        // Verify the email link
        // We can verify with just email if oobCode is missing
        const response = await fetch('/api/auth/verify-email-link', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            actionCode: oobCode || 'email-only', // Use placeholder if oobCode missing
            email: email,
            action: action || 'signup',
          }),
        });

        const data = await response.json();

        if (!response.ok) {
          setStatus('error');
          setError(data.error || 'Failed to verify email link');
          return;
        }

        // Use the email from the response (it's the verified email)
        const verifiedEmail = data.email;
        if (!verifiedEmail) {
          setStatus('error');
          setError('Unable to verify email address');
          return;
        }

        // Determine if this is signup or signin
        const isSignup = action === 'signup' || data.action === 'signup';

        // If it's a signup, create the user account first
        if (isSignup) {
          const registerResponse = await fetch('/api/auth/complete-signup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
              email: verifiedEmail,
              name: verifiedEmail.split('@')[0], // Use email prefix as name
            }),
          });

          const registerData = await registerResponse.json();

          if (!registerResponse.ok) {
            setStatus('error');
            setError(registerData.error || 'Failed to create account');
            return;
          }
        }

        // Sign in using the email link token
        if (data.sessionToken) {
          const signInResponse = await signIn('emailLink', {
            token: data.sessionToken,
            redirect: false,
          });

          if (signInResponse?.ok) {
            router.push('/dashboard');
            router.refresh();
            setStatus('success');
            return;
          } else {
            setStatus('error');
            setError('Failed to sign in. Please try again.');
            return;
          }
        }

        setStatus('error');
        setError('Missing session token');
      } catch (err) {
        console.error('[VerifyEmail] Error:', err);
        setStatus('error');
        setError(err instanceof Error ? err.message : 'An error occurred');
      }
    };

    verifyEmail();
  }, [oobCode, email, action, router]);

  if (status === 'loading') {
    return (
      <div className="flex min-h-screen w-full items-center justify-center bg-gray-50 px-6 py-16 font-mono">
        <div className="w-full max-w-md rounded-lg border border-gray-200 bg-white p-10 shadow-sm text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-sm text-gray-600">Verifying your email...</p>
        </div>
      </div>
    );
  }

  if (status === 'error') {
    return (
      <div className="flex min-h-screen w-full items-center justify-center bg-gray-50 px-6 py-16 font-mono">
        <div className="w-full max-w-md rounded-lg border border-red-200 bg-white p-10 shadow-sm">
          <div className="text-center">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-100 mb-4">
              <svg className="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h1 className="text-xl font-semibold text-gray-900 mb-2">Verification Failed</h1>
            <p className="text-sm text-gray-600 mb-6">{error}</p>
            <div className="space-y-2">
              <Link
                href="/register"
                className="inline-block rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
              >
                Try again
              </Link>
              <p className="text-xs text-gray-500">
                Or <Link href="/login" className="text-blue-600 hover:underline">sign in</Link> if you already have an account
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-gray-50 px-6 py-16 font-mono">
      <div className="w-full max-w-md rounded-lg border border-gray-200 bg-white p-10 shadow-sm">
        <div className="text-center">
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-emerald-100 mb-4">
            <svg className="h-6 w-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-xl font-semibold text-gray-900 mb-2">Email Verified</h1>
          <p className="text-sm text-gray-600">Redirecting to dashboard...</p>
        </div>
      </div>
    </div>
  );
}

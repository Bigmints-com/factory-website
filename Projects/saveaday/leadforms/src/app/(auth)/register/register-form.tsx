"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { signIn } from 'next-auth/react';
import { z } from 'zod';

const emailSchema = z.string().email('Please provide a valid email');

export const RegisterForm = () => {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [sending, setSending] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [devLink, setDevLink] = useState<string | null>(null);

  const handleSendEmailLink = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setDevLink(null);

    // Validate email
    const emailValidation = emailSchema.safeParse(email);
    if (!emailValidation.success) {
      setError('Please provide a valid email address');
      return;
    }

    if (!name.trim()) {
      setError('Please provide your name');
      return;
    }

    setSending(true);

    try {
      const response = await fetch('/api/auth/send-email-link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, action: 'signup' }),
      });

      const data = await response.json();

      if (!response.ok) {
        setError(data.error || 'Failed to send email link');
        setSending(false);
        return;
      }

      setEmailSent(true);
      // In development, show the link
      if (data.link) {
        setDevLink(data.link);
      }
    } catch (err) {
      setError('Failed to send email link. Please try again.');
    } finally {
      setSending(false);
    }
  };

  const handleGoogle = async () => {
    await signIn('google', {
      callbackUrl: '/dashboard',
    });
  };

  if (emailSent) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-blue-50 p-4 text-sm text-blue-800">
          <p className="font-medium">Check your email</p>
          <p className="mt-1">
            We've sent a sign-in link to <strong>{email}</strong>
          </p>
          <p className="mt-2">
            Click the link in the email to complete your registration. The link will expire in 1 hour.
          </p>
        </div>

        {devLink && (
          <div className="rounded-md bg-blue-100 p-4 text-sm">
            <p className="font-medium mb-2">Development mode - Your link:</p>
            <a
              href={devLink}
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:underline break-all font-mono text-xs"
            >
              {devLink}
            </a>
          </div>
        )}

        <div className="text-center space-y-2">
          <button
            type="button"
            onClick={() => {
              setEmailSent(false);
              setEmail('');
              setName('');
              setError(null);
            }}
            className="text-sm text-blue-600 hover:text-blue-700 hover:underline"
          >
            Use a different email
          </button>
          <p className="text-xs text-gray-600">
            Didn't receive the email? Check your spam folder or try again.
          </p>
        </div>
      </div>
    );
  }

  return (
    <>
      <form onSubmit={handleSendEmailLink} className="space-y-6">
        <div className="space-y-2">
          <label
            htmlFor="name"
            className="block text-sm font-medium text-gray-700"
          >
            Name
          </label>
          <input
            id="name"
            name="name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Ada Lovelace"
            required
            className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="space-y-2">
          <label
            htmlFor="email"
            className="block text-sm font-medium text-gray-700"
          >
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            placeholder="you@example.com"
            className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {error && (
          <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">
            {error}
          </div>
        )}

        <button
          type="submit"
          disabled={sending}
          className="w-full rounded-md bg-blue-600 px-6 py-3 font-medium text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {sending ? 'Sending link…' : 'Continue with email'}
        </button>
      </form>

      <div className="mt-6 border-t border-gray-300 pt-6">
        <button
          type="button"
          onClick={handleGoogle}
          disabled={sending}
          className="w-full rounded-md border border-gray-300 bg-white px-6 py-3 font-medium text-gray-700 shadow-sm transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
        >
          Continue with Google
        </button>
        <p className="mt-2 text-center text-xs text-gray-600">
          Optional — enable by setting Google OAuth credentials.
        </p>
      </div>
    </>
  );
};

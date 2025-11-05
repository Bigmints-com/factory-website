"use client";

import { signOut } from 'next-auth/react';

export const SignOutButton = () => (
  <button
    onClick={() => signOut({ callbackUrl: '/' })}
    className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition hover:bg-gray-50"
  >
    Sign out
  </button>
);

"use client";

import { SessionProvider } from 'next-auth/react';
import type { Session } from 'next-auth';

interface Props {
  children: React.ReactNode;
  session?: Session | null;
}

export const AuthSessionProvider = ({ children, session }: Props) => (
  <SessionProvider session={session}>{children}</SessionProvider>
);

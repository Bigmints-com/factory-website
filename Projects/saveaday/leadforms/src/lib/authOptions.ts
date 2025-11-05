import type { NextAuthOptions } from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import GoogleProvider from 'next-auth/providers/google';
import bcrypt from 'bcryptjs';
import { readFileSync } from 'fs';
import { join } from 'path';
import {
  getUserByEmail,
  touchUserLogin,
  upsertGoogleUser,
} from '@/lib/repositories/userRepository';
import { getNextAuthSecret } from '@/lib/getNextAuthSecret';
import { verifySSOToken } from '@/lib/sso';

// Load Google OAuth credentials from creds folder if available
let googleClientId = process.env.GOOGLE_CLIENT_ID;
let googleClientSecret = process.env.GOOGLE_CLIENT_SECRET;

if (!googleClientId || !googleClientSecret) {
  try {
    const googleCredsPath = join(
      process.cwd(),
      'creds',
      'client_secret_2_647930923087-pautg3hpsa1irb6q6ub46qh1eoarbmqc.apps.googleusercontent.com.json',
    );
    const googleCreds = JSON.parse(readFileSync(googleCredsPath, 'utf8'));
    if (googleCreds.web) {
      googleClientId = googleClientId || googleCreds.web.client_id;
      googleClientSecret = googleClientSecret || googleCreds.web.client_secret;
    }
  } catch (error) {
    // Ignore if file doesn't exist, will use env vars only
  }
}

// Get persistent NEXTAUTH_SECRET (uses env var or generates/saves one for development)
const NEXTAUTH_SECRET = getNextAuthSecret();

// Set NEXTAUTH_URL for proper redirect handling
if (!process.env.NEXTAUTH_URL && process.env.NODE_ENV === 'development') {
  // Use port 3012 for leadforms app
  process.env.NEXTAUTH_URL = 'http://localhost:3012';
}

export const authOptions: NextAuthOptions = {
  secret: NEXTAUTH_SECRET,
  session: {
    strategy: 'jwt',
  },
  providers: [
    CredentialsProvider({
      id: 'password',
      name: 'Email and Password',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null;
        }

        const user = await getUserByEmail(credentials.email);
        if (!user || !user.passwordHash) {
          return null;
        }

        const match = await bcrypt.compare(
          credentials.password,
          user.passwordHash,
        );
        if (!match) {
          return null;
        }

        await touchUserLogin(user.id);
        return {
          id: user.id,
          email: user.email,
          name: user.name,
        };
      },
    }),
    CredentialsProvider({
      id: 'emailLink',
      name: 'Email Link',
      credentials: {
        token: { label: 'Token', type: 'text' },
      },
      async authorize(credentials) {
        if (!credentials?.token) {
          return null;
        }

        const { verifyEmailLinkToken } = await import('@/lib/services/emailLinkToken');
        const result = await verifyEmailLinkToken(credentials.token);
        
        if (!result) {
          return null;
        }

        const user = await getUserByEmail(result.email);
        if (!user) {
          return null;
        }

        await touchUserLogin(user.id);
        return {
          id: user.id,
          email: user.email,
          name: user.name,
        };
      },
    }),
    // SSO Provider - checks SSO token from auth service
    CredentialsProvider({
      id: 'sso',
      name: 'SSO',
      credentials: {},
      async authorize() {
        // Verify SSO token
        const ssoUser = await verifySSOToken();
        if (!ssoUser) {
          return null;
        }

        // Get or create user in database
        let user = await getUserByEmail(ssoUser.email);
        
        if (!user) {
          // Create user from SSO
          const { upsertGoogleUser } = await import('@/lib/repositories/userRepository');
          user = await upsertGoogleUser({
            email: ssoUser.email,
            name: ssoUser.name,
          });
        }

        await touchUserLogin(user.id);
        return {
          id: user.id,
          email: user.email,
          name: user.name,
        };
      },
    }),
    // Enable Google OAuth if credentials are available
    // NextAuth will automatically use NEXTAUTH_URL for the redirect URI
    ...(googleClientId && googleClientSecret
      ? [
          GoogleProvider({
            clientId: googleClientId,
            clientSecret: googleClientSecret,
          }),
        ]
      : []),
  ],
  callbacks: {
    async jwt({ token, user, account }) {
      if (account?.provider === 'google' && user?.email) {
        try {
          console.log('[NextAuth] Processing Google OAuth for:', user.email);
          const upserted = await upsertGoogleUser({
            email: user.email,
            name: user.name ?? undefined,
          });
          console.log('[NextAuth] Google user upserted:', upserted.id);
          token.sub = upserted.id;
        } catch (error) {
          console.error('[NextAuth] Error upserting Google user:', error);
          // Don't throw - log the error but allow the session to continue
          // The user will still be authenticated via Google, just without local DB record
          if (!token.sub && user?.email) {
            // Fallback: use email as identifier if upsert fails
            token.sub = user.email;
          }
        }
      }
      if (user?.id) {
        token.sub = user.id;
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user && token.sub) {
        session.user.id = token.sub;
      }
      return session;
    },
    async redirect({ url, baseUrl }) {
      console.log('[NextAuth] Redirect callback:', { url, baseUrl });
      // If url is a relative path, prepend baseUrl
      if (url.startsWith('/')) {
        const redirectUrl = `${baseUrl}${url}`;
        console.log('[NextAuth] Redirecting to relative path:', redirectUrl);
        return redirectUrl;
      }
      // If url is on the same origin, allow it
      try {
        const urlObj = new URL(url);
        if (urlObj.origin === baseUrl) {
          console.log('[NextAuth] Redirecting to same origin:', url);
          return url;
        }
      } catch (e) {
        console.log('[NextAuth] Invalid URL, using baseUrl');
      }
      // Default to dashboard if no specific URL
      const defaultUrl = `${baseUrl}/dashboard`;
      console.log('[NextAuth] Default redirect to:', defaultUrl);
      return defaultUrl;
    },
  },
  pages: {
    signIn: '/login',
  },
};

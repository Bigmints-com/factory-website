import { withAuth } from 'next-auth/middleware';
import { NextResponse } from 'next/server';
import { verifySSOToken } from '@/lib/sso';

export default withAuth(
  async function middleware(req) {
    // If NextAuth session exists, allow access
    if (req.nextauth.token) {
      return NextResponse.next();
    }

    // Check if we're in local development
    const host = req.headers.get('host') || '';
    const isLocalhost = host.includes('localhost') || host.includes('127.0.0.1');
    const bypassSSO = process.env.BYPASS_SSO_LOCALLY !== 'false' && (isLocalhost || process.env.NODE_ENV === 'development');
    
    // If local development and SSO bypass is enabled, allow access to /login
    // and redirect unauthenticated users to /login instead of SSO
    if (bypassSSO) {
      // Allow access to login page
      const url = new URL(req.url);
      if (url.pathname === '/login' || url.pathname === '/register') {
        return NextResponse.next();
      }
      
      // For other protected routes, redirect to local login
      const loginUrl = new URL('/login', req.url);
      loginUrl.searchParams.set('callbackUrl', req.url);
      return NextResponse.redirect(loginUrl);
    }

    // Production: Use SSO flow
    // If no NextAuth session, check SSO token
    const ssoUser = await verifySSOToken();
    
    if (!ssoUser) {
      // No SSO token either, redirect to SSO login
      const returnUrl = req.url;
      const authUrl = `${process.env.SSO_AUTH_URL || 'https://auth.saveaday.ai'}/login?returnUrl=${encodeURIComponent(returnUrl)}`;
      return NextResponse.redirect(authUrl);
    }

    // SSO token exists but no NextAuth session
    // Try to sign in with SSO provider
    // This will trigger NextAuth to call the SSO provider's authorize function
    const signInUrl = new URL('/api/auth/signin/sso', req.url);
    signInUrl.searchParams.set('callbackUrl', req.url);
    
    return NextResponse.redirect(signInUrl);
  },
  {
    callbacks: {
      authorized: ({ token, req }) => {
        // Allow if NextAuth token exists
        if (token) return true;
        
        // Will check SSO in the middleware function above
        return true;
      },
    },
  }
);

export const config = {
  matcher: ['/dashboard/:path*', '/leadforms/:path*', '/integrations/:path*'],
};

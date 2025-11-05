/**
 * SSO Integration Utilities
 * Handles communication with the centralized auth service
 */

/**
 * Check if we're in local development environment
 * Returns true if we should bypass SSO and use regular login
 */
export function isLocalDevelopment(): boolean {
  // Client-side check - check window location
  if (typeof window !== 'undefined') {
    try {
      const hostname = window.location.hostname;
      return hostname === 'localhost' || hostname === '127.0.0.1';
    } catch (e) {
      // window might not be available in some contexts
      return false;
    }
  }
  
  // Server-side check
  try {
    // Check environment variable first (can be set to 'false' to force SSO even locally)
    if (typeof process !== 'undefined' && process.env) {
      if (process.env.BYPASS_SSO_LOCALLY === 'false') {
        return false;
      }
      if (process.env.BYPASS_SSO_LOCALLY === 'true') {
        return true;
      }
      
      // Check NODE_ENV
      if (process.env.NODE_ENV === 'development') {
        return true;
      }
    }
  } catch (e) {
    // process.env might not be available in some contexts
  }
  
  return false;
}

/**
 * Check if we should use SSO (opposite of isLocalDevelopment)
 * In production, always use SSO. In local dev, can be bypassed.
 */
export function shouldUseSSO(): boolean {
  return !isLocalDevelopment();
}

// Detect local development and use localhost auth service
function getSSOAuthURL(): string {
  // Check environment variable first
  if (process.env.SSO_AUTH_URL || process.env.NEXT_PUBLIC_SSO_AUTH_URL) {
    return process.env.SSO_AUTH_URL || process.env.NEXT_PUBLIC_SSO_AUTH_URL || 'https://auth.saveaday.ai';
  }
  
  const isServer = typeof window === 'undefined';
  
  // Check if running on localhost (client-side)
  if (!isServer) {
    try {
      const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
      if (isLocalhost) {
        return 'http://localhost:3000';
      }
    } catch (e) {
      // window might not be available in some contexts
    }
  }
  
  // Server-side check - use 127.0.0.1 in development (more reliable than localhost on some systems)
  if (isServer && typeof process !== 'undefined' && process.env.NODE_ENV === 'development') {
    return 'http://127.0.0.1:3000';
  }
  
  // Default to production
  return 'https://auth.saveaday.ai';
}

export interface SSOUser {
  uid: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  picture?: string;
}

/**
 * Verify SSO token and get user information
 * Works on both client and server side
 */
export async function verifySSOToken(): Promise<SSOUser | null> {
  try {
    const SSO_AUTH_URL = getSSOAuthURL();
    const response = await fetch(`${SSO_AUTH_URL}/api/auth/verify`, {
      credentials: 'include', // Include cookies
      headers: {
        'Content-Type': 'application/json',
      },
      // Don't cache
      cache: 'no-store',
    });

    if (!response.ok) {
      return null;
    }

    const data = await response.json();
    if (data.authenticated && data.user) {
      return data.user;
    }
    return null;
  } catch (error) {
    console.error('SSO verification failed:', error);
    return null;
  }
}

/**
 * Redirect to SSO login page
 */
export function redirectToSSO(returnUrl?: string) {
  const SSO_AUTH_URL = getSSOAuthURL();
  const currentUrl = returnUrl || (typeof window !== 'undefined' ? window.location.href : '');
  const authUrl = `${SSO_AUTH_URL}/login?returnUrl=${encodeURIComponent(currentUrl)}`;
  
  if (typeof window !== 'undefined') {
    window.location.href = authUrl;
  }
}

/**
 * Logout from SSO (clears SSO cookie)
 */
export async function logoutSSO() {
  try {
    const SSO_AUTH_URL = getSSOAuthURL();
    await fetch(`${SSO_AUTH_URL}/api/auth/logout`, {
      method: 'POST',
      credentials: 'include',
    });
  } catch (error) {
    console.error('SSO logout failed:', error);
  }
}


import { NextResponse } from 'next/server';
import { z } from 'zod';
import { adminAuth } from '@/lib/firebaseAdmin';
import { generateEmailLinkToken } from '@/lib/services/emailLinkToken';
import { getUserByEmail } from '@/lib/repositories/userRepository';

// Force dynamic rendering to prevent build-time analysis
export const dynamic = 'force-dynamic';

const verifyEmailLinkSchema = z.object({
  actionCode: z.string().optional(), // Make optional since we can verify with just email
  email: z.string().email(),
  action: z.enum(['signup', 'signin']).optional(),
});

export const POST = async (request: Request) => {
  try {
    const body = await request.json();
    const parsed = verifyEmailLinkSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Invalid request parameters', details: parsed.error.flatten().fieldErrors },
        { status: 400 },
      );
    }

    const { actionCode, email: providedEmail, action: providedAction } = parsed.data;

    // Email is required
    if (!providedEmail) {
      return NextResponse.json(
        { error: 'Email is required for verification' },
        { status: 400 },
      );
    }

    try {
      let email = providedEmail;
      let firebaseUser = null;

      // Try to get user from Firebase Auth
      try {
        firebaseUser = await adminAuth.getUserByEmail(email);
      } catch (error: any) {
        // User not found in Firebase Auth is OK - it means it's a new signup
        if (error.code !== 'auth/user-not-found') {
          throw error;
        }
      }

      // If we have a Firebase user, verify the email is verified
      // If no Firebase user, it's a new signup
      const isSignup = !firebaseUser;

      // Check if user exists in our database
      const dbUser = await getUserByEmail(email);
      
      // Determine action: signup if user doesn't exist in our DB, signin otherwise
      const action = providedAction || (dbUser ? 'signin' : 'signup');

      // Generate a one-time token for NextAuth session
      const sessionToken = await generateEmailLinkToken(email);

      return NextResponse.json({
        success: true,
        email,
        uid: firebaseUser?.uid,
        action,
        sessionToken,
      });
    } catch (error: any) {
      console.error('[VerifyEmailLink] Error:', error);
      
      // If user doesn't exist in Firebase Auth, it's still valid for signup
      if (error.code === 'auth/user-not-found' && providedEmail) {
        const sessionToken = await generateEmailLinkToken(providedEmail);
        
        return NextResponse.json({
          success: true,
          email: providedEmail,
          action: 'signup',
          sessionToken,
        });
      }
      
      return NextResponse.json(
        { error: error.message || 'Failed to verify email link' },
        { status: 500 },
      );
    }
  } catch (error: any) {
    console.error('[VerifyEmailLink] Error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to verify email link' },
      { status: 500 },
    );
  }
};

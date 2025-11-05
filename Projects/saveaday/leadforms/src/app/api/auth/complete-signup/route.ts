import { NextResponse } from 'next/server';
import { z } from 'zod';
import { registerUser } from '@/lib/actions/authActions';
import { getUserByEmail } from '@/lib/repositories/userRepository';
import { adminAuth } from '@/lib/firebaseAdmin';

// Force dynamic rendering to prevent build-time analysis
export const dynamic = 'force-dynamic';

const completeSignupSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});

export const POST = async (request: Request) => {
  try {
    const body = await request.json();
    const parsed = completeSignupSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Invalid request parameters', details: parsed.error.flatten().fieldErrors },
        { status: 400 },
      );
    }

    const { email, name } = parsed.data;

    // Check if user already exists in our system
    const existing = await getUserByEmail(email);
    if (existing) {
      // User exists, return success (they can sign in)
      return NextResponse.json({
        success: true,
        message: 'Account already exists',
        existing: true,
      });
    }

    // Create user account using our existing registerUser action
    // For email link auth, we don't need a password - we'll generate one
    const formData = new FormData();
    formData.set('email', email);
    formData.set('name', name);
    // Generate a random password - user won't need it for email link auth
    formData.set('password', Math.random().toString(36).slice(-12) + Math.random().toString(36).slice(-12) + 'A1!');

    const result = await registerUser(formData);

    if (!result.success) {
      return NextResponse.json(
        { error: 'Failed to create account', details: result.errors },
        { status: 500 },
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Account created successfully',
    });
  } catch (error: any) {
    console.error('[CompleteSignup] Error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to complete signup' },
      { status: 500 },
    );
  }
};

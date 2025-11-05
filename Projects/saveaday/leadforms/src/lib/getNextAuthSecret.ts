import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import { randomBytes } from 'crypto';

const SECRET_FILE = join(process.cwd(), '.nextauth-secret');

export function getNextAuthSecret(): string {
  // If set in environment, use it
  if (process.env.NEXTAUTH_SECRET) {
    return process.env.NEXTAUTH_SECRET;
  }

  // During build time, generate a temporary secret
  // This allows the build to complete, but production runtime must have NEXTAUTH_SECRET set
  const isBuildTime = process.env.NEXT_PHASE === 'phase-production-build' || 
                      process.env.NEXT_PHASE === 'phase-development-server';
  
  if (process.env.NODE_ENV === 'production' && !isBuildTime) {
    // In actual production runtime, require the secret
    throw new Error(
      'NEXTAUTH_SECRET must be set in production environment variables.',
    );
  }

  // In development or during build, use a persistent secret file
  if (existsSync(SECRET_FILE)) {
    try {
      const secret = readFileSync(SECRET_FILE, 'utf8').trim();
      if (secret.length > 0) {
        console.log('[NextAuth] Using persistent secret from file');
        return secret;
      }
    } catch (error) {
      console.warn('[NextAuth] Failed to read secret file, generating new one');
    }
  }

  // Generate a new secret and save it
  const secret = randomBytes(32).toString('base64');
  try {
    writeFileSync(SECRET_FILE, secret, { mode: 0o600 });
    console.log('[NextAuth] Generated and saved persistent secret for development');
  } catch (error) {
    console.warn('[NextAuth] Failed to save secret file, using in-memory secret');
  }

  return secret;
}

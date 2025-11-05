import { cert, getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { readFileSync } from 'fs';
import { join } from 'path';

const { FIRESTORE_DATABASE_ID } = process.env;

// Lazy initialization to avoid Firebase credential requirements during build time
let app: ReturnType<typeof initializeApp> | null = null;
let adminAuthInstance: Auth | null = null;
let adminDbInstance: Firestore | null = null;

function getFirebaseApp() {
  // Check if we're in build phase - Next.js tries to analyze routes during build
  const isBuildTime = 
    process.env.NEXT_PHASE === 'phase-production-build' ||
    (process.env.NODE_ENV === 'production' && !process.env.FIREBASE_PROJECT_ID);

  // Runtime initialization - normal flow
  if (!app) {
    let credentialConfig;

    try {
      const credsPath = join(process.cwd(), 'creds', 'dvizfb-314a185c77ef.json');
      const serviceAccount = JSON.parse(readFileSync(credsPath, 'utf8'));
      credentialConfig = cert({
        projectId: serviceAccount.project_id,
        clientEmail: serviceAccount.client_email,
        privateKey: serviceAccount.private_key,
      });
    } catch (error) {
      // Fall back to environment variables if file doesn't exist
      const {
        FIREBASE_PROJECT_ID,
        FIREBASE_CLIENT_EMAIL,
        FIREBASE_PRIVATE_KEY,
      } = process.env;

      if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
        throw new Error(
          'Missing Firebase service account credentials. Either provide creds/dvizfb-314a185c77ef.json or set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY environment variables.',
        );
      }

      credentialConfig = cert({
        projectId: FIREBASE_PROJECT_ID,
        clientEmail: FIREBASE_CLIENT_EMAIL,
        privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      });
    }

    app =
      getApps().length > 0
        ? getApp()
        : initializeApp({
            credential: credentialConfig,
          });
  }

  return app;
}

export function getAdminAuth(): Auth {
  // Check if we're in build phase
  const isBuildTime = process.env.NEXT_PHASE === 'phase-production-build';
  
  if (isBuildTime) {
    // During build, return a mock that won't throw errors
    // This allows Next.js to analyze routes without failing
    return {
      app: {} as any,
      getUserByEmail: () => Promise.reject(new Error('Firebase not available during build')),
      getUser: () => Promise.reject(new Error('Firebase not available during build')),
    } as any as Auth;
  }

  if (!adminAuthInstance) {
    const firebaseApp = getFirebaseApp();
    if (!firebaseApp) {
      throw new Error('Firebase Admin not initialized. Credentials are required at runtime.');
    }
    adminAuthInstance = getAuth(firebaseApp);
  }
  return adminAuthInstance;
}

export function getAdminDb(): Firestore {
  // Check if we're in build phase
  const isBuildTime = process.env.NEXT_PHASE === 'phase-production-build';
  
  if (isBuildTime) {
    // During build, return a mock that won't throw errors
    // This allows Next.js to analyze routes without failing
    return {
      app: {} as any,
      collection: () => ({
        doc: () => ({
          get: () => Promise.reject(new Error('Firebase not available during build')),
          set: () => Promise.reject(new Error('Firebase not available during build')),
          update: () => Promise.reject(new Error('Firebase not available during build')),
          collection: () => ({
            get: () => Promise.reject(new Error('Firebase not available during build')),
          }),
        }),
        where: () => ({
          get: () => Promise.reject(new Error('Firebase not available during build')),
        }),
        get: () => Promise.reject(new Error('Firebase not available during build')),
      }),
      collectionGroup: () => ({
        where: () => ({
          orderBy: () => ({
            get: () => Promise.reject(new Error('Firebase not available during build')),
          }),
          get: () => Promise.reject(new Error('Firebase not available during build')),
        }),
      }),
      batch: () => ({
        update: () => {},
        commit: () => Promise.reject(new Error('Firebase not available during build')),
      }),
    } as any as Firestore;
  }

  if (!adminDbInstance) {
    const firebaseApp = getFirebaseApp();
    if (!firebaseApp) {
      throw new Error('Firebase Admin not initialized. Credentials are required at runtime.');
    }
    // Use default database if FIRESTORE_DATABASE_ID is not set or is 'default'
    // Otherwise use the specified database ID
    const databaseId = FIRESTORE_DATABASE_ID && FIRESTORE_DATABASE_ID !== 'default' 
      ? FIRESTORE_DATABASE_ID 
      : 'leadforms'; // Default to 'leadforms' database
    adminDbInstance = getFirestore(firebaseApp, databaseId);
  }
  return adminDbInstance;
}

// Create Proxy objects that lazily initialize when accessed
// This allows the exports to work without initializing at module load time
export const adminAuth = new Proxy({} as Auth, {
  get(_target, prop) {
    const auth = getAdminAuth();
    const value = auth[prop as keyof Auth];
    if (typeof value === 'function') {
      return value.bind(auth);
    }
    return value;
  },
  has(_target, prop) {
    return prop in getAdminAuth();
  },
  ownKeys(_target) {
    return Object.keys(getAdminAuth());
  },
  getOwnPropertyDescriptor(_target, prop) {
    const auth = getAdminAuth();
    return Object.getOwnPropertyDescriptor(auth, prop);
  },
}) as Auth;

export const adminDb = new Proxy({} as Firestore, {
  get(_target, prop) {
    const db = getAdminDb();
    const value = db[prop as keyof Firestore];
    if (typeof value === 'function') {
      return value.bind(db);
    }
    return value;
  },
  has(_target, prop) {
    return prop in getAdminDb();
  },
  ownKeys(_target) {
    return Object.keys(getAdminDb());
  },
  getOwnPropertyDescriptor(_target, prop) {
    const db = getAdminDb();
    return Object.getOwnPropertyDescriptor(db, prop);
  },
}) as Firestore;

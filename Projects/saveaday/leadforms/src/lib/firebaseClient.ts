/**
 * Firebase Client SDK configuration
 * Used for email link authentication on the client side
 */
import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import { getAuth, type Auth } from 'firebase/auth';

// Get Firebase config from service account or environment
const getFirebaseConfig = () => {
  // Try to get from service account file
  try {
    const { readFileSync } = require('fs');
    const { join } = require('path');
    const credsPath = join(process.cwd(), 'creds', 'dvizfb-314a185c77ef.json');
    const serviceAccount = JSON.parse(readFileSync(credsPath, 'utf8'));
    return {
      apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '',
      authDomain: `${serviceAccount.project_id}.firebaseapp.com`,
      projectId: serviceAccount.project_id,
      storageBucket: `${serviceAccount.project_id}.appspot.com`,
      messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
      appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '',
    };
  } catch (error) {
    // Fall back to environment variables
    return {
      apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '',
      authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || '',
      projectId: process.env.FIREBASE_PROJECT_ID || process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || '',
      storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || '',
      messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
      appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '',
    };
  }
};

let app: FirebaseApp | undefined;
let auth: Auth | undefined;

export const getFirebaseApp = (): FirebaseApp => {
  if (!app) {
    const apps = getApps();
    if (apps.length > 0) {
      app = apps[0];
    } else {
      const config = getFirebaseConfig();
      if (!config.apiKey || !config.projectId) {
        throw new Error('Firebase client configuration is missing. Please set NEXT_PUBLIC_FIREBASE_API_KEY and FIREBASE_PROJECT_ID');
      }
      app = initializeApp(config);
    }
  }
  return app;
};

export const getFirebaseAuth = (): Auth => {
  if (!auth) {
    auth = getAuth(getFirebaseApp());
  }
  return auth;
};


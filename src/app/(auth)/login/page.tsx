import { LoginForm } from './login-form';

export const dynamic = 'force-dynamic';

export default function LoginPage() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-gray-50 px-6 py-16 font-mono">
      <div className="w-full max-w-md rounded-lg border border-gray-200 bg-white p-10 shadow-sm">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-gray-900">Sign in</h1>
          <p className="mt-2 text-sm text-gray-600">
            Enter your credentials to access your account.
          </p>
        </div>
        <LoginForm />
      </div>
    </div>
  );
}

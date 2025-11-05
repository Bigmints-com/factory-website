import { RegisterForm } from './register-form';

export const dynamic = 'force-dynamic';

export default function RegisterPage() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-gray-50 px-6 py-16 font-mono">
      <div className="w-full max-w-md rounded-lg border border-gray-200 bg-white p-10 shadow-sm">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-gray-900">Create account</h1>
          <p className="mt-2 text-sm text-gray-600">
            Get started by creating your account.
          </p>
        </div>
        <RegisterForm />
      </div>
    </div>
  );
}

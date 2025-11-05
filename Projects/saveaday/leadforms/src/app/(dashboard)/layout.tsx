import { SignOutButton } from '@/components/sign-out-button';
import { NavLink } from '@/components/nav-link';
import { authOptions } from '@/lib/authOptions';
import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user) {
    redirect('/login');
  }

  return (
    <div className="flex min-h-screen w-full bg-gray-50 text-gray-900 font-mono">
      <aside className="hidden w-64 flex-col border-r border-gray-200 bg-white px-6 py-10 shadow-sm lg:flex">
        <div className="text-lg font-medium">Lead Form Platform</div>
        <nav className="mt-10 space-y-1 text-sm">
          <NavLink href="/dashboard">Overview</NavLink>
          <NavLink href="/leadforms">Lead forms</NavLink>
          <NavLink href="/integrations/webhooks">Webhooks</NavLink>
          <NavLink href="/integrations/api">API access</NavLink>
          <NavLink href="/billing">Billing</NavLink>
        </nav>
      </aside>
      <div className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4 shadow-sm">
          <div>
            <p className="text-sm text-gray-500">Signed in as</p>
            <p className="text-sm font-medium">{session.user.email}</p>
          </div>
          <SignOutButton />
        </header>
        <main className="flex-1 bg-gray-50 px-6 py-8">{children}</main>
      </div>
    </div>
  );
}

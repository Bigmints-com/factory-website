'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface NavLinkProps {
  href: string;
  children: React.ReactNode;
}

export function NavLink({ href, children }: NavLinkProps) {
  const pathname = usePathname();
  
  // Determine if the link is active
  let isActive = false;
  
  if (href === '/dashboard') {
    // Dashboard should only be active on exact match
    isActive = pathname === '/dashboard';
  } else if (href === '/leadforms/new') {
    // Create lead form should only be active on exact match
    isActive = pathname === '/leadforms/new';
  } else {
    // Other routes should be active if pathname starts with the href
    // This handles nested routes like /leadforms/[id] -> highlights "Lead forms"
    isActive = pathname === href || (pathname?.startsWith(`${href}/`) ?? false);
  }

  return (
    <Link
      href={href}
      className={`block rounded-md px-3 py-2 transition ${
        isActive
          ? 'bg-blue-50 text-blue-700 font-medium'
          : 'text-gray-700 hover:bg-gray-100'
      }`}
    >
      {children}
    </Link>
  );
}

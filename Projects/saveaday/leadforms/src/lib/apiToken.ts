import { getUserByApiToken, touchApiToken } from '@/lib/repositories/userRepository';

export const getUserForApiToken = async (
  header: string | null,
) => {
  if (!header) return null;
  const [scheme, token] = header.split(' ');
  if (!token || scheme.toLowerCase() !== 'bearer') return null;

  const user = await getUserByApiToken(token);
  if (!user) return null;
  await touchApiToken(user.id);
  return user;
};

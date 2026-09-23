import { User } from '@prisma/client';
import { PublicProfile } from '@alevi/contracts';

export type PublicUser = Pick<User, 'id' | 'displayName' | 'bio' | 'avatarUrl' | 'city' | 'createdAt'>;

export const publicProfileSelect = { id: true, displayName: true, bio: true, avatarUrl: true, city: true, createdAt: true } as const;

export function toPublicProfile(user: PublicUser): PublicProfile {
  return {
    id: user.id,
    displayName: user.displayName,
    bio: user.bio,
    avatarUrl: user.avatarUrl,
    city: user.city,
    createdAt: user.createdAt.toISOString()
  };
}

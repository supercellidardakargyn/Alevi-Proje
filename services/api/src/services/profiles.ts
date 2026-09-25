import { User } from '@prisma/client';
import { PublicProfile } from '@alevi/contracts';

export type PublicUser = Pick<User, 'id' | 'displayName' | 'bio' | 'avatarUrl' | 'photos' | 'city' | 'district' | 'interests' | 'createdAt'> & {
  invitedById?: string | null;
};

export const publicProfileSelect = {
  id: true,
  displayName: true,
  bio: true,
  avatarUrl: true,
  photos: true,
  city: true,
  district: true,
  interests: true,
  invitedById: true,
  createdAt: true
} as const;

export function toPublicProfile(
  user: PublicUser,
  context?: { myInterests?: string[]; sharedEvents?: number }
): PublicProfile {
  const mine = context?.myInterests ?? [];
  const sharedInterests = user.interests.filter((tag) => mine.includes(tag));
  return {
    id: user.id,
    displayName: user.displayName,
    bio: user.bio,
    avatarUrl: user.avatarUrl,
    photos: user.photos,
    city: user.city,
    district: user.district,
    interests: user.interests,
    referred: user.invitedById != null,
    sharedInterests,
    sharedEvents: context?.sharedEvents ?? 0,
    createdAt: user.createdAt.toISOString()
  };
}

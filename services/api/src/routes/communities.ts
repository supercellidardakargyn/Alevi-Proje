import { Router } from 'express';
import { z } from 'zod';
import { createCommunitySchema, createPostSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { decryptText, encryptText } from '../security/fields';
import { ApiError } from '../middleware/errors';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';

async function membership(prisma: PrismaClient, communityId: string, currentUserId: string) {
  return prisma.communityMember.findUnique({ where: { communityId_userId: { communityId, userId: currentUserId } } });
}

async function accessibleCommunity(prisma: PrismaClient, communityId: string, currentUserId: string) {
  const [community, member] = await Promise.all([
    prisma.community.findUnique({ where: { id: communityId } }),
    membership(prisma, communityId, currentUserId)
  ]);
  const found = notFoundIfNull(community, 'Community');
  if (found.visibility === 'PRIVATE' && !member) {
    throw new ApiError(403, 'FORBIDDEN', 'Join this private community to access it');
  }
  return { community: found, member };
}

const communityPostsQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(30)
});

export function communityRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/', asyncHandler(async (req, res) => {
    const id = userId(req);
    const communities = await prisma.community.findMany({ where: { OR: [{ visibility: 'PUBLIC' }, { members: { some: { userId: id } } }] }, include: { _count: { select: { members: true, posts: true } } }, orderBy: { createdAt: 'desc' }, take: 50 });
    res.json({ data: communities.map((community) => ({ id: community.id, name: community.name, description: community.description, visibility: community.visibility, memberCount: community._count.members, postCount: community._count.posts, createdAt: community.createdAt.toISOString() })) });
  }));
  router.post('/', validate(createCommunitySchema), asyncHandler(async (req, res) => {
    const id = userId(req);
    const body = req.body as { name: string; description?: string; visibility: 'PUBLIC' | 'PRIVATE' };
    const community = await prisma.$transaction(async (tx) => {
      const created = await tx.community.create({ data: { ownerId: id, name: body.name, description: body.description, visibility: body.visibility } });
      await tx.communityMember.create({ data: { communityId: created.id, userId: id, role: 'OWNER' } });
      return created;
    });
    res.status(201).json({ data: community });
  }));
  router.get('/:id', asyncHandler(async (req, res) => {
    const id = routeParam(req, 'id');
    const currentUserId = userId(req);
    const community = notFoundIfNull(
      await prisma.community.findUnique({
        where: { id },
        include: { _count: { select: { members: true, posts: true } } }
      }),
      'Community'
    );
    if (community.visibility === 'PRIVATE') {
      const member = await prisma.communityMember.findUnique({
        where: { communityId_userId: { communityId: community.id, userId: currentUserId } }
      });
      if (!member) throw new ApiError(403, 'FORBIDDEN', 'Join this private community to access it');
    }
    res.json({ data: { id: community.id, name: community.name, description: community.description, visibility: community.visibility, memberCount: community._count.members, postCount: community._count.posts, createdAt: community.createdAt.toISOString() } });
  }));
  router.post('/:id/join', asyncHandler(async (req, res) => {
    const id = userId(req);
    const communityId = routeParam(req, 'id');
    const community = notFoundIfNull(await prisma.community.findUnique({ where: { id: communityId }, select: { id: true, visibility: true } }), 'Community');
    if (community.visibility === 'PRIVATE') throw new ApiError(403, 'INVITE_REQUIRED', 'This community is private');
    const member = await prisma.communityMember.upsert({ where: { communityId_userId: { communityId, userId: id } }, create: { communityId, userId: id }, update: {} });
    res.status(201).json({ data: { communityId: member.communityId, role: member.role } });
  }));
  router.get('/:id/posts', validate(communityPostsQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const communityId = routeParam(req, 'id');
    const query = req.query as unknown as { limit: number };
    await accessibleCommunity(prisma, communityId, userId(req));
    const posts = await prisma.communityPost.findMany({ where: { communityId }, include: { author: { select: { id: true, displayName: true, avatarUrl: true } } }, orderBy: { createdAt: 'desc' }, take: query.limit });
    res.json({ data: posts.map((post) => ({ id: post.id, body: decryptText(post.body), createdAt: post.createdAt.toISOString(), author: post.author })) });
  }));
  router.post('/:id/posts', validate(createPostSchema), asyncHandler(async (req, res) => {
    const id = userId(req);
    const communityId = routeParam(req, 'id');
    const { member } = await accessibleCommunity(prisma, communityId, id);
    if (!member) throw new ApiError(403, 'MEMBERSHIP_REQUIRED', 'Join the community before posting');
    const post = await prisma.communityPost.create({ data: { communityId, authorId: id, body: encryptText(req.body.body) } });
    res.status(201).json({ data: { ...post, body: req.body.body } });
  }));
  return router;
}

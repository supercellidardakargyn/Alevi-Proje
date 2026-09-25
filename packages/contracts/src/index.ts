import { z } from 'zod';

export const uuidSchema = z.string().uuid();
export const emailSchema = z.string().trim().toLowerCase().email().max(320);
export const passwordSchema = z.string().min(12).max(128);
export const displayNameSchema = z.string().trim().min(2).max(80);

const sensitivePayloadSchema = z.record(z.string().max(80), z.unknown()).superRefine((value, context) => {
  if (JSON.stringify(value).length > 16_384) {
    context.addIssue({ code: z.ZodIssueCode.too_big, maximum: 16_384, type: 'string', inclusive: true, message: 'Sensitive payload is too large' });
  }
});

export const registerRequestSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  displayName: displayNameSchema,
  consentVersion: z.string().trim().min(1).max(32),
  ageConfirmed: z.literal(true, {
    errorMap: () => ({ message: '18+ confirmation is required' }),
  }),
  inviteCode: z.string().trim().min(4).max(12).optional(),
  interests: z.array(z.string().trim().min(1).max(30)).max(10).optional(),
  sensitivePayload: sensitivePayloadSchema.optional()
});

export const loginRequestSchema = z.object({
  email: emailSchema,
  password: passwordSchema
});

export const refreshRequestSchema = z.object({
  refreshToken: z.string().min(32).max(4096)
});

export const logoutRequestSchema = z.object({
  refreshToken: z.string().min(32).max(4096).optional()
});

export const updateProfileRequestSchema = z.object({
  displayName: displayNameSchema.optional(),
  bio: z.string().trim().max(2000).nullable().optional(),
  avatarUrl: z.string().url().max(2048).nullable().optional(),
  city: z.string().trim().max(120).nullable().optional(),
  latitude: z.number().min(-90).max(90).nullable().optional(),
  longitude: z.number().min(-180).max(180).nullable().optional(),
  interests: z.array(z.string().trim().min(1).max(30)).max(10).optional(),
  photos: z.array(z.string().url().max(2048)).max(6).optional(),
  sensitivePayload: sensitivePayloadSchema.nullable().optional()
}).strict();

export const discoverQuerySchema = z.object({
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  q: z.string().trim().max(80).optional(),
  city: z.string().trim().max(120).optional(),
  latitude: z.coerce.number().min(-90).max(90).optional(),
  longitude: z.coerce.number().min(-180).max(180).optional(),
  maxDistanceKm: z.coerce.number().min(1).max(20000).optional()
});

export const createMatchRequestSchema = z.object({
  userId: uuidSchema,
  decision: z.enum(['LIKE', 'PASS']).default('LIKE')
});

export const matchActionSchema = z.object({
  decision: z.enum(['ACCEPT', 'REJECT'])
});

export const blockRequestSchema = z.object({
  userId: uuidSchema
});

export const reportRequestSchema = z.object({
  userId: uuidSchema.optional(),
  messageId: uuidSchema.optional(),
  reason: z.enum(['HARASSMENT', 'HATE', 'SPAM', 'SAFETY', 'OTHER']),
  details: z.string().trim().max(2000).optional()
}).refine((value) => value.userId || value.messageId, { message: 'userId or messageId is required' });

export const createCommunitySchema = z.object({
  name: z.string().trim().min(2).max(120),
  description: z.string().trim().max(2000).optional(),
  visibility: z.enum(['PUBLIC', 'PRIVATE']).default('PUBLIC')
});

export const createPostSchema = z.object({
  body: z.string().trim().min(1).max(10_000)
});

export const createConversationSchema = z.object({
  participantIds: z.array(uuidSchema).min(1).max(50),
  title: z.string().trim().max(120).optional()
});

export const createMessageSchema = z.object({
  body: z.string().trim().min(1).max(10_000),
  clientMessageId: z.string().trim().max(128).optional()
});

export const suspendUserRequestSchema = z.object({
  reason: z.string().trim().min(3).max(2000),
});

export const resolveReportRequestSchema = z.object({
  action: z.enum(['dismiss', 'remove', 'suspend']),
  note: z.string().trim().max(2000).optional(),
});

export const createEdgeNodeRequestSchema = z.object({
  name: z.string().trim().min(2).max(80),
  meshHost: z.string().trim().min(1).max(255),
  meshPort: z.coerce.number().int().min(1).max(65535),
});

export const edgeHeartbeatRequestSchema = z.object({
  token: z.string().min(32).max(512),
});

export const googleRequestSchema = z.object({
  idToken: z.string().min(32).max(8192),
  displayName: displayNameSchema.optional(),
  consentVersion: z.string().trim().min(1).max(32),
  ageConfirmed: z.literal(true, {
    errorMap: () => ({ message: '18+ confirmation is required' }),
  }),
});

export const verifyEmailRequestSchema = z.object({
  email: emailSchema,
  code: z.string().trim().regex(/^\d{6}$/, 'Verification code must be 6 digits'),
});

export const resendCodeRequestSchema = z.object({
  email: emailSchema,
});

export const forgotPasswordRequestSchema = z.object({
  email: emailSchema,
});

export const resetPasswordRequestSchema = z.object({
  email: emailSchema,
  code: z.string().trim().regex(/^\d{6}$/, 'Verification code must be 6 digits'),
  newPassword: passwordSchema,
});

export const createEventRequestSchema = z.object({
  title: z.string().trim().min(2).max(120),
  description: z.string().trim().max(2000).optional(),
  city: z.string().trim().max(120).optional(),
  startsAt: z.string().datetime(),
});

export const deviceTokenRequestSchema = z.object({
  token: z.string().trim().min(10).max(255),
  platform: z.enum(['android', 'ios', 'windows']).default('android'),
});

export const createTicketRequestSchema = z.object({
  subject: z.string().trim().min(3).max(120),
  body: z.string().trim().min(10).max(2000),
});

export const replyTicketRequestSchema = z.object({
  message: z.string().trim().min(1).max(2000),
});

export type RegisterRequest = z.infer<typeof registerRequestSchema>;
export type LoginRequest = z.infer<typeof loginRequestSchema>;
export type RefreshRequest = z.infer<typeof refreshRequestSchema>;
export type UpdateProfileRequest = z.infer<typeof updateProfileRequestSchema>;
export type DiscoverQuery = z.infer<typeof discoverQuerySchema>;
export type CreateMatchRequest = z.infer<typeof createMatchRequestSchema>;
export type PublicProfile = {
  id: string;
  displayName: string;
  bio: string | null;
  avatarUrl: string | null;
  photos: string[];
  city: string | null;
  interests: string[];
  referred: boolean;
  sharedInterests: string[];
  sharedEvents: number;
  createdAt: string;
};

export type ApiErrorBody = {
  error: {
    code: string;
    message: string;
    requestId?: string;
    details?: unknown;
  };
};

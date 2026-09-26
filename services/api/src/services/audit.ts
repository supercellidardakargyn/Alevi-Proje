import { PrismaClient } from '@prisma/client';

export interface AuditEntry {
  actorId?: string;
  action: string;
  targetType: string;
  targetId?: string;
  reason?: string;
  metadata?: Record<string, unknown>;
}

/** Denetim izni yazar; yazilamazsa uyari verir ama akisi bozmaz. */
export async function writeAudit(prisma: PrismaClient, entry: AuditEntry): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        actorId: entry.actorId,
        action: entry.action,
        targetType: entry.targetType,
        targetId: entry.targetId,
        reason: entry.reason,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        metadata: (entry.metadata ?? undefined) as any
      }
    });
  } catch {
    // Audit kaybi gorunmez olmamali.
    console.warn(`[audit] yazilamadi: ${entry.action} -> ${entry.targetType}/${entry.targetId ?? '-'}`);
  }
}

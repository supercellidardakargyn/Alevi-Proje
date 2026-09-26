import { PrismaClient } from '@prisma/client';
import { config } from '../config';
import { decryptText } from '../security/fields';
import { writeAudit } from './audit';

/**
 * Reflex moderasyon (Jev / TypeSafe System One).
 *
 * Sohbet modelinden farkli calisir: metin uretmez, tek istekte paralel
 * sorulara yapiilandirilmis puan/sinif/olasilik doner. Bu yuzden hizli ve
 * ucuzdur; sikayet triyaji icin kullanilir.
 *
 * Kendi hizli kuyrugu vardir (sohbet FIFO'sundan bagimsiz): ayni anda en
 * fazla 2 istek, istekler arasi en az 100ms, istek basina 12sn zaman asimi.
 * Kapaliysa veya anahtar yoksa her sey null doner, akis kilitlenmez.
 */

const MAX_CONCURRENCY = 2;
const REQUEST_GAP_MS = 100;
const REQUEST_TIMEOUT_MS = 12_000;
const MAX_STATE_CHARS = 1500;

/** Ciddiyet olcegi: 0 zararsiz, 4 acil tehlike. */
export type Severity = 0 | 1 | 2 | 3 | 4;

export interface ReflexVerdict {
  severity: Severity;
  severityConfidence: number;
  category: string;
  actionable: number;
}

export type ReflexDecision = 'auto-suspend' | 'prioritize' | 'none';

function reflexReady(): boolean {
  const { enabled, apiKey, model } = config.reflex;
  return Boolean(enabled && apiKey && model);
}

// --- Hizli kuyruk (es-zamanlilik sinirli, kisa bekleme) --------------------

let running = 0;
let lastFinishedAt = 0;
const waiting: Array<() => void> = [];

function acquire(): Promise<void> {
  return new Promise((resolve) => {
    waiting.push(() => {
      running += 1;
      resolve();
    });
    pump();
  });
}

function pump(): void {
  if (running >= MAX_CONCURRENCY || waiting.length === 0) return;
  const wait = lastFinishedAt + REQUEST_GAP_MS - Date.now();
  if (wait > 0) {
    setTimeout(pump, wait);
    return;
  }
  const next = waiting.shift();
  if (!next) return;
  next();
  // Siradakiler icin kapiyi aralik birak (yineleme patlamamasi icin tek adim).
  if (waiting.length > 0 && running < MAX_CONCURRENCY) {
    const gap = lastFinishedAt + REQUEST_GAP_MS - Date.now();
    setTimeout(pump, Math.max(0, gap));
  }
}

function release(): void {
  running = Math.max(0, running - 1);
  lastFinishedAt = Date.now();
  pump();
}

// --- Degerlendirme ----------------------------------------------------------

interface JevAnswers {
  answers?: {
    severity?: { score?: number; confidence?: number };
    category?: { choice?: string; confidence?: number };
    actionable?: { noul?: number };
  };
}

/**
 * Sikayet metnini tek istekte 3 boyutta degerlendirir:
 * ciddiyet (0-4), kategori, mudahale gerekliligi (0-1).
 */
export async function evaluateReport(state: string): Promise<ReflexVerdict | null> {
  if (!reflexReady()) return null;
  const trimmed = state.trim().slice(0, MAX_STATE_CHARS);
  if (trimmed.length === 0) return null;
  const { apiUrl, apiKey, model } = config.reflex;
  await acquire();
  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        state: trimmed,
        model,
        questions: {
          severity: {
            type: 'score',
            instructions: 'How severe is the reported behavior',
            criteria: [
              'Harmless or false report, no violation',
              'Mild annoyance or spam, no direct harm',
              'Clear harassment, hate or repeated abuse',
              'Serious threat, sexual coercion or targeted hate campaign',
              'Immediate danger: physical violence, self-harm or child safety'
            ]
          },
          category: {
            type: 'choice',
            instructions: 'Which moderation category fits best',
            criteria: {
              harassment: 'Bullying, threats or persistent unwanted contact',
              hate: 'Slur or attack based on identity or belief',
              spam: 'Scam, advertisement or mass low-quality content',
              safety: 'Physical danger, self-harm or child safety',
              other: 'None of the above'
            }
          },
          actionable: {
            type: 'noul',
            instructions: 'A moderator must intervene on this report'
          }
        }
      }),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
    });
    if (!response.ok) {
      console.error(`[reflex] degerlendirme hatasi: ${response.status} ${model}`);
      return null;
    }
    const payload = (await response.json()) as JevAnswers;
    const answers = payload.answers;
    if (!answers) return null;
    const rawScore = Number(answers.severity?.score);
    if (!Number.isFinite(rawScore)) return null;
    const severity = Math.max(0, Math.min(4, Math.round(rawScore))) as Severity;
    return {
      severity,
      severityConfidence: Number(answers.severity?.confidence ?? 0),
      category: (answers.category?.choice ?? 'other').toString().slice(0, 32),
      actionable: Number(answers.actionable?.noul ?? 0)
    };
  } catch {
    console.error('[reflex] istek basarisiz');
    return null;
  } finally {
    release();
  }
}

/**
 * Karar kurali (saf fonksiyon, test edilebilir):
 * - auto-suspend: cok ciddi (3+) + yuksek guven + mudahale gerekli.
 *   Uygulama tarafi ayrica hedefin siradan uye oldugunu dogrular.
 * - prioritize: orta ve uzeri sikayetler moderasyon kuyrugunun basina.
 * - none: zararsiz / dusuk guven.
 */
export function decideReflex(verdict: ReflexVerdict | null): ReflexDecision {
  if (!verdict) return 'none';
  if (
    verdict.severity >= 3 &&
    verdict.severityConfidence >= 0.75 &&
    verdict.actionable >= 0.7
  ) {
    return 'auto-suspend';
  }
  if (verdict.severity >= 2 || verdict.actionable >= 0.6) {
    return 'prioritize';
  }
  return 'none';
}

// --- Sikayet triyaji --------------------------------------------------------
// Rapor acildiktan sonra arka planda calisir, yaniti geciktirmez.

/**
 * Raporu degerlendirir, sonucu satira yazar ve karara gore aksiyon alir:
 * - auto-suspend: hedef siradan uyeyse hesabi kapatir (denetim izli),
 *   raporu cozulmus sayar. Yonetici/moderator ve silinmis hesaplara dokunmaz.
 * - prioritize: raporu REVIEWING yapar, moderasyon kuyrugunun basina gecer.
 * Jev kapaliysa veya sonuc alinamazsa rapor OPEN kalir (mevcut akis).
 */
export async function triageReport(prisma: PrismaClient, reportId: string): Promise<void> {
  const report = await prisma.report.findUnique({
    where: { id: reportId },
    include: {
      reported: { select: { id: true, role: true, deletedAt: true } },
      message: { select: { id: true, body: true, senderId: true } }
    }
  });
  if (!report || report.status !== 'OPEN') return;

  const parts = [`Sebep: ${report.reason}`];
  if (report.details) {
    const details = decryptText(report.details).trim();
    if (details) parts.push(`Detay: ${details}`);
  }
  if (report.message) {
    const body = decryptText(report.message.body).trim().slice(0, 800);
    if (body) parts.push(`Sikayet edilen mesaj: ${body}`);
  }
  const verdict = await evaluateReport(parts.join('\n'));
  if (!verdict) return;

  await prisma.report.update({
    where: { id: report.id },
    data: { severity: verdict.severity, evalCategory: verdict.category }
  });

  const decision = decideReflex(verdict);
  if (decision === 'prioritize') {
    await prisma.report.update({
      where: { id: report.id },
      data: { status: 'REVIEWING', autoAction: 'prioritize' }
    });
    return;
  }
  if (decision !== 'auto-suspend') return;

  // Oto-yasak: sadece hedef belliyse ve siradan aktif uyeseyse.
  const targetId = report.reported?.id ?? (report.message && report.message.senderId !== report.reporterId ? report.message.senderId : null);
  if (!targetId) return;
  const target =
    report.reported?.id === targetId
      ? report.reported
      : await prisma.user.findUnique({ where: { id: targetId }, select: { id: true, role: true, deletedAt: true } });
  if (!target || target.deletedAt || target.role !== 'USER') return;

  await prisma.$transaction([
    prisma.user.update({ where: { id: target.id }, data: { deletedAt: new Date() } }),
    prisma.report.update({ where: { id: report.id }, data: { status: 'RESOLVED', autoAction: 'suspend' } })
  ]);
  await writeAudit(prisma, {
    action: 'user.suspend',
    targetType: 'user',
    targetId: target.id,
    reason: `Reflex oto-moderasyon: siddet ${verdict.severity}/4 (${verdict.category})`,
    metadata: { actor: 'reflex', reportId: report.id, severity: verdict.severity, confidence: verdict.severityConfidence }
  });
}

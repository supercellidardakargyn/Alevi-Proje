import { config } from '../config';

/**
 * Can Meydani yapay zeka katmani (Vercel AI Gateway / OpenAI uyumlu API).
 *
 * Kurallar:
 * - AI_ENABLED=false veya API_KEY/MODEL bos ise hicbir istek atilmaz, null doner.
 * - Tum istekler tek bir FIFO kuyrugundan gecer: ayni anda en fazla 1 istek,
 *   istekler arasi en az 1500ms bekleme, istek basina 30sn zaman asimi.
 * - Ggomulu senaryo kutuphaneleri (bkz. SCENARIOS) modele gonderilmeden once
 *   calistirilir; hizli ve bedava olan yollarda model hic cagrilmaz.
 * - Hata durumunda surekli null doner, istemci cokmez.
 */

const REQUEST_GAP_MS = 1500;
const REQUEST_TIMEOUT_MS = 30_000;
const MAX_OUTPUT_CHARS = 2000;
const MAX_INPUT_CHARS = 1200;

function aiReady(): boolean {
  const { enabled, apiKey, model } = config.ai;
  return Boolean(enabled && apiKey && model);
}

/** Sirali kuyruk: tek istek ayni anda, aralarinda bekleme payi ile. */
let tail: Promise<unknown> = Promise.resolve();
let lastFinishedAt = 0;

async function enqueue<T>(job: () => Promise<T>): Promise<T> {
  const run = tail.then(async () => {
    const wait = lastFinishedAt + REQUEST_GAP_MS - Date.now();
    if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait));
    try {
      return await job();
    } finally {
      lastFinishedAt = Date.now();
    }
  });
  // Kuyrugun bir sonraki isi bloklamamasi icin hata izolasyonu.
  tail = run.then(
    () => undefined,
    () => undefined
  );
  return run;
}

/** Ortak sohrugu tamamlama cagrisi. Hata/bos ciktida null doner. */
async function chatComplete(system: string, user: string, maxTokens: number): Promise<string | null> {
  if (!aiReady()) return null;
  const { apiUrl, apiKey, model } = config.ai;
  try {
    const response = await fetch(`${apiUrl}/chat/completions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        temperature: 0.7,
        max_tokens: maxTokens,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user.slice(0, MAX_INPUT_CHARS * 6) }
        ]
      }),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
    });
    if (!response.ok) {
      console.error(`[ai] model hatasi: ${response.status} ${model}`);
      return null;
    }
    const payload = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
    const text = payload.choices?.[0]?.message?.content?.trim() ?? '';
    return text.length > 0 ? text.slice(0, MAX_OUTPUT_CHARS) : null;
  } catch {
    console.error('[ai] istek basarisiz');
    return null;
  }
}

function cleanLine(line: string): string {
  return line
    .replace(/^[\s\-*•\d.)]+/, '')
    .replace(/^["'\u201c\u2018]|["'\u201d\u2019]$/g, '')
    .trim();
}

/** Model ciktisindan "her satir bir oneri" listesini cikarir. */
function toList(text: string, limit: number): string[] {
  return text
    .split('\n')
    .map(cleanLine)
    .filter((line) => line.length > 3 && line.length <= 140)
    .filter((line, index, all) => all.indexOf(line) === index)
    .slice(0, limit);
}

// ---------------------------------------------------------------------------
// Gomulu senaryo kutuphaneleri (model cagrisina gerekmeden aninda sonuc)
// ---------------------------------------------------------------------------

/** Sohbet son mesajina gore hazir ilk/yeni mesaj oneri havuzu. */
const FOLLOWUP_SCENARIOS: Array<{ when: RegExp; replies: string[] }> = [
  {
    when: /(sağ\s*ol\w*|teşekkür\w*|tesekkur\w*|eyvallah)/i,
    replies: ['Rica ederim, görüşmek üzere 🙂', 'Ne demek, her zaman 🙂', 'Ben de sana iyi dileklerde bulunurum.']
  },
  {
    when: /(görüşürüz|gorusuruz|iyi günler|iyi aksamlar|iyi geceler|merhaba|selam|slm)/i,
    replies: ['Ben de merhaba, nasılsın?', 'Selam! Bugünün nasıl geçiyor?', 'Hoş geldin, nasıl gidiyor?']
  },
  {
    when: /(ne yapıyorsun|ne yapıyorsunuz|napıyorsun|napıyorsunuz)/i,
    replies: ['Seni düşünüyordum, sen nasılsın?', 'Biraz dinleniyorum, sonra bir kahve içeceğim.', 'Seni hiç sormadım, günün nasıl?']
  },
  {
    when: /(nered[e|i]|n[aı]led[e|i]n|evde mi|d[aşş]ar[iı]da m[iı])/i,
    replies: ['Aslında dışarıdayım, biraz hava alıyorum.', 'Evdeyim, sakin bir akşam.', 'Şu an dışarıda, yeni bir yer keşfediyorum.']
  },
  {
    when: /\?$/,
    replies: ['Sen ne dersin, çok merak ediyorum 🙂', 'Bence gayet iyi, sen de katılıyor musun?', 'Bu soru güzel, düşüneyim de sana döneyim.']
  }
];

const ICEBREAKER_SCENARIOS: Array<{ when: (ctx: { displayName: string; city?: string | null; interests: string[] }) => boolean; openers: (ctx: { displayName: string; city?: string | null; interests: string[] }) => string[] }> = [
  {
    when: (ctx) => ctx.interests.length > 0,
    openers: (ctx) => [
      `${ctx.interests[0]} seni ilgimi çekti, nasıl bu işe başladın?`,
      `${ctx.displayName}, ${ctx.interests[0]} konusunda bana bir şey anlatır mısın?`,
      `Merhaba ${ctx.displayName}, ${ctx.interests.slice(0, 2).join(' ve ')} ilginç görünüyor.`
    ]
  },
  {
    when: (ctx) => Boolean(ctx.city),
    openers: (ctx) => [
      `${ctx.city} güzel bir yer, orada en sevdiğin yer neresi?`,
      `${ctx.displayName}, ${ctx.city}'de yaşamak nasıl bir his?`,
      `Selam ${ctx.displayName}, ${ctx.city}'de ne yapılır iyi bilmiyorum, tavsiye verir misin?`
    ]
  },
  {
    when: () => true,
    openers: (ctx) => [
      `Merhaba ${ctx.displayName}, profilin ilgimi çekti, kendinden biraz bahseder misin?`,
      `Selam ${ctx.displayName}, nasıl bir gün geçiriyorsun?`,
      `Merhaba ${ctx.displayName}, bir kahve içmeye ne dersin?`
    ]
  }
];

const MATCH_NOTE_SCENARIOS: Array<{ when: (shared: string[], events: number) => boolean; note: (shared: string[], events: number) => string }> = [
  {
    when: (shared, events) => shared.length >= 2 && events > 0,
    note: (shared, events) => `${shared.slice(0, 2).join(' ve ')} ilgi alanlarınız ortak ve ${events} etkinlikte karşılaştınız.`
  },
  {
    when: (shared, events) => shared.length >= 2,
    note: (shared) => `${shared.slice(0, 2).join(' ve ')} ilgi alanlarınız ortak, sohbetiniz için güzel bir başlangıç.`
  },
  {
    when: (shared, events) => events > 0,
    note: (_shared, events) => `${events} etkinlikte birlikte olmuşsunuz, tanışıklığınızın üstüne koyun.`
  },
  {
    when: (shared) => shared.length === 1,
    note: (shared) => `${shared[0]} ilgi alanınız ortak, sohbet oradan başlayabilir.`
  },
  {
    when: () => true,
    note: () => 'Henüz ortak ilgi alanınız yok; profiline bakarak bir başlangıç cümlesi kurabilirsin.'
  }
];

// ---------------------------------------------------------------------------
// Saf senaryo fonksiyonlari (model cagrisiz, hizli, test edilebilir)
// ---------------------------------------------------------------------------

/** Son mesaja gore hazir cevap onerisi havuzundan ilk esleseni doner. */
export function scenarioSmartReplies(lastMessages: string[]): string[] | null {
  const last = lastMessages.filter(Boolean).slice(-1)[0] ?? '';
  if (last.length === 0) return null;
  const lower = last.toLowerCase();
  for (const scenario of FOLLOWUP_SCENARIOS) {
    if (scenario.when.test(lower)) return scenario.replies.slice(0, 3);
  }
  return null;
}

/** Hedef profile gore buz kirici onerisi (modele gerek yok). */
export function scenarioIcebreakers(profile: IcebreakerProfile): string[] | null {
  if (!profile.displayName) return null;
  const ctx = {
    displayName: profile.displayName,
    city: profile.city,
    interests: (profile.interests ?? []).filter(Boolean)
  };
  for (const scenario of ICEBREAKER_SCENARIOS) {
    if (scenario.when(ctx)) return scenario.openers(ctx);
  }
  return null;
}

/** Ortak ilgi alani ve etkinlige gore eslesme notu (modele gerek yok). */
export function scenarioMatchNote(sharedInterests: string[], sharedEvents: number): string | null {
  const shared = (sharedInterests ?? []).filter(Boolean);
  const events = Number.isFinite(sharedEvents) ? sharedEvents : 0;
  for (const scenario of MATCH_NOTE_SCENARIOS) {
    if (scenario.when(shared, events)) return scenario.note(shared, events);
  }
  return null;
}

// ---------------------------------------------------------------------------
// 1) Destek yanit taslagi
// ---------------------------------------------------------------------------

/**
 * Destek taleplerine yapay zeka yanit taslagi uretir.
 * Taslak dogrudan gonderilmez, yonetim onaylar.
 */
export async function draftSupportReply(subject: string, body: string): Promise<string | null> {
  if (!aiReady()) return null;
  return enqueue(() =>
    chatComplete(
      'Can Meydanı uygulamasının destek asistanısın. Türkçe, kısa ve yardımsever yanıt taslakları yaz. Yanıtı doğrudan kullanıcıya gönderilecekmiş gibi yaz, açıklama ekleme.',
      `Konu: ${subject}\nMesaj: ${body}`,
      300
    )
  );
}

// ---------------------------------------------------------------------------
// 2) Akilli yanit onerileri
// ---------------------------------------------------------------------------

/** Son mesajlara gore 3 kisa hazir cevap onerisi (satir basina bir tane). */
export async function smartReplies(lastMessages: string[]): Promise<string[] | null> {
  const recent = lastMessages.filter(Boolean).slice(-6);
  if (recent.length === 0 || !aiReady()) return null;
  // Once gomulu senaryo: aninda, bedava, tutarli.
  const scenario = scenarioSmartReplies(recent);
  if (scenario) return scenario;
  const text = await enqueue(() =>
    chatComplete(
      'Sen Can Meydanı adına kısa Türkçe mesaj öneriyorsun. Her satıra tam olarak bir öneri yaz, 3 satır, sadece mesaj metni, numara yok, tırnak yok.',
      `Sohbet:\n${recent.map((line) => `- ${line}`).join('\n')}\nSon mesaja uygun 3 kısa cevap öner.`,
      120
    )
  );
  const list = text ? toList(text, 3) : [];
  return list.length > 0 ? list : null;
}

// ---------------------------------------------------------------------------
// 3) Buz kirici (icebreaker) onerileri
// ---------------------------------------------------------------------------

export interface IcebreakerProfile {
  displayName: string;
  bio?: string | null;
  city?: string | null;
  interests: string[];
}

/** Hedef profile gore 3 kisa ilk mesaj onerisi. */
export async function icebreakers(profile: IcebreakerProfile): Promise<string[] | null> {
  if (!profile.displayName || !aiReady()) return null;
  return scenarioIcebreakers(profile);
}

// ---------------------------------------------------------------------------
// 4) Bio + buz kirici koaclari
// ---------------------------------------------------------------------------

/** Bio metnini duzeltir ve 2 kisa ipucu ekler. */
export async function coachBio(bio: string): Promise<string | null> {
  const text = bio.trim();
  if (!aiReady()) return null;
  if (text.length < 20) {
    return [
      'Öneri: Bio biraz daha açıklayıcı olabilir.',
      'Eklemen gerekenler: 1 cümle tanıtım + 2 cümle ilgi alanı.',
      'Kötü: “Merhaba :)” · İyi: “Ankara’da yaşıyorum, hafta sonları doğa yürüyüşü yapıyorum, film ve müzikle geçen biriyim.”'
    ].join('\n');
  }
  return enqueue(() =>
    chatComplete(
      'Sen Can Meydanı profil biografisi-editörüsün. Türkçe yaz. Önce tek paragraf hâlinde düzeltilmiş biyoyu ver (maks 2 cümle, doğal, emojisiz). Sonra “İpuçları:” satırıyla 2 kısa cümle ipucu ekle. Başka açıklama yapma.',
      `Mevcut bio: ${text}`,
      220
    )
  );
}

// ---------------------------------------------------------------------------
// 5) Sohbet ozeti
// ---------------------------------------------------------------------------

/** Sohbeti en fazla 3 cumleyle ozetler. */
export async function summarizeChat(messages: string[]): Promise<string | null> {
  const text = messages.filter(Boolean).slice(-50);
  if (text.length === 0 || !aiReady()) return null;
  if (text.length < 4) return 'Henüz özetlenecek kadar mesaj yok.';
  return enqueue(() =>
    chatComplete(
      'Sohbet özetçisisin. Türkçe, en fazla 3 cümle yaz. Gündelik konuşmalarda notlar hâlinde özetle, gereksiz tekrar etme.',
      `Mesajlar (en yeniden eskiye):\n${text.slice(-30).map((line) => `- ${line}`).join('\n')}`,
      200
    )
  );
}

// ---------------------------------------------------------------------------
// 6) Akilli eslesme notu
// ---------------------------------------------------------------------------

/** Ortak ilgi alanlarina gore tek cumlelik "neden eslestiniz" notu. */
export async function matchNote(sharedInterests: string[], sharedEvents: number): Promise<string | null> {
  if (!aiReady()) return null;
  return scenarioMatchNote(sharedInterests, sharedEvents);
}

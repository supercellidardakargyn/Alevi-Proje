import { config } from '../config';

/**
 * Destek taleplerine yapay zeka yanit taslagi uretir (OpenAI uyumlu API).
 * Vercel AI Gateway varsayilan ucur; AI_ENABLED=true + AI_API_KEY + AI_MODEL
 * verilmeden calismaz. Taslak dogrudan gonderilmez, yonetim onaylar.
 */
export async function draftSupportReply(subject: string, body: string): Promise<string | null> {
  const { enabled, apiUrl, apiKey, model } = config.ai;
  if (!enabled || !apiKey || !model) return null;
  try {
    const response = await fetch(`${apiUrl}/chat/completions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        temperature: 0.3,
        max_tokens: 300,
        messages: [
          {
            role: 'system',
            content: 'Can Meydanı uygulamasının destek asistanısın. Türkçe, kısa ve yardımsever yanıt taslakları yaz. Yanıtı doğrudan kullanıcıya gönderilecekmiş gibi yaz, açıklama ekleme.'
          },
          { role: 'user', content: `Konu: ${subject}\nMesaj: ${body}` }
        ]
      }),
      signal: AbortSignal.timeout(25_000)
    });
    if (!response.ok) {
      console.error(`[ai] taslak uretilemedi: ${response.status}`);
      return null;
    }
    const payload = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
    const text = payload.choices?.[0]?.message?.content?.trim() ?? '';
    return text.length > 0 ? text.slice(0, 2000) : null;
  } catch {
    console.error('[ai] taslak uretilemedi');
    return null;
  }
}

import { createTransport, type Transporter } from 'nodemailer';
import { config } from '../config';

let transporter: Transporter | null = null;

function getTransporter(): Transporter | null {
  if (!config.smtp.host || !config.smtp.user || !config.smtp.pass) return null;
  if (!transporter) {
    transporter = createTransport({
      host: config.smtp.host,
      port: config.smtp.port,
      secure: config.smtp.port === 465,
      auth: { user: config.smtp.user, pass: config.smtp.pass }
    });
  }
  return transporter;
}

export async function sendVerificationEmail(to: string, code: string): Promise<boolean> {
  const transport = getTransporter();
  if (!transport) {
    // Uretimde SMTP zorunlu oldugundan buraya dusulmez; gelistirmede kod
    // yalnizca acik opt-in ile loglanir (ALLOW_DEV_MAIL_LOG=1).
    if (config.nodeEnv !== 'production' && process.env.ALLOW_DEV_MAIL_LOG === '1') {
      console.log(`[dev] dogrulama kodu ${to}: ${code}`);
    }
    return false;
  }
  try {
    await transport.sendMail({
      from: config.smtp.from,
      to,
      subject: 'Can Meydanı — e-posta doğrulama kodun',
      text: `Merhaba,\n\nCan Meydanı hesabını doğrulamak için kodun: ${code}\n\nBu kod 10 dakika geçerli. Sen istemediysen bu e-postayı görmezden gel.\n\nSevgiler,\nCan Meydanı ekibi`,
      html: `<p>Merhaba,</p><p>Can Meydanı hesabını doğrulamak için kodun: <strong style="font-size:22px;letter-spacing:4px">${code}</strong></p><p>Bu kod 10 dakika geçerli. Sen istemediysen bu e-postayı görmezden gel.</p><p>Sevgiler,<br>Can Meydanı ekibi</p>`
    });
    return true;
  } catch {
    console.error('[mail] dogrulama e-postasi gonderilemedi');
    return false;
  }
}

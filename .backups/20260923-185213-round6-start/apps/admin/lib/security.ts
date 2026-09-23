export type SecurityNoteTone = "good" | "warning" | "critical";

export interface AdminSecurityNote {
  title: string;
  description: string;
  tone: SecurityNoteTone;
}

/**
 * Bu liste arayüz hatırlatıcısıdır; gerçek güvenlik sınırı API ve kimlik
 * sağlayıcı tarafından uygulanır. UI'daki görünürlük kontrollerine güvenilmez.
 */
export const adminSecurityNotes: AdminSecurityNote[] = [
  {
    title: "MFA ve kısa oturum",
    description: "Yönetici girişi MFA zorunlu, HttpOnly/Secure oturum çerezi ve kısa idle timeout ile korunur.",
    tone: "good"
  },
  {
    title: "Sunucu tarafı RBAC",
    description: "Rol ve amaç kontrolü her istekte API tarafından uygulanır; butonu gizlemek yetkilendirme değildir.",
    tone: "good"
  },
  {
    title: "Hassas veri maskesi",
    description: "Dini/kültürel alanlar ve iletişim bilgileri varsayılan olarak maskelidir; gereksiz veri çekilmez.",
    tone: "warning"
  },
  {
    title: "Değiştirilemez denetim izi",
    description: "Suspend, silme, dışa aktarma ve erişim olayları kullanıcı, amaç ve zaman bilgisiyle audit log'a yazılır.",
    tone: "good"
  },
  {
    title: "Token saklama yasağı",
    description: "Access token localStorage/sessionStorage'a yazılmaz. İstemci yalnızca güvenli oturum çerezi ve CSRF akışı kullanır.",
    tone: "critical"
  }
];

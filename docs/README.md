# Alevi dağıtım ve yönetişim dokümanları

Bu klasör, sunucu kurulumu, güvenli mesh dağıtımı, mağaza sürümleri, güvenlik, KVKK veri envanteri ve moderasyon ilkelerini içerir.

- [Kurulum](./install.md)
- [Mesh dağıtımı](./mesh-deployment.md)
- [Mağaza sürümü](./store-release.md)
- [Güvenlik modeli](./security-model.md)
- [KVKK veri haritası](./kvkk-data-map.md)
- [Moderasyon politikası](./moderation-policy.md)

## Kapsam ve sorumluluk

Bu dokümanlar operasyonel bir başlangıç noktasıdır; hukuki görüş, bağımsız güvenlik denetimi veya mağaza onayı yerine geçmez. Üretime çıkmadan önce veri sorumlusu, hukuk danışmanı, DPO/uyum sorumlusu ve güvenlik ekibi tarafından onaylanmalıdır.

Gerçek secret, özel anahtar, sertifika, kişisel veri veya yedek bu repoya konmaz. CI, zorunlu imzalama secret'ları eksikse açık hata ile durur ve sahte/sözde release artifact'i üretmez.

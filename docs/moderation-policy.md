# Moderasyon politikası

## Amaç ve ilkeler

Amaç; Alevi topluluğunda güvenli, saygılı ve ayrımcılık karşıtı bir alan korumaktır. Moderasyon:

- davranışa ve içeriğe odaklanır, kimlik veya inanç varsayımına değil;
- tutarlı, orantılı, açıklanabilir ve mümkün olduğunda geri alınabilir olur;
- hassas kültürel/dini bilgileri görünürlük veya sıralama avantajına dönüştürmez;
- raporlayan kişiyi misillemeden korur;
- karar, erişim ve itiraz kayıtlarını audit'e yazar.

Bu metin hukuki tavsiye değildir; yerel hukuk, platform kuralları ve insan güvenliği uzmanlığıyla birlikte uygulanır.

## İhlal sınıfları

### Seviye 0 — izin verilen içerik

Kişisel görüş, kültürel paylaşım, karşılıklı rıza içindeki flört/iletişim ve iyi niyetli anlaşmazlık. Eleştiri, tehdit veya hedef göstermeye dönüşmediği sürece kaldırılmaz.

### Seviye 1 — düşük zarar / kural ihlali

Spam, tekrarlı istenmeyen ileti, yanıltıcı profil detayı, düşük yoğunluklu hakaret veya topluluk akışını bozan içerik. Uyarı, görünürlük azaltma, içerik düzeltme veya geçici kısıt uygulanabilir.

### Seviye 2 — ciddi ihlal

Taciz, nefret/ayrımcılık, doxxing, rıza dışı cinsel içerik, tehdit iması, dolandırıcılık, şantaj, çocuk güvenliği riski veya koordineli abuse. İçerik/hesap kısıtlanır, kanıt korunur ve gerekli escalation yapılır.

### Seviye 3 — acil güvenlik

Yakın ve inandırıcı fiziksel zarar tehdidi, çocuk istismarı materyali, kendine zarar için acil risk, organize suç/şiddet veya hesap/altyapı saldırısı. Erişim derhal kesilebilir; güvenlik, hukuk ve gerekli acil kanallar devreye alınır. Hayati riskte platformun acil durum prosedürü izlenir.

## İş akışı

1. Rapor; kategori, hedef, kaynak ve kullanıcı açıklamasıyla alınır. Tekrarlı spam dedup edilir.
2. Otomasyon yalnız önceliklendirme ve güvenli ön filtre için kullanılır; nihai ağır yaptırım için insan incelemesi ve gerekçe gerekir.
3. Moderator, yalnız gerekli veri ve amaç için erişir; hassas alanlar maskeli kalır.
4. Kanıtın hash/request id/oluşturulma zamanı tutulur; özel mesaj içeriği rıza dışı geniş taranmaz.
5. Karar; ihlal seviyesi, politika maddesi, eylem, süre, gerekçe ve reviewer ile audit edilir.
6. Hesap sahibi uygun ölçüde bilgilendirilir; güvenliği riske atan ayrıntılar paylaşılmaz.

## Eylem merdiveni

- içerik etiketleme veya kaldırma;
- uyarı ve yeniden paylaşım yönlendirmesi;
- yorum/mesaj/keşfet kısıtı;
- geçici suspend;
- kalıcı kapatma ve cihaz/session revoke;
- tehdit/çocuk güvenliği/acil durum escalation'ı.

Ceza, ihlalin şiddeti, tekrarı, hedef üzerindeki etkisi ve kötüye kullanım geçmişiyle orantılı olmalıdır. Otomatik kalıcı ban yanlış pozitifte geri alınabilir olmalıdır.

## Rapor ve itiraz

- Engelleme, raporlama ve güvenlik ayarları kolay bulunur.
- Raporlanan kişi raporlayanın kimliğini görmez.
- İtiraz bağımsız veya ikinci bir reviewer tarafından değerlendirilir.
- İtirazda yeni kanıt, karar gerekçesi ve süre sınırı tutulur.
- Moderator kararı ile admin override'ı ayrı event olarak audit edilir; sessizce silme yapılmaz.
- Kötü niyetli toplu raporlar abuse olarak ele alınır, ancak gerçek raporları susturmak için kullanılmaz.

## Hassasiyetler ve güvenlik

Alevi kimliği/doğrulaması zorunlu değildir. Dini/kültürel beyanlar admin panelinde maskeli, public API'de amaç dışı kapalı, keşfetme sıralamasında kullanılmaz. Kimlik veya inanç temelinde hedef gösterme, nefret ve ayrımcılık ciddi ihlaldir; ancak kültürel tartışmanın kendisi otomatik ihlal sayılmaz.

Fotoğraf ve medya kaldırılmadan önce retention ve itiraz ihtiyacı değerlendirilir. EXIF ve konum bilgisi temizlenir. Moderator erişimi MFA, least privilege ve davranış analitiğiyle izlenir.

## Ölçüm ve gözden geçirme

Aylık olarak yanlış pozitif/negatif, itiraz sonuçları, kategori bazında çözüm süresi, tekrarlı abuse ve grup etkileri incelenir. Demografik veya hassas alanlar yalnız hukuken gerekli, anonim/toplulaştırılmış ve güvenli amaçla ölçülür; kullanıcıları fişlemek için kullanılmaz. Politika değişikliği, eğitim ve sürüm notuyla duyurulur.

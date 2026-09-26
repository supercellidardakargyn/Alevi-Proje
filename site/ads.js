// Can Meydanı - AdSense iskeleti (site reklamları).
//
// Bu dosya sunucudan sunulur ve sadece YAYINCI KİMLİĞİ tanımlıysa çalışır.
// Kimlik girilene kadar hiçbir şey yüklemez, sayfayı yavaşlatmaz.
//
// Nasıl açılır:
//   1) AdSense hesabını onayla (https://www.google.com/adsense).
//   2) Aşağıdaki CAĞRıYI kendi yayıncı kimliğinle değiştir (ca-pub-XXXXXXXXXXXXXXXX).
//   3) /ads.txt dosyasındaki satırı da aynı kimlikle güncelle.
//      (AdSense paneli üretir; elle de yazılabilir.)
// AdSense etiketi yalnızca içerik sayfalarında (indirme/gizlilik/KVKK gibi
// düşük trafikli sayfalarda) kullanılmamalıdır; ana sayfa uygundur.
(function () {
  'use strict';

  var PUBLISHER_ID = 'ca-pub-8250637076614354';
  var SLOT_ID = ''; // TODO: AdSense panelinde Reklamlar > Reklam birimi olustur, ID'yi buraya yaz.

  // Kimlik girilmediyse sessizce cik.
  if (!PUBLISHER_ID || !SLOT_ID) return;

  var script = document.createElement('script');
  script.async = true;
  script.crossOrigin = 'anonymous';
  script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + PUBLISHER_ID;
  document.head.appendChild(script);

  document.addEventListener('DOMContentLoaded', function () {
    var main = document.querySelector('main');
    if (!main) return;

    var ins = document.createElement('ins');
    ins.className = 'adsbygoogle';
    ins.style.display = 'block';
    ins.style.margin = '24px auto';
    ins.style.maxWidth = '970px';
    ins.setAttribute('data-ad-client', PUBLISHER_ID);
    ins.setAttribute('data-ad-slot', SLOT_ID);
    ins.setAttribute('data-ad-format', 'auto');
    ins.setAttribute('data-full-width-responsive', 'true');

    var marker = document.createElement('p');
    marker.className = 'eyebrow';
    marker.textContent = 'Reklam';

    main.insertBefore(ins, main.firstChild);
    main.insertBefore(marker, ins);

    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch (e) {
      /* reklam yuklenemezse sayfa calismaya devam eder */
    }
  });
})();

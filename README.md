# Masraf Paylaş (iOS)

Android sürümünün birebir iOS karşılığı: seyahatler, para birimi seçimi (TRY, EUR, USD, GBP, JPY, Diğer),
masraf girişi, kaydet ve kapat, aynı hesaplama yöntemi. SwiftUI ile yazıldı; iOS / iPadOS 17 ve üzeri.
Veriler yalnızca cihazda saklanır (uygulamanın Belgeler klasöründe `trips.json`).

`MasrafPaylas.swiftpm` bir **uygulama paketidir**: Mac'te Xcode ile, iPad'de Swift Playgrounds ile doğrudan açılır.

## Mac + Xcode ile iPhone'a yükleme (ücretsiz)

1. Mac App Store'dan **Xcode**'u kurun.
2. `MasrafPaylas.swiftpm` klasörüne çift tıklayın; Xcode'da açılır.
3. Xcode → **Settings → Accounts** bölümünden Apple hesabınızla giriş yapın (ücretsiz hesap yeterli).
4. Sol üstte proje adına tıklayın → **Signing & Capabilities** → **Team** olarak kendi hesabınızı seçin.
   "Bundle Identifier zaten kullanılıyor" uyarısı çıkarsa `com.masraf.paylas` yerine kendinize özgü bir ad yazın
   (örn. `com.adiniz.masrafpaylas`).
5. iPhone'u kabloyla Mac'e bağlayın, telefonda "Bu bilgisayara güven" deyin.
6. iPhone'da **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu**'nu açın (telefon yeniden başlar).
7. Xcode'da üstteki cihaz listesinden iPhone'unuzu seçip **▶ Run**'a basın.
8. İlk açılışta "Güvenilmeyen Geliştirici" uyarısı çıkarsa: **Ayarlar → Genel → VPN ve Cihaz Yönetimi** →
   Apple hesabınız → **Güven**.

> Ücretsiz Apple hesabıyla yüklenen uygulama **7 gün** sonra açılmaz hale gelir; verileriniz silinmez.
> Telefonu Mac'e bağlayıp Xcode'da tekrar **Run**'a basmanız yeterli.
> Ücretli Apple Developer Program üyeliğinde bu süre 1 yıldır.

## iPad'de (Mac olmadan)

1. App Store'dan **Swift Playgrounds**'u kurun.
2. `MasrafPaylas.swiftpm` klasörünü iCloud Drive / Dosyalar ile iPad'e aktarın ve Swift Playgrounds'ta açın.
3. **▶ Çalıştır**'a basın. Uygulama iPad'de çalışır (iPhone'a bu yolla aktarılamaz).

## Dosyalar

```
MasrafPaylas.swiftpm/
├── Package.swift            Uygulama tanımı (ad, simge, renk, iOS 17)
├── MasrafPaylasApp.swift    Uygulama girişi
├── Models.swift             Currency, Expense, Trip
├── MoneyFormat.swift        Tutar biçimlendirme / okuma, tarih biçimi
├── Calculator.swift         Hesaplama motoru (Android ile aynı)
├── TripStore.swift          Seyahatleri cihazda saklama
├── Components.swift         Kişi düğmeleri, rozetler, akışlı yerleşim
├── TripsView.swift          Seyahatlerim listesi
├── TripFormView.swift       Yeni seyahat / düzenle (başlık + para birimi)
├── TripDetailView.swift     Kişi + masraf girişi, Kaydet ve kapat, HESAPLA
└── ResultView.swift         Hesap sonucu + paylaş
```

## Hesaplama yöntemi

- Her masraf, "kimin için" seçilen kişilere eşit bölünür.
- Listede olup masrafı ödemeyen herkes, kendi payı kadar ödeyene borçlanır.
- İki kişi birbirine borçluysa borçlar mahsup edilir, net tutar gösterilir.
- Japon Yeni gibi kuruşsuz para birimlerinde tutarlar ve borçlar tam sayıya yuvarlanır.

# Look & Cook - Production Kurulum Rehberi

Bu doküman, uygulamanızı App Store ve Google Play Store'a yüklemeden önce tamamlamanız gereken adımları içerir.

## 1. Uygulama İkonu Oluşturma

### Gerekli Dosyalar
`assets/icons/` klasörüne aşağıdaki dosyaları ekleyin:

- **app_icon.png** (1024x1024 px) - Ana uygulama ikonu
- **app_icon_foreground.png** (1024x1024 px) - Android adaptive icon için foreground (şeffaf arka plan)
- **splash_logo.png** (512x512 px) - Splash screen logosu

### İkon Oluşturma Araçları
- [App Icon Generator](https://appicon.co/) - Online araç
- [Canva](https://canva.com) - Logo tasarımı
- [Figma](https://figma.com) - Profesyonel tasarım

### İkonları Uygulama
İkon dosyalarını ekledikten sonra:
```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## 2. Android Signing Key Oluşturma

### Keystore Oluşturma
```bash
keytool -genkey -v -keystore ~/lookcook-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lookcook
```

### key.properties Dosyası
`android/key.properties` dosyasını oluşturun (key.properties.example'ı kopyalayın):
```properties
storePassword=<keystore_şifreniz>
keyPassword=<key_şifreniz>
keyAlias=lookcook
storeFile=/Users/<kullanıcı>/lookcook-release-key.jks
```

**ÖNEMLİ:** `key.properties` ve `.jks` dosyalarını ASLA git'e yüklemeyin!

## 3. Release Build Oluşturma

### APK (Test için)
```bash
flutter build apk --release
```
APK konumu: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Google Play için)
```bash
flutter build appbundle --release
```
AAB konumu: `build/app/outputs/bundle/release/app-release.aab`

## 4. iOS Kurulumu

### Apple Developer Account
1. [Apple Developer Program](https://developer.apple.com/programs/)'a kaydolun
2. Xcode'da Team seçin
3. Bundle Identifier'ı günceleyin: `com.lookcook.app`

### iOS Build
```bash
flutter build ios --release
```

## 5. Store Bilgileri

### Google Play Console
- **Uygulama Adı:** Look & Cook
- **Kısa Açıklama:** Türkiye'nin en lezzetli tarif paylaşım uygulaması
- **Kategori:** Yemek ve İçecek
- **İçerik Derecelendirmesi:** Herkes için uygun

### App Store Connect
- **Uygulama Adı:** Look & Cook
- **Kategori:** Food & Drink
- **Age Rating:** 4+

## 6. Önemli Notlar

### Gizli Bilgiler
Aşağıdaki dosyaları `.gitignore`'a ekleyin:
```
android/key.properties
*.jks
*.keystore
.env
```

### Supabase ve Algolia
- Production için yeni Supabase projesi oluşturmanız önerilir
- API anahtarlarını güvenli bir şekilde saklayın
- Algolia'da üretim indeksleri oluşturun

## 7. Test Kontrol Listesi

- [ ] Giriş/kayıt işlevselliği
- [ ] Tarif ekleme ve görüntüleme
- [ ] Yorum ve puanlama
- [ ] Arama işlevselliği
- [ ] Takip sistemi
- [ ] Admin paneli (y.boranonder@gmail.com ile)
- [ ] Performans testi
- [ ] Bellek sızıntıları kontrolü

## 8. Yardımcı Komutlar

### Analiz ve Test
```bash
flutter analyze
flutter test
```

### Temizlik
```bash
flutter clean
flutter pub get
```

---

Sorularınız için: İyi kodlamalar! 🍳

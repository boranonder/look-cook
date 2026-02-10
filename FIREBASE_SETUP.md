# 🔥 Firebase Kurulum Rehberi - Look & Cook

## 📝 DURUM

Şu an iOS için Firebase yapılandırması var (`look-cook-app` projesi) ama Android eksik ve dummy data kullanılıyor.

---

## 🚀 ADIM 1: Firebase Console'a Git

1. **[Firebase Console](https://console.firebase.google.com/)** aç
2. Google hesabınla giriş yap
3. **"look-cook-app"** projesini bul

### Eğer Proje YOKSA:
- **"Add project"** → İsim ver: `look-cook-app`
- Google Analytics → Şimdilik kapat
- **Create project** → Bekle (30 saniye)

---

## 🔧 ADIM 2: FlutterFire CLI Kurulum

Terminal'de şu komutları çalıştır:

```bash
# Firebase CLI kur (bir kere)
curl -sL https://firebase.tools | bash

# Firebase'e login ol
firebase login

# FlutterFire CLI kur (bir kere)
dart pub global activate flutterfire_cli

# Path'e ekle (eğer hata alırsan)
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

---

## ⚙️ ADIM 3: Projeyi Firebase'e Bağla

```bash
# Proje klasörüne git
cd /Users/boranonder/AndroidStudioProjects/look_cook

# FlutterFire configure çalıştır
flutterfire configure
```

**Sırayla şunları sor:**

1. **"Select a Firebase project"**
   → `look-cook-app` seç (varsa)
   → Yoksa "Create new project" seç

2. **"Which platforms should your configuration support?"**
   → ✅ android
   → ✅ ios
   → ❌ macos (gerekirse ekle)
   → ❌ web (şimdilik)

3. **Android package name?**
   → `com.example.look_cook` (varsayılan kabul et)

4. **iOS bundle ID?**
   → `com.example.lookCook` (zaten var)

**Sonuç:**
```
✅ firebase_options.dart güncellendi
✅ android/app/google-services.json oluşturuldu
✅ ios/Runner/GoogleService-Info.plist güncellendi
```

---

## 🗄️ ADIM 4: Firestore Database Oluştur

1. Firebase Console → **look-cook-app** projesine git
2. Sol menü → **Build** → **Firestore Database**
3. **Create database** butonuna tıkla
4. Şu ayarları seç:

```
Location: europe-west (Türkiye'ye yakın)
Mode: ⚠️ START IN TEST MODE (şimdilik - geliştirme için)
```

5. **Enable** → Bekle (30 saniye)

**Test Mode Rules:** (Otomatik gelir)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 2, 1);
    }
  }
}
```

⚠️ **Önemli:** Bu rules sadece test için! Production'a çıkmadan önce güvenli rules yazacağız.

---

## 📦 ADIM 5: Firebase Storage Aktifleştir

1. Firebase Console → Sol menü → **Build** → **Storage**
2. **Get Started** butonuna tıkla
3. **Security Rules:** Test mode seç
4. **Storage Location:** europe-west3
5. **Done** → Bekle

**Test Mode Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2025, 2, 1);
    }
  }
}
```

---

## 🔐 ADIM 6: Authentication Aktifleştir

1. Firebase Console → Sol menü → **Build** → **Authentication**
2. **Get started** butonuna tıkla
3. **Sign-in method** sekmesine git
4. **Email/Password** butonuna tıkla
5. ✅ **Enable** yap
6. **Save**

---

## 🧪 ADIM 7: Test Et

```bash
# Paketleri güncelle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

**Console'da şunları göreceksin:**

✅ **Başarılı:**
```
✅ Firebase initialized successfully
✅ Algolia sync completed
🎉 App ready!
```

❌ **Başarısız:**
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(41)] 
Unhandled Exception: [core/no-app] No Firebase App...
```

---

## 🔥 ADIM 8: İlk Kullanıcı Oluştur (Test)

1. Uygulamayı aç
2. **Kayıt Ol** butonuna tıkla
3. Email: `test@example.com`
4. Şifre: `test123`
5. İsim: `Test User`
6. **Kayıt Ol**

Firebase Console → **Authentication** → **Users** sekmesinde göreceksin! ✅

---

## 📊 ADIM 9: Firestore'da Veri Kontrol

1. Uygulamada bir tarif ekle
2. Firebase Console → **Firestore Database**
3. **recipes** koleksiyonunu göreceksin
4. İçinde tarif verisi var mı kontrol et

---

## ⚠️ SORUN GİDERME

### "No Firebase App has been created"
```bash
# FlutterFire'ı yeniden configure et
flutterfire configure --force

# Pub get
flutter pub get

# Uygulamayı temizle
flutter clean
flutter pub get
flutter run
```

### "google-services.json not found"
```bash
# Android Studio'da:
# Build → Rebuild Project

# Ya da manuel kopyala:
cp google-services.json android/app/
```

### "Unable to authenticate with Firebase"
```bash
# Firebase'e tekrar login ol
firebase logout
firebase login

# FlutterFire'ı güncelle
dart pub global activate flutterfire_cli
```

---

## ✅ BAŞARILI KURULUM KONTROLLERİ

- [ ] `firebase_options.dart` gerçek API keyleri var
- [ ] `android/app/google-services.json` var
- [ ] `ios/Runner/GoogleService-Info.plist` güncel
- [ ] Firebase Console → Authentication aktif
- [ ] Firebase Console → Firestore oluşturuldu
- [ ] Firebase Console → Storage aktif
- [ ] Uygulama çalışıyor ve hata yok
- [ ] Test kullanıcısı oluşturulabildi
- [ ] Tarif eklenebiliyor

---

## 🎉 TAMAMLANDI!

Artık Firebase tamamen aktif:
- ✅ Gerçek kullanıcı kaydı
- ✅ Firestore database
- ✅ Firebase Storage (resim/video)
- ✅ Algolia (arama)
- ✅ Herşey hazır! 🚀

---

## 📱 ÜRETİME ÇIKMADAN ÖNCE (ÖNEMLI!)

### 1. Security Rules Güncelle

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users - Sadece kendi profilini düzenleyebilir
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Recipes - Authenticated users yazabilir
    match /recipes/{recipeId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.authorId;
    }
    
    // Reviews
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.userId;
    }
  }
}
```

**Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /recipes/{recipeId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /users/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 2. API Key Restrictions (Google Cloud Console)

Firebase Console → Project Settings → Service Accounts → Google Cloud Console

API Keys için restrictions ekle (Android/iOS app restrictions)

---

## 🔗 Faydalı Linkler

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firebase Storage Rules](https://firebase.google.com/docs/storage/security)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)


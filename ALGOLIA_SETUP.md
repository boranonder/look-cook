# 🔥 Algolia Kurulum Rehberi

Uygulamanızın arama ve ranking özelliklerini aktifleştirmek için Algolia'yı yapılandırın.

## 📝 Adım 1: Algolia Hesabı Oluşturun

1. [https://www.algolia.com](https://www.algolia.com) adresine gidin
2. **"Start for Free"** butonuna tıklayın
3. Email ile kayıt olun (GitHub ile de olur)
4. Ücretsiz plan otomatik seçilir ✅

## 🔑 Adım 2: API Key'lerini Alın

1. Algolia Dashboard'a girin
2. Sol menüden **Settings** → **API Keys** seçin
3. Şu bilgileri kopyalayın:
   - **Application ID** (örn: `ABC123XYZ`)
   - **Search-Only API Key** (örn: `abc123...`)
   - **Admin API Key** (örn: `xyz789...`) - Sadece backend için!

## 📝 Adım 3: Config Dosyasını Güncelleyin

`lib/config/algolia_config.dart` dosyasını açın ve değerleri yapıştırın:

```dart
class AlgoliaConfig {
  static const String applicationId = 'AFIN2QXTEMQ'; // Buraya yapıştır
  static const String searchApiKey = 'abc123...';  // Buraya yapıştır
  static const String adminApiKey = 'xyz789...';   // Buraya yapıştır (opsiyonel)
  
  // Index isimleri (değiştirmeyin)
  static const String recipesIndex = 'recipes';
  static const String recipesTrendingIndex = 'recipes_trending';
  static const String recipesTopRatedIndex = 'recipes_top_rated';
  static const String usersIndex = 'users';
}
```

## 🗂️ Adım 4: Index'leri Oluşturun

1. Algolia Dashboard'da **Indices** sekmesine gidin
2. **"Create Index"** butonuna tıklayın
3. Şu index'leri oluşturun:
   - `recipes`
   - `recipes_trending`
   - `recipes_top_rated`
   - `users`

## ⚙️ Adım 5: Index Ayarlarını Yapılandırın

### `recipes` Index'i için:

1. Index'i açın → **Configuration** → **Searchable Attributes**
2. Şu alanları ekleyin (sırayla):
   ```
   name
   description
   ingredients
   authorName
   tags
   ```

3. **Custom Ranking** (Configuration → Ranking and Sorting):
   ```
   desc(averageRating)
   desc(reviewCount)
   desc(favoriteCount)
   ```

4. **Facets** (Configuration → Facets):
   ```
   category
   authorId
   ```

### `recipes_trending` Index'i için:

1. **Custom Ranking**:
   ```
   desc(trendScore)
   desc(createdAt)
   ```

### `recipes_top_rated` Index'i için:

1. **Custom Ranking**:
   ```
   desc(averageRating)
   desc(reviewCount)
   ```

### `users` Index'i için:

1. **Searchable Attributes**:
   ```
   name
   bio
   ```

2. **Custom Ranking**:
   ```
   desc(followerCount)
   desc(recipeCount)
   ```

## 🚀 Adım 6: Uygulamayı Çalıştırın

```bash
# Paketleri yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

Uygulama başladığında:
- Mock data otomatik olarak Algolia'ya sync edilir ✅
- Console'da şu mesajları göreceksiniz:
  ```
  🔄 Starting Algolia sync...
  👥 Syncing users...
  ✅ Synced 6 users
  🍳 Syncing recipes...
  ✅ Synced 12 recipes
  🎉 Algolia sync completed successfully!
  ```

## ✅ Test Edin

1. **Arama Ekranı**: Üst menüde 🔍 ikonuna tıklayın
   - "pizza" yazın → Anında sonuç görmeli ⚡
   - Algolia aktifse "⚡ Hızlı arama aktif" yazısını görürsünüz

2. **Keşfet Sayfası**: Alt menüde 🔥 Keşfet'e tıklayın
   - Top 10 listeler Algolia'dan gelir
   - Başlıkta ⚡ ikonu görürseniz Algolia aktif demektir

## 🐛 Sorun Giderme

### "Algolia is not configured" Hatası
- `lib/config/algolia_config.dart` dosyasındaki key'leri kontrol edin
- `YOUR_APP_ID` ve `YOUR_SEARCH_API_KEY` değiştirilmiş mi?

### "Index does not exist" Hatası
- Algolia Dashboard'da index'leri oluşturduğunuzdan emin olun
- Index isimlerinin config'deki ile aynı olduğunu kontrol edin

### Arama Sonuç Vermiyor
- Index'e veri sync edildi mi kontrol edin
- Algolia Dashboard → Index → **Browse** bölümünden veriyi görebilirsiniz
- Uygulamayı yeniden başlatarak sync'i tetikleyin

### Console'da "Algolia sync failed" Görüyorum
- API Key'lerin doğru olduğundan emin olun
- Search-Only API Key yerine Admin API Key kullanmanız gerekebilir (sadece sync için)

## 💰 Ücretsiz Limitler

✅ **Algolia Free Tier:**
- 10,000 arama/ay
- 100,000 kayıt
- İlk 1000 kullanıcı için yeterli!

⚠️ **Limit Aşımında:**
- Dashboard'dan kullanım istatistiklerini takip edin
- Gerekirse ücretli plana yükseltin ($1/1K search)

## 🎉 Tebrikler!

Artık uygulamanızda **profesyonel arama ve ranking** sistemi çalışıyor! 🚀

**Özellikler:**
- ⚡ Anlık arama (typo tolerance)
- 🎯 Akıllı ranking
- 📊 Top 10 listeler
- 🔥 Trend hesaplama
- 🏆 En iyi aşçılar

## 📚 Daha Fazla Bilgi

- [Algolia Docs](https://www.algolia.com/doc/)
- [Flutter Algolia Package](https://pub.dev/packages/algolia)
- [Algolia Dashboard](https://www.algolia.com/dashboard)


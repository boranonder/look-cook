import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('tr'),
  ];

  // App Name
  String get appName;

  // Auth
  String get login;
  String get register;
  String get email;
  String get password;
  String get confirmPassword;
  String get name;
  String get enterApp;
  String get loginToLike;
  String get loginToComment;
  String get loginToSave;

  // Navigation
  String get home;
  String get discover;
  String get leaderboard;
  String get addRecipe;
  String get profile;

  // Home Screen
  String get fromFollowing;
  String get noRecipesFromFollowing;
  String get noFollowingYet;
  String get discoverChefs;
  String get goToDiscover;
  String get discoverMore;
  String get categories;
  String get featured;
  String get topTenToday;
  String get mostPopularDesserts;
  String get recommendationsForYou;
  String get mostFavorited;

  // Discover Screen
  String get searchPlaceholder;
  String get filter;
  String get seeAll;
  String get forYou;
  String get topTen;
  String get popularRecipes;
  String get popularChefs;
  String get noRecipesYet;

  // Category Screen
  String get sortBy;
  String get highestRating;
  String get newest;
  String get mostPopular;
  String get noRecipesInCategory;

  // Leaderboard
  String get topRated;
  String get mostReviewed;
  String get trending;
  String get topChefs;

  // Rankings
  String get rankings;
  String get allRecipes;
  String get chefs;
  String get rank1st;
  String get rank2nd;
  String get rank3rd;

  // Recipe
  String get recipeName;
  String get ingredients;
  String get instructions;
  String get addPhoto;
  String get publish;
  String get rating;
  String get reviews;
  String get addReview;
  String get ratingOnly;
  String get writeReview;
  String get submitReview;
  String get cookTime;
  String get servings;
  String get minutes;
  String get person;

  // Profile
  String get myRecipes;
  String get settings;
  String get language;
  String get followers;
  String get following;
  String get recipes;
  String get editProfile;
  String get logout;

  // General
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get search;
  String get loading;
  String get error;
  String get retry;
  String get success;
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'tr':
        return AppLocalizationsTr();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appName => 'Look & Cook';

  // Auth
  @override
  String get login => 'Login';
  @override
  String get register => 'Register';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get name => 'Name';
  @override
  String get enterApp => 'Enter App';
  @override
  String get loginToLike => 'Please login to like';
  @override
  String get loginToComment => 'Please login to comment';
  @override
  String get loginToSave => 'Please login to save';

  // Navigation
  @override
  String get home => 'Home';
  @override
  String get discover => 'Discover';
  @override
  String get leaderboard => 'Leaderboard';
  @override
  String get addRecipe => 'Add Recipe';
  @override
  String get profile => 'Profile';

  // Home Screen
  @override
  String get fromFollowing => 'From Following';
  @override
  String get noRecipesFromFollowing => 'No recipes from people you follow yet';
  @override
  String get noFollowingYet => 'You are not following anyone yet';
  @override
  String get discoverChefs => 'Discover chefs and follow them to see their recipes here';
  @override
  String get goToDiscover => 'Go to Discover';
  @override
  String get discoverMore => 'Discover More';
  @override
  String get categories => 'Categories';
  @override
  String get featured => 'Featured';
  @override
  String get topTenToday => 'Top 10 Today';
  @override
  String get mostPopularDesserts => 'Most Popular Desserts';
  @override
  String get recommendationsForYou => 'Recommendations for You';
  @override
  String get mostFavorited => 'Most Favorited';

  // Discover Screen
  @override
  String get searchPlaceholder => 'Search recipe, ingredient or chef...';
  @override
  String get filter => 'Filter';
  @override
  String get seeAll => 'See All';
  @override
  String get forYou => 'For You';
  @override
  String get topTen => 'Top 10';
  @override
  String get popularRecipes => 'Popular Recipes';
  @override
  String get popularChefs => 'Popular Chefs';
  @override
  String get noRecipesYet => 'No recipes yet';

  // Category Screen
  @override
  String get sortBy => 'Sort by:';
  @override
  String get highestRating => 'Highest Rating';
  @override
  String get newest => 'Newest';
  @override
  String get mostPopular => 'Most Popular';
  @override
  String get noRecipesInCategory => 'No recipes in this category yet';

  // Leaderboard
  @override
  String get topRated => 'Top Rated';
  @override
  String get mostReviewed => 'Most Reviewed';
  @override
  String get trending => 'Trending';
  @override
  String get topChefs => 'Top Chefs';

  // Rankings
  @override
  String get rankings => 'Rankings';
  @override
  String get allRecipes => 'All Recipes';
  @override
  String get chefs => 'Chefs';
  @override
  String get rank1st => '1st';
  @override
  String get rank2nd => '2nd';
  @override
  String get rank3rd => '3rd';

  // Recipe
  @override
  String get recipeName => 'Recipe Name';
  @override
  String get ingredients => 'Ingredients';
  @override
  String get instructions => 'Instructions';
  @override
  String get addPhoto => 'Add Photo';
  @override
  String get publish => 'Publish';
  @override
  String get rating => 'Rating';
  @override
  String get reviews => 'Reviews';
  @override
  String get addReview => 'Add Review';
  @override
  String get ratingOnly => 'Rating Only';
  @override
  String get writeReview => 'Write a review...';
  @override
  String get submitReview => 'Submit Review';
  @override
  String get cookTime => 'Cook Time';
  @override
  String get servings => 'Servings';
  @override
  String get minutes => 'min';
  @override
  String get person => 'person';

  // Profile
  @override
  String get myRecipes => 'My Recipes';
  @override
  String get settings => 'Settings';
  @override
  String get language => 'Language';
  @override
  String get followers => 'Followers';
  @override
  String get following => 'Following';
  @override
  String get recipes => 'Recipes';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get logout => 'Logout';

  // General
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get search => 'Search';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get retry => 'Retry';
  @override
  String get success => 'Success';
  @override
  String get close => 'Close';
}

class AppLocalizationsTr extends AppLocalizations {
  @override
  String get appName => 'Look & Cook';

  // Auth
  @override
  String get login => 'Giriş Yap';
  @override
  String get register => 'Kayıt Ol';
  @override
  String get email => 'E-posta';
  @override
  String get password => 'Şifre';
  @override
  String get confirmPassword => 'Şifre Tekrar';
  @override
  String get name => 'İsim';
  @override
  String get enterApp => 'Uygulamaya Gir';
  @override
  String get loginToLike => 'Beğenmek için giriş yapmalısınız';
  @override
  String get loginToComment => 'Yorum yapmak için giriş yapmalısınız';
  @override
  String get loginToSave => 'Kaydetmek için giriş yapmalısınız';

  // Navigation
  @override
  String get home => 'Ana Sayfa';
  @override
  String get discover => 'Keşfet';
  @override
  String get leaderboard => 'Sıralama';
  @override
  String get addRecipe => 'Tarif Ekle';
  @override
  String get profile => 'Profil';

  // Home Screen
  @override
  String get fromFollowing => 'Takip Ettiklerinden';
  @override
  String get noRecipesFromFollowing => 'Takip ettigin kisilerden henuz tarif yok';
  @override
  String get noFollowingYet => 'Henuz kimseyi takip etmiyorsun';
  @override
  String get discoverChefs => 'Ascilar kesfet ve tariflerini burada gormek icin takip et';
  @override
  String get goToDiscover => 'Kesfet\'e Git';
  @override
  String get discoverMore => 'Daha Fazla Kesfet';
  @override
  String get categories => 'Kategoriler';
  @override
  String get featured => 'Öne Çıkanlar';
  @override
  String get topTenToday => 'Bugün Top 10';
  @override
  String get mostPopularDesserts => 'En Popüler Tatlılar';
  @override
  String get recommendationsForYou => 'Sizin İçin Öneriler';
  @override
  String get mostFavorited => 'En Çok Favorilenenler';

  // Discover Screen
  @override
  String get searchPlaceholder => 'Tarif, malzeme veya aşçı ara...';
  @override
  String get filter => 'Filtrele';
  @override
  String get seeAll => 'Tümünü Gör';
  @override
  String get forYou => 'Senin İçin';
  @override
  String get topTen => 'Top 10';
  @override
  String get popularRecipes => 'Popüler Tarifler';
  @override
  String get popularChefs => 'Popüler Aşçılar';
  @override
  String get noRecipesYet => 'Henüz tarif yok';

  // Category Screen
  @override
  String get sortBy => 'Sırala:';
  @override
  String get highestRating => 'En Yüksek Puan';
  @override
  String get newest => 'En Yeni';
  @override
  String get mostPopular => 'En Popüler';
  @override
  String get noRecipesInCategory => 'Bu kategoride henüz tarif yok';

  // Leaderboard
  @override
  String get topRated => 'En Yüksek Puanlı';
  @override
  String get mostReviewed => 'En Çok Değerlendirilen';
  @override
  String get trending => 'Trend Olanlar';
  @override
  String get topChefs => 'En İyi Aşçılar';

  // Rankings
  @override
  String get rankings => 'Sıralamalar';
  @override
  String get allRecipes => 'Tüm Tarifler';
  @override
  String get chefs => 'Aşçılar';
  @override
  String get rank1st => '1.';
  @override
  String get rank2nd => '2.';
  @override
  String get rank3rd => '3.';

  // Recipe
  @override
  String get recipeName => 'Tarif Adı';
  @override
  String get ingredients => 'Malzemeler';
  @override
  String get instructions => 'Yapılışı';
  @override
  String get addPhoto => 'Fotoğraf Ekle';
  @override
  String get publish => 'Yayınla';
  @override
  String get rating => 'Puan';
  @override
  String get reviews => 'Yorumlar';
  @override
  String get addReview => 'Yorum Ekle';
  @override
  String get ratingOnly => 'Sadece Puan';
  @override
  String get writeReview => 'Yorum yazın...';
  @override
  String get submitReview => 'Gönder';
  @override
  String get cookTime => 'Pişirme Süresi';
  @override
  String get servings => 'Porsiyon';
  @override
  String get minutes => 'dk';
  @override
  String get person => 'kişi';

  // Profile
  @override
  String get myRecipes => 'Tariflerim';
  @override
  String get settings => 'Ayarlar';
  @override
  String get language => 'Dil';
  @override
  String get followers => 'Takipçi';
  @override
  String get following => 'Takip';
  @override
  String get recipes => 'Tarif';
  @override
  String get editProfile => 'Profili Düzenle';
  @override
  String get logout => 'Çıkış Yap';

  // General
  @override
  String get save => 'Kaydet';
  @override
  String get cancel => 'İptal';
  @override
  String get delete => 'Sil';
  @override
  String get edit => 'Düzenle';
  @override
  String get search => 'Ara';
  @override
  String get loading => 'Yükleniyor...';
  @override
  String get error => 'Hata';
  @override
  String get retry => 'Tekrar Dene';
  @override
  String get success => 'Başarılı';
  @override
  String get close => 'Kapat';
}

import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/user.dart' as app_user;
import 'algolia_service.dart';

/// Seed Service - Veritabanına test verisi eklemek için
/// 100 kullanıcı, 100 tarif ve karşılıklı yorumlar oluşturur
class SeedService {
  late final SupabaseClient _supabase;
  final AlgoliaService _algoliaService = AlgoliaService();
  final _uuid = const Uuid();
  final _random = Random();

  SeedService() {
    // Service Role Key ile admin client oluştur (RLS'yi bypass eder)
    final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';

    if (serviceRoleKey.isNotEmpty && supabaseUrl.isNotEmpty) {
      _supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
    } else {
      // Fallback to regular client
      _supabase = Supabase.instance.client;
    }
  }

  // Progress callback
  Function(String message, double progress)? onProgress;

  // ======================= TURKISH DATA =======================

  final List<String> _turkishFirstNames = [
    'Ahmet', 'Mehmet', 'Mustafa', 'Ali', 'Hüseyin', 'Hasan', 'İbrahim', 'İsmail', 'Osman', 'Yusuf',
    'Murat', 'Ömer', 'Emre', 'Burak', 'Cem', 'Kemal', 'Serkan', 'Tolga', 'Umut', 'Volkan',
    'Ayşe', 'Fatma', 'Emine', 'Hatice', 'Zeynep', 'Elif', 'Merve', 'Büşra', 'Esra', 'Seda',
    'Deniz', 'Derya', 'Gül', 'Hacer', 'Havva', 'Kübra', 'Melek', 'Nur', 'Özlem', 'Pınar',
    'Rabia', 'Selin', 'Sibel', 'Tuğba', 'Yasemin', 'Zehra', 'Aslı', 'Başak', 'Ceren', 'Dilek',
    'Ece', 'Filiz', 'Gamze', 'Gizem', 'Hilal', 'İrem', 'Kader', 'Leyla', 'Mine', 'Naz',
    'Oğuz', 'Polat', 'Rıza', 'Sami', 'Taner', 'Ufuk', 'Veli', 'Yavuz', 'Zafer', 'Berkay',
    'Can', 'Doğan', 'Eren', 'Ferhat', 'Görkem', 'Halil', 'Ilgaz', 'Kaan', 'Levent', 'Mert',
    'Necati', 'Onur', 'Özer', 'Rüzgar', 'Selim', 'Tuna', 'Uğur', 'Vedat', 'Yiğit', 'Arda',
    'Barış', 'Cenk', 'Doruk', 'Eray', 'Furkan', 'Gökhan', 'Harun', 'Koray', 'Ozan', 'Serhat',
  ];

  final List<String> _turkishLastNames = [
    'Yılmaz', 'Kaya', 'Demir', 'Çelik', 'Şahin', 'Yıldız', 'Yıldırım', 'Öztürk', 'Aydın', 'Özdemir',
    'Arslan', 'Doğan', 'Kılıç', 'Aslan', 'Çetin', 'Kara', 'Koç', 'Kurt', 'Özkan', 'Şimşek',
    'Polat', 'Korkmaz', 'Acar', 'Güneş', 'Aktaş', 'Erdoğan', 'Yalçın', 'Özer', 'Aksoy', 'Güler',
    'Tekin', 'Kaplan', 'Karataş', 'Bulut', 'Taş', 'Ünal', 'Keskin', 'Bozkurt', 'Güngör', 'Sarı',
    'Turan', 'Bayrak', 'Karakuş', 'Sönmez', 'Erdem', 'Coşkun', 'Duman', 'Eroğlu', 'Peker', 'Akgün',
  ];

  final List<String> _turkishBios = [
    'Yemek yapmayı seven bir gurme',
    'Mutfakta denemeler yapmayı seviyorum',
    'Anne mutfağından lezzetler sunuyorum',
    'Profesyonel aşçı, 10 yıllık deneyim',
    'Ev yemekleri uzmanı',
    'Tatlı yapımında uzmanlaştım',
    'Sağlıklı beslenme tutkunu',
    'Dünya mutfaklarını keşfediyorum',
    'Geleneksel Türk mutfağı aşığı',
    'Sokak lezzetleri meraklısı',
    'Fitness ve sağlıklı tarifler',
    'Vejeteryan mutfak sevdalısı',
    'Deniz ürünleri konusunda uzmanım',
    'Kahvaltı sofraları benim işim',
    'Hamur işleri ustası',
  ];

  // ======================= RECIPE DATA =======================

  final Map<RecipeCategory, List<Map<String, dynamic>>> _recipesByCategory = {
    RecipeCategory.pizza: [
      {'name': 'Margarita Pizza', 'desc': 'Klasik İtalyan margarita pizza tarifi', 'ingredients': ['500g pizza hamuru', 'Domates sosu', 'Mozzarella peyniri', 'Taze fesleğen', 'Zeytinyağı'], 'instructions': ['Hamuru açın', 'Sosu sürün', 'Peyniri ekleyin', '220°C fırında 15 dk pişirin'], 'tags': ['italyan', 'pizza', 'peynirli']},
      {'name': 'Sucuklu Pizza', 'desc': 'Türk usulü sucuklu pizza', 'ingredients': ['Pizza hamuru', 'Sucuk', 'Kaşar peyniri', 'Domates sosu', 'Biber'], 'instructions': ['Hamuru yuvarlak açın', 'Sosu sürün', 'Sucuk ve peynir ekleyin', 'Fırında pişirin'], 'tags': ['türk', 'sucuklu', 'pizza']},
      {'name': 'Karışık Pizza', 'desc': 'Her şeyden biraz karışık pizza', 'ingredients': ['Pizza hamuru', 'Sosis', 'Mantar', 'Biber', 'Zeytin', 'Mozzarella'], 'instructions': ['Hamuru hazırlayın', 'Malzemeleri doğrayın', 'Üzerine dizin', 'Fırında pişirin'], 'tags': ['karışık', 'mantarlı', 'pizza']},
      {'name': 'Lahmacun Pizza', 'desc': 'Lahmacun tadında pizza', 'ingredients': ['Pizza hamuru', 'Kıyma', 'Soğan', 'Biber', 'Domates', 'Maydanoz'], 'instructions': ['Kıymalı harcı hazırlayın', 'Hamura yayın', 'Fırında pişirin', 'Limon ile servis edin'], 'tags': ['lahmacun', 'kıymalı', 'türk']},
    ],
    RecipeCategory.tatli: [
      {'name': 'Sütlaç', 'desc': 'Geleneksel Türk sütlacı', 'ingredients': ['1L süt', '1 su bardağı pirinç', '1 su bardağı şeker', 'Vanilya'], 'instructions': ['Pirinci haşlayın', 'Süt ekleyin', 'Şekeri ekleyin', 'Koyulaşana kadar karıştırın'], 'tags': ['geleneksel', 'sütlü', 'tatlı']},
      {'name': 'Kazandibi', 'desc': 'Karamelize tavuk göğsü tatlısı', 'ingredients': ['Tavuk göğsü', 'Süt', 'Şeker', 'Nişasta', 'Vanilya'], 'instructions': ['Tavuğu didikleyin', 'Muhallebi yapın', 'Altını yakın', 'Rulo yapıp servis edin'], 'tags': ['osmanlı', 'geleneksel', 'muhallebi']},
      {'name': 'Revani', 'desc': 'Şerbetli irmik tatlısı', 'ingredients': ['İrmik', 'Un', 'Yumurta', 'Şeker', 'Yoğurt', 'Şerbet'], 'instructions': ['Malzemeleri karıştırın', 'Tepsiye dökün', 'Fırında pişirin', 'Şerbeti dökün'], 'tags': ['şerbetli', 'irmikli', 'tatlı']},
      {'name': 'Profiterol', 'desc': 'Çikolata soslu profiterol', 'ingredients': ['Su', 'Tereyağı', 'Un', 'Yumurta', 'Krema', 'Çikolata'], 'instructions': ['Hamuru pişirin', 'Toplar yapın', 'İçini doldurun', 'Çikolata dökün'], 'tags': ['çikolatalı', 'kremalı', 'fransız']},
    ],
    RecipeCategory.dondurma: [
      {'name': 'Maraş Dondurması', 'desc': 'Uzayan geleneksel Maraş dondurması', 'ingredients': ['Keçi sütü', 'Salep', 'Şeker', 'Mastic sakızı'], 'instructions': ['Sütü ısıtın', 'Salepi ekleyin', 'Karıştırarak pişirin', 'Dondurma makinesinde dondurun'], 'tags': ['maraş', 'geleneksel', 'salep']},
      {'name': 'Çikolatalı Dondurma', 'desc': 'Ev yapımı çikolatalı dondurma', 'ingredients': ['Süt', 'Krema', 'Kakao', 'Şeker', 'Yumurta sarısı'], 'instructions': ['Krema bazı hazırlayın', 'Kakao ekleyin', 'Soğutun', 'Dondurun'], 'tags': ['çikolatalı', 'ev yapımı', 'kremalı']},
      {'name': 'Meyveli Sorbe', 'desc': 'Serinletici meyve sorbesi', 'ingredients': ['Çilek', 'Şeker', 'Limon suyu', 'Su'], 'instructions': ['Meyveleri püre yapın', 'Şerbeti hazırlayın', 'Karıştırın', 'Dondurun'], 'tags': ['meyveli', 'sorbe', 'vegan']},
      {'name': 'Fıstıklı Dondurma', 'desc': 'Antep fıstıklı dondurma', 'ingredients': ['Süt', 'Krema', 'Antep fıstığı', 'Şeker'], 'instructions': ['Fıstıkları öğütün', 'Kremayı hazırlayın', 'Karıştırın', 'Dondurun'], 'tags': ['fıstıklı', 'antep', 'premium']},
    ],
    RecipeCategory.sokakLezzetleri: [
      {'name': 'Midye Dolma', 'desc': 'Klasik sokak midyesi', 'ingredients': ['Midye', 'Pirinç', 'Soğan', 'Çam fıstığı', 'Kuş üzümü', 'Baharat'], 'instructions': ['Midyeleri temizleyin', 'İç harcı hazırlayın', 'Doldurun', 'Pişirin'], 'tags': ['deniz', 'sokak', 'geleneksel']},
      {'name': 'Kokoreç', 'desc': 'Baharatlı kokoreç', 'ingredients': ['Bağırsak', 'Baharat', 'Kimyon', 'Pul biber', 'Ekmek'], 'instructions': ['Bağırsakları temizleyin', 'Baharatlayın', 'Şişe geçirin', 'Közde pişirin'], 'tags': ['sokak', 'ızgara', 'baharatlı']},
      {'name': 'Kumpir', 'desc': 'Dolu dolu kumpir', 'ingredients': ['Büyük patates', 'Tereyağı', 'Kaşar', 'Turşu', 'Mısır', 'Soslar'], 'instructions': ['Patatesi fırında pişirin', 'İçini ezin', 'Malzemeleri ekleyin', 'Servis edin'], 'tags': ['patates', 'sokak', 'doyurucu']},
      {'name': 'Balık Ekmek', 'desc': 'İstanbul usulü balık ekmek', 'ingredients': ['Uskumru', 'Soğan', 'Marul', 'Ekmek', 'Limon'], 'instructions': ['Balığı ızgara yapın', 'Ekmeğe koyun', 'Soğan ve marul ekleyin', 'Limon sıkın'], 'tags': ['balık', 'istanbul', 'sokak']},
    ],
    RecipeCategory.burger: [
      {'name': 'Klasik Burger', 'desc': 'Ev yapımı klasik burger', 'ingredients': ['Dana kıyma', 'Burger ekmeği', 'Marul', 'Domates', 'Turşu', 'Sos'], 'instructions': ['Köfteleri şekillendirin', 'Izgara yapın', 'Ekmeği kızartın', 'Birleştirin'], 'tags': ['klasik', 'dana', 'burger']},
      {'name': 'Cheese Burger', 'desc': 'Bol peynirli burger', 'ingredients': ['Kıyma', 'Cheddar peyniri', 'Burger ekmeği', 'Soğan', 'Turşu'], 'instructions': ['Köfteyi pişirin', 'Peyniri eritin', 'Ekmeğe koyun', 'Servis edin'], 'tags': ['peynirli', 'cheddar', 'burger']},
      {'name': 'Tavuk Burger', 'desc': 'Çıtır tavuk burger', 'ingredients': ['Tavuk göğsü', 'Galeta unu', 'Marul', 'Mayonez', 'Ekmek'], 'instructions': ['Tavuğu paneleyin', 'Kızartın', 'Ekmeğe yerleştirin', 'Sos ekleyin'], 'tags': ['tavuk', 'çıtır', 'burger']},
      {'name': 'Double Burger', 'desc': 'Çift katlı dev burger', 'ingredients': ['2 köfte', 'Çift peynir', 'Bacon', 'Soğan halkası', 'Özel sos'], 'instructions': ['Köfteleri pişirin', 'Katları oluşturun', 'Sos ekleyin', 'Servis edin'], 'tags': ['double', 'doyurucu', 'premium']},
    ],
    RecipeCategory.doner: [
      {'name': 'Tavuk Döner', 'desc': 'Ev yapımı tavuk döner', 'ingredients': ['Tavuk but', 'Yoğurt', 'Baharat', 'Lavaş', 'Domates'], 'instructions': ['Tavuğu marine edin', 'Şişe geçirin', 'Pişirin', 'Lavaşa sarın'], 'tags': ['tavuk', 'döner', 'ev yapımı']},
      {'name': 'Et Döner', 'desc': 'Geleneksel et döner', 'ingredients': ['Dana eti', 'Kuyruk yağı', 'Baharat', 'Pide', 'Sos'], 'instructions': ['Etleri dilimleyin', 'Baharatlayın', 'Şişe dizin', 'Döner ocağında pişirin'], 'tags': ['et', 'geleneksel', 'döner']},
      {'name': 'İskender', 'desc': 'Bursa usulü iskender kebap', 'ingredients': ['Döner eti', 'Pide', 'Tereyağı', 'Yoğurt', 'Domates sosu'], 'instructions': ['Pideyi doğrayın', 'Döner ekleyin', 'Sos dökün', 'Tereyağı gezdirin'], 'tags': ['iskender', 'bursa', 'yoğurtlu']},
      {'name': 'Döner Dürüm', 'desc': 'Lavaşta döner dürüm', 'ingredients': ['Döner eti', 'Lavaş', 'Soğan', 'Maydanoz', 'Sos'], 'instructions': ['Döneri kesin', 'Lavaşa koyun', 'Garnitür ekleyin', 'Sarın'], 'tags': ['dürüm', 'pratik', 'sokak']},
    ],
    RecipeCategory.kebap: [
      {'name': 'Adana Kebap', 'desc': 'Acılı Adana kebabı', 'ingredients': ['Dana kıyma', 'Kuyruk yağı', 'Pul biber', 'Tuz', 'Şiş'], 'instructions': ['Kıymayı yoğurun', 'Şişe geçirin', 'Közde pişirin', 'Lavaşla servis edin'], 'tags': ['adana', 'acılı', 'közde']},
      {'name': 'Urfa Kebap', 'desc': 'Acısız Urfa kebabı', 'ingredients': ['Dana kıyma', 'Kuyruk yağı', 'Karabiber', 'Tuz'], 'instructions': ['Kıymayı hazırlayın', 'Şişe çekin', 'Közde pişirin', 'Servis edin'], 'tags': ['urfa', 'acısız', 'kebap']},
      {'name': 'Beyti Kebap', 'desc': 'Yoğurtlu beyti sarma', 'ingredients': ['Kuşbaşı et', 'Lavaş', 'Yoğurt', 'Tereyağı', 'Domates sosu'], 'instructions': ['Eti pişirin', 'Lavaşa sarın', 'Dilimleyin', 'Sos ve yoğurt ekleyin'], 'tags': ['beyti', 'sarma', 'yoğurtlu']},
      {'name': 'Şiş Kebap', 'desc': 'Klasik kuşbaşı şiş', 'ingredients': ['Kuzu eti', 'Biber', 'Soğan', 'Domates', 'Baharat'], 'instructions': ['Eti marine edin', 'Şişe dizin', 'Sebzeleri ekleyin', 'Izgara yapın'], 'tags': ['şiş', 'kuzu', 'ızgara']},
    ],
    RecipeCategory.tavuk: [
      {'name': 'Tavuk Sote', 'desc': 'Sebzeli tavuk sote', 'ingredients': ['Tavuk göğsü', 'Biber', 'Mantar', 'Soğan', 'Domates'], 'instructions': ['Tavuğu doğrayın', 'Sebzeleri kavurun', 'Tavuğu ekleyin', 'Pişirin'], 'tags': ['sote', 'sebzeli', 'hafif']},
      {'name': 'Fırında Tavuk', 'desc': 'Bütün fırın tavuk', 'ingredients': ['Bütün tavuk', 'Patates', 'Havuç', 'Tereyağı', 'Baharat'], 'instructions': ['Tavuğu baharatlayın', 'Sebzeleri dizin', 'Fırına verin', '180°C de pişirin'], 'tags': ['fırında', 'bütün', 'aile']},
      {'name': 'Tavuk Tandır', 'desc': 'Yumuşacık tavuk tandır', 'ingredients': ['Tavuk but', 'Yoğurt', 'Baharat', 'Sarımsak'], 'instructions': ['Marine edin', 'Tepsiye dizin', 'Düşük ateşte pişirin', 'Servis edin'], 'tags': ['tandır', 'yumuşak', 'yoğurtlu']},
      {'name': 'Çıtır Tavuk', 'desc': 'KFC tarzı çıtır tavuk', 'ingredients': ['Tavuk parçaları', 'Un', 'Baharat', 'Yumurta', 'Yağ'], 'instructions': ['Sosu hazırlayın', 'Tavuğu kaplama yapın', 'Kızgın yağda pişirin', 'Servis edin'], 'tags': ['çıtır', 'kızartma', 'fast food']},
    ],
    RecipeCategory.pide: [
      {'name': 'Kıymalı Pide', 'desc': 'Geleneksel kıymalı pide', 'ingredients': ['Pide hamuru', 'Kıyma', 'Soğan', 'Biber', 'Domates'], 'instructions': ['Hamuru açın', 'Harcı hazırlayın', 'Yayın', 'Taş fırında pişirin'], 'tags': ['kıymalı', 'geleneksel', 'fırın']},
      {'name': 'Kuşbaşılı Pide', 'desc': 'Et parçalı kuşbaşılı pide', 'ingredients': ['Pide hamuru', 'Kuşbaşı et', 'Biber', 'Domates'], 'instructions': ['Eti kavurun', 'Hamuru şekillendirin', 'İçini doldurun', 'Fırınlayın'], 'tags': ['kuşbaşı', 'etli', 'doyurucu']},
      {'name': 'Kaşarlı Pide', 'desc': 'Bol kaşarlı pide', 'ingredients': ['Pide hamuru', 'Kaşar peyniri', 'Tereyağı'], 'instructions': ['Hamuru açın', 'Kaşarı rendeleyin', 'Üzerine yayın', 'Pişirin'], 'tags': ['kaşarlı', 'peynirli', 'vejeteryan']},
      {'name': 'Karışık Pide', 'desc': 'Her şeyden biraz karışık pide', 'ingredients': ['Pide hamuru', 'Sucuk', 'Pastırma', 'Kaşar', 'Yumurta'], 'instructions': ['Hamuru hazırlayın', 'Malzemeleri dizin', 'Yumurta kırın', 'Fırınlayın'], 'tags': ['karışık', 'sucuklu', 'pastırmalı']},
    ],
    RecipeCategory.lahmacun: [
      {'name': 'Klasik Lahmacun', 'desc': 'Geleneksel ince lahmacun', 'ingredients': ['İnce hamur', 'Kıyma', 'Soğan', 'Biber', 'Domates', 'Maydanoz'], 'instructions': ['Hamuru ince açın', 'Harcı hazırlayın', 'Yayın', 'Taş fırında pişirin'], 'tags': ['geleneksel', 'ince', 'kıymalı']},
      {'name': 'Antep Lahmacun', 'desc': 'Gaziantep usulü acılı lahmacun', 'ingredients': ['Hamur', 'Kıyma', 'Acı biber', 'Nar ekşisi', 'Soğan'], 'instructions': ['Acılı harç hazırlayın', 'İnce hamura yayın', 'Taş fırında pişirin', 'Sıcak servis edin'], 'tags': ['antep', 'acılı', 'nar ekşili']},
      {'name': 'Lor Lahmacun', 'desc': 'Lor peynirli lahmacun', 'ingredients': ['Hamur', 'Lor peyniri', 'Maydanoz', 'Yeşil soğan'], 'instructions': ['Loru karıştırın', 'Hamura yayın', 'Fırınlayın', 'Sıcak servis edin'], 'tags': ['lorlu', 'peynirli', 'farklı']},
      {'name': 'Fındık Lahmacun', 'desc': 'Mini boy lahmacun', 'ingredients': ['Mini hamurlar', 'Kıyma harcı', 'Maydanoz', 'Limon'], 'instructions': ['Küçük yuvarlaklar açın', 'Harç yayın', 'Pişirin', 'Meze olarak servis edin'], 'tags': ['mini', 'meze', 'parti']},
    ],
    RecipeCategory.evYemekleri: [
      {'name': 'Karnıyarık', 'desc': 'Klasik karnıyarık', 'ingredients': ['Patlıcan', 'Kıyma', 'Soğan', 'Domates', 'Biber', 'Sarımsak'], 'instructions': ['Patlıcanları kızartın', 'İç harcı kavurun', 'Doldurun', 'Fırınlayın'], 'tags': ['patlıcan', 'kıymalı', 'fırın']},
      {'name': 'İmam Bayıldı', 'desc': 'Zeytinyağlı imam bayıldı', 'ingredients': ['Patlıcan', 'Soğan', 'Domates', 'Sarımsak', 'Zeytinyağı'], 'instructions': ['Patlıcanları hazırlayın', 'Harcı kavurun', 'Doldurun', 'Zeytinyağında pişirin'], 'tags': ['zeytinyağlı', 'vejeteryan', 'soğuk']},
      {'name': 'Etli Yaprak Sarma', 'desc': 'Geleneksel yaprak sarması', 'ingredients': ['Asma yaprağı', 'Pirinç', 'Kıyma', 'Soğan', 'Baharat'], 'instructions': ['İçi hazırlayın', 'Yaprakları sarın', 'Tencereye dizin', 'Pişirin'], 'tags': ['sarma', 'geleneksel', 'etli']},
      {'name': 'Türlü', 'desc': 'Sebzeli türlü yemeği', 'ingredients': ['Patlıcan', 'Kabak', 'Biber', 'Domates', 'Patates', 'Et'], 'instructions': ['Sebzeleri doğrayın', 'Eti kavurun', 'Tepsiye dizin', 'Fırınlayın'], 'tags': ['sebzeli', 'fırın', 'aile']},
    ],
    RecipeCategory.kofte: [
      {'name': 'İzmir Köfte', 'desc': 'Patatesli İzmir köfte', 'ingredients': ['Kıyma', 'Patates', 'Biber', 'Domates', 'Soğan'], 'instructions': ['Köfteleri yapın', 'Patatesleri dizin', 'Sosu hazırlayın', 'Fırınlayın'], 'tags': ['izmir', 'patatesli', 'fırın']},
      {'name': 'İnegöl Köfte', 'desc': 'Meşhur İnegöl köftesi', 'ingredients': ['Dana kıyma', 'Soğan', 'Tuz', 'Karabiber'], 'instructions': ['Kıymayı yoğurun', 'Şekil verin', 'Izgarada pişirin', 'Pide ile servis edin'], 'tags': ['inegöl', 'ızgara', 'sade']},
      {'name': 'Kadınbudu Köfte', 'desc': 'Pirinçli kadınbudu köfte', 'ingredients': ['Kıyma', 'Pirinç', 'Soğan', 'Yumurta', 'Un'], 'instructions': ['Harcı hazırlayın', 'Şekil verin', 'Haşlayın', 'Kızartın'], 'tags': ['kadınbudu', 'pirinçli', 'kızartma']},
      {'name': 'Sulu Köfte', 'desc': 'Soslu sulu köfte', 'ingredients': ['Kıyma', 'Pirinç', 'Domates salçası', 'Nane', 'Baharat'], 'instructions': ['Köfteleri yapın', 'Suyu hazırlayın', 'Köfteleri pişirin', 'Sıcak servis edin'], 'tags': ['sulu', 'soslu', 'ev yemeği']},
    ],
    RecipeCategory.salata: [
      {'name': 'Çoban Salata', 'desc': 'Klasik çoban salatası', 'ingredients': ['Domates', 'Salatalık', 'Biber', 'Soğan', 'Maydanoz', 'Zeytinyağı'], 'instructions': ['Sebzeleri küp doğrayın', 'Karıştırın', 'Yağ ve limon ekleyin', 'Servis edin'], 'tags': ['klasik', 'taze', 'hafif']},
      {'name': 'Akdeniz Salata', 'desc': 'Zeytinli Akdeniz salatası', 'ingredients': ['Marul', 'Domates', 'Salatalık', 'Zeytin', 'Beyaz peynir'], 'instructions': ['Malzemeleri doğrayın', 'Karıştırın', 'Peynir ekleyin', 'Sosla servis edin'], 'tags': ['akdeniz', 'zeytinli', 'peynirli']},
      {'name': 'Sezar Salata', 'desc': 'Tavuklu sezar salata', 'ingredients': ['Marul', 'Tavuk göğsü', 'Kruton', 'Parmesan', 'Sezar sos'], 'instructions': ['Tavuğu pişirin', 'Marulu doğrayın', 'Kruton ekleyin', 'Sosla karıştırın'], 'tags': ['sezar', 'tavuklu', 'doyurucu']},
      {'name': 'Mercimek Salatası', 'desc': 'Yeşil mercimek salatası', 'ingredients': ['Yeşil mercimek', 'Soğan', 'Maydanoz', 'Limon', 'Zeytinyağı'], 'instructions': ['Mercimeği haşlayın', 'Soğutun', 'Sebzeleri ekleyin', 'Sosla karıştırın'], 'tags': ['mercimek', 'protein', 'vegan']},
    ],
    RecipeCategory.vejeteryan: [
      {'name': 'Ispanaklı Börek', 'desc': 'Ev yapımı ıspanaklı börek', 'ingredients': ['Yufka', 'Ispanak', 'Lor peyniri', 'Yumurta', 'Soğan'], 'instructions': ['Ispanağı kavurun', 'Peynirle karıştırın', 'Yufkaları sarın', 'Fırınlayın'], 'tags': ['börek', 'ıspanak', 'vejeteryan']},
      {'name': 'Sebze Kızartma', 'desc': 'Karışık sebze kızartması', 'ingredients': ['Patlıcan', 'Kabak', 'Biber', 'Patates', 'Yoğurt'], 'instructions': ['Sebzeleri dilimleyin', 'Kızartın', 'Yoğurtla servis edin'], 'tags': ['kızartma', 'sebze', 'meze']},
      {'name': 'Mantar Sote', 'desc': 'Kremalı mantar sote', 'ingredients': ['Mantar', 'Krema', 'Sarımsak', 'Tereyağı', 'Maydanoz'], 'instructions': ['Mantarları soteleyin', 'Sarımsak ekleyin', 'Krema dökün', 'Servis edin'], 'tags': ['mantar', 'kremalı', 'hafif']},
      {'name': 'Zeytinyağlı Fasulye', 'desc': 'Klasik zeytinyağlı taze fasulye', 'ingredients': ['Taze fasulye', 'Domates', 'Soğan', 'Zeytinyağı'], 'instructions': ['Fasulyeleri ayıklayın', 'Soğanı kavurun', 'Domatesi ekleyin', 'Pişirin'], 'tags': ['zeytinyağlı', 'soğuk', 'vegan']},
    ],
    RecipeCategory.sushiUzakdogu: [
      {'name': 'California Roll', 'desc': 'Klasik California roll sushi', 'ingredients': ['Sushi pirinci', 'Yosun', 'Yengeç', 'Avokado', 'Salatalık'], 'instructions': ['Pirinci pişirin', 'Yosunu serin', 'Malzemeleri dizin', 'Sarın ve kesin'], 'tags': ['sushi', 'california', 'deniz']},
      {'name': 'Ramen', 'desc': 'Japon usulü ramen çorbası', 'ingredients': ['Ramen noodle', 'Tavuk suyu', 'Soya sosu', 'Yumurta', 'Yeşil soğan'], 'instructions': ['Suyu hazırlayın', 'Noodle pişirin', 'Yumurtayı haşlayın', 'Birleştirin'], 'tags': ['ramen', 'japon', 'çorba']},
      {'name': 'Pad Thai', 'desc': 'Tayland usulü pad thai', 'ingredients': ['Pirinç noodle', 'Karides', 'Yumurta', 'Fıstık', 'Tamarind sos'], 'instructions': ['Noodle hazırlayın', 'Karidesleri soteleyin', 'Yumurta ekleyin', 'Sosla karıştırın'], 'tags': ['thai', 'noodle', 'egzotik']},
      {'name': 'Tempura', 'desc': 'Çıtır sebze tempurası', 'ingredients': ['Karışık sebzeler', 'Tempura unu', 'Buz', 'Soya sosu'], 'instructions': ['Hamuru hazırlayın', 'Sebzeleri batırın', 'Kızartın', 'Sosla servis edin'], 'tags': ['tempura', 'çıtır', 'japon']},
    ],
    RecipeCategory.manti: [
      {'name': 'Kayseri Mantısı', 'desc': 'Geleneksel Kayseri mantısı', 'ingredients': ['Un', 'Yumurta', 'Kıyma', 'Soğan', 'Yoğurt', 'Sarımsaklı sos'], 'instructions': ['Hamuru yoğurun', 'Küçük kareler kesin', 'İçini doldurun', 'Haşlayın'], 'tags': ['kayseri', 'geleneksel', 'yoğurtlu']},
      {'name': 'Sinop Mantısı', 'desc': 'Cevizli Sinop mantısı', 'ingredients': ['Hamur', 'Ceviz', 'Yoğurt', 'Tereyağı'], 'instructions': ['Hamuru hazırlayın', 'Cevizle doldurun', 'Pişirin', 'Yoğurtla servis edin'], 'tags': ['sinop', 'cevizli', 'farklı']},
      {'name': 'Su Böreği Mantı', 'desc': 'Su böreği tadında mantı', 'ingredients': ['Yufka', 'Kıyma', 'Yoğurt', 'Tereyağı', 'Salça'], 'instructions': ['Yufkayı kesin', 'Doldurun', 'Haşlayın', 'Sosla servis edin'], 'tags': ['su böreği', 'pratik', 'ev yapımı']},
      {'name': 'Hingel', 'desc': 'Azerbaycan usulü hingel', 'ingredients': ['Hamur', 'Kıyma', 'Soğan', 'Yoğurt', 'Sarımsak'], 'instructions': ['Geniş hamur açın', 'Doldurun', 'Üçgen kesin', 'Haşlayıp servis edin'], 'tags': ['hingel', 'azerbaycan', 'yoğurtlu']},
    ],
    RecipeCategory.makarna: [
      {'name': 'Fettuccine Alfredo', 'desc': 'Kremalı fettuccine', 'ingredients': ['Fettuccine', 'Krema', 'Parmesan', 'Tereyağı', 'Sarımsak'], 'instructions': ['Makarnayı haşlayın', 'Sosu hazırlayın', 'Karıştırın', 'Peynir serpin'], 'tags': ['kremalı', 'italyan', 'peynirli']},
      {'name': 'Bolonez Makarna', 'desc': 'Kıymalı bolonez sos', 'ingredients': ['Spagetti', 'Kıyma', 'Domates sosu', 'Soğan', 'Sarımsak'], 'instructions': ['Kıymayı kavurun', 'Sosu ekleyin', 'Makarnayı haşlayın', 'Karıştırın'], 'tags': ['bolonez', 'kıymalı', 'klasik']},
      {'name': 'Penne Arrabbiata', 'desc': 'Acılı domates soslu penne', 'ingredients': ['Penne', 'Domates', 'Sarımsak', 'Acı biber', 'Fesleğen'], 'instructions': ['Sosu hazırlayın', 'Makarnayı pişirin', 'Karıştırın', 'Servis edin'], 'tags': ['acılı', 'domates', 'vegan']},
      {'name': 'Lazanya', 'desc': 'Katmerli fırın lazanyası', 'ingredients': ['Lazanya yaprağı', 'Beşamel', 'Kıyma', 'Domates sosu', 'Peynir'], 'instructions': ['Sosları hazırlayın', 'Katları dizin', 'Peynir serpin', 'Fırınlayın'], 'tags': ['lazanya', 'fırın', 'doyurucu']},
    ],
    RecipeCategory.denizUrunleri: [
      {'name': 'Levrek Buğulama', 'desc': 'Sebzeli levrek buğulama', 'ingredients': ['Levrek', 'Domates', 'Biber', 'Patates', 'Limon'], 'instructions': ['Balığı temizleyin', 'Sebzeleri dizin', 'Fırına verin', 'Buğulayın'], 'tags': ['levrek', 'buğulama', 'hafif']},
      {'name': 'Karides Güveç', 'desc': 'Fırında karides güveç', 'ingredients': ['Karides', 'Domates', 'Biber', 'Sarımsak', 'Peynir'], 'instructions': ['Karidesleri temizleyin', 'Güvece dizin', 'Peynir ekleyin', 'Fırınlayın'], 'tags': ['karides', 'güveç', 'peynirli']},
      {'name': 'Midye Tava', 'desc': 'Çıtır midye tava', 'ingredients': ['Midye', 'Un', 'Mısır unu', 'Yumurta', 'Tarator'], 'instructions': ['Midyeleri temizleyin', 'Paneleyin', 'Kızartın', 'Taratorla servis edin'], 'tags': ['midye', 'kızartma', 'çıtır']},
      {'name': 'Hamsi Tava', 'desc': 'Karadeniz usulü hamsi tava', 'ingredients': ['Hamsi', 'Mısır unu', 'Tuz', 'Yağ'], 'instructions': ['Hamsileri temizleyin', 'Una bulayın', 'Kızartın', 'Sıcak servis edin'], 'tags': ['hamsi', 'karadeniz', 'kızartma']},
    ],
    RecipeCategory.izgara: [
      {'name': 'Pirzola', 'desc': 'Izgarada kuzu pirzola', 'ingredients': ['Kuzu pirzola', 'Zeytinyağı', 'Biberiye', 'Sarımsak', 'Tuz'], 'instructions': ['Pirzolaları marine edin', 'Izgarayı ısıtın', 'Pişirin', 'Dinlendirin'], 'tags': ['kuzu', 'ızgara', 'et']},
      {'name': 'Izgara Köfte', 'desc': 'Mangalda ızgara köfte', 'ingredients': ['Kıyma', 'Soğan', 'Maydanoz', 'Baharat'], 'instructions': ['Kıymayı yoğurun', 'Şekil verin', 'Izgarada pişirin', 'Servis edin'], 'tags': ['köfte', 'mangal', 'ızgara']},
      {'name': 'Tavuk Kanat', 'desc': 'Baharatlı ızgara kanat', 'ingredients': ['Tavuk kanat', 'Sos', 'Baharat', 'Bal', 'Soya sosu'], 'instructions': ['Kanatları marine edin', 'Izgarada pişirin', 'Sosla karıştırın', 'Servis edin'], 'tags': ['kanat', 'baharatlı', 'ızgara']},
      {'name': 'Ciğer Şiş', 'desc': 'Arnavut ciğeri şiş', 'ingredients': ['Dana ciğer', 'Soğan', 'Maydanoz', 'Pul biber', 'Sumak'], 'instructions': ['Ciğeri küp kesin', 'Şişe geçirin', 'Izgarada pişirin', 'Soğanla servis edin'], 'tags': ['ciğer', 'şiş', 'meze']},
    ],
    RecipeCategory.tantuni: [
      {'name': 'Mersin Tantuni', 'desc': 'Orijinal Mersin tantunisi', 'ingredients': ['Dana eti', 'Soğan', 'Domates', 'Maydanoz', 'Lavaş'], 'instructions': ['Eti ince doğrayın', 'Sacda kavurun', 'Lavaşa sarın', 'Servis edin'], 'tags': ['mersin', 'orijinal', 'sokak']},
      {'name': 'Tavuk Tantuni', 'desc': 'Tavuk etli tantuni', 'ingredients': ['Tavuk göğsü', 'Soğan', 'Biber', 'Domates', 'Lavaş'], 'instructions': ['Tavuğu doğrayın', 'Sacda pişirin', 'Lavaşa sarın', 'Servis edin'], 'tags': ['tavuk', 'hafif', 'tantuni']},
      {'name': 'Karışık Tantuni', 'desc': 'Et ve tavuk karışık', 'ingredients': ['Dana eti', 'Tavuk', 'Soğan', 'Biber', 'Baharat'], 'instructions': ['Etleri karıştırın', 'Sacda pişirin', 'Lavaşa sarın', 'Servis edin'], 'tags': ['karışık', 'doyurucu', 'tantuni']},
      {'name': 'Tantuni Dürüm', 'desc': 'Tantuni dürüm versiyonu', 'ingredients': ['Dana eti', 'Lavaş', 'Soğan', 'Domates', 'Sos'], 'instructions': ['Tantuni hazırlayın', 'Dürüm yapın', 'Sıkı sarın', 'Servis edin'], 'tags': ['dürüm', 'pratik', 'sokak']},
    ],
    RecipeCategory.pilav: [
      {'name': 'Tereyağlı Pilav', 'desc': 'Klasik tereyağlı pilav', 'ingredients': ['Pirinç', 'Tereyağı', 'Tavuk suyu', 'Tuz'], 'instructions': ['Pirinci yıkayın', 'Tereyağında kavurun', 'Suyu ekleyin', 'Pişirin'], 'tags': ['klasik', 'tereyağlı', 'temel']},
      {'name': 'İç Pilav', 'desc': 'Düğün pilavı', 'ingredients': ['Pirinç', 'Ciğer', 'Fıstık', 'Kuş üzümü', 'Baharat'], 'instructions': ['Ciğeri kavurun', 'Pirinci ekleyin', 'Kuru yemişleri ekleyin', 'Pişirin'], 'tags': ['düğün', 'iç pilav', 'özel gün']},
      {'name': 'Bulgur Pilavı', 'desc': 'Domatesli bulgur pilavı', 'ingredients': ['Bulgur', 'Domates salçası', 'Soğan', 'Biber', 'Yağ'], 'instructions': ['Soğanı kavurun', 'Salçayı ekleyin', 'Bulguru ekleyin', 'Pişirin'], 'tags': ['bulgur', 'domatesli', 'sağlıklı']},
      {'name': 'Şehriyeli Pilav', 'desc': 'Tel şehriyeli pilav', 'ingredients': ['Pirinç', 'Tel şehriye', 'Tereyağı', 'Su'], 'instructions': ['Şehriyeyi kavurun', 'Pirinci ekleyin', 'Suyu dökün', 'Pişirin'], 'tags': ['şehriyeli', 'klasik', 'pratik']},
    ],
    RecipeCategory.meze: [
      {'name': 'Humus', 'desc': 'Tahinli humus', 'ingredients': ['Nohut', 'Tahin', 'Limon', 'Sarımsak', 'Zeytinyağı'], 'instructions': ['Nohutu haşlayın', 'Blenderdan geçirin', 'Tahin ekleyin', 'Servis edin'], 'tags': ['humus', 'vegan', 'ortadoğu']},
      {'name': 'Patlıcan Salatası', 'desc': 'Közlenmiş patlıcan salatası', 'ingredients': ['Patlıcan', 'Sarımsak', 'Yoğurt', 'Zeytinyağı'], 'instructions': ['Patlıcanları közleyin', 'Kabuklarını soyun', 'Ezin', 'Yoğurtla karıştırın'], 'tags': ['patlıcan', 'közleme', 'meze']},
      {'name': 'Acılı Ezme', 'desc': 'Antep usulü acılı ezme', 'ingredients': ['Domates', 'Biber', 'Ceviz', 'Nar ekşisi', 'Pul biber'], 'instructions': ['Malzemeleri doğrayın', 'Karıştırın', 'Baharatlayın', 'Servis edin'], 'tags': ['acılı', 'antep', 'ezme']},
      {'name': 'Haydari', 'desc': 'Sarımsaklı süzme yoğurt', 'ingredients': ['Süzme yoğurt', 'Sarımsak', 'Dereotu', 'Zeytinyağı'], 'instructions': ['Yoğurdu süzün', 'Sarımsak ezin', 'Karıştırın', 'Servis edin'], 'tags': ['haydari', 'yoğurtlu', 'meze']},
    ],
    RecipeCategory.tostSandvic: [
      {'name': 'Tost', 'desc': 'Klasik kaşarlı tost', 'ingredients': ['Tost ekmeği', 'Kaşar peyniri', 'Domates', 'Tereyağı'], 'instructions': ['Ekmeği yağlayın', 'Kaşar koyun', 'Domates ekleyin', 'Tost makinesinde pişirin'], 'tags': ['tost', 'kaşarlı', 'pratik']},
      {'name': 'Kumru', 'desc': 'İzmir kumrusu', 'ingredients': ['Kumru ekmeği', 'Sucuk', 'Kaşar', 'Domates', 'Biber'], 'instructions': ['Malzemeleri dizin', 'Ekmeğe yerleştirin', 'Preste pişirin', 'Servis edin'], 'tags': ['kumru', 'izmir', 'sokak']},
      {'name': 'Club Sandwich', 'desc': '3 katlı club sandviç', 'ingredients': ['Tost ekmeği', 'Hindi füme', 'Bacon', 'Marul', 'Domates'], 'instructions': ['Ekmekleri kızartın', 'Katları oluşturun', 'Kürdan ile tutturun', 'Servis edin'], 'tags': ['club', 'doyurucu', 'klasik']},
      {'name': 'Ayvalık Tost', 'desc': 'Meşhur Ayvalık tostu', 'ingredients': ['Tost ekmeği', 'Sucuk', 'Sosis', 'Kaşar', 'Turşu', 'Mısır'], 'instructions': ['Malzemeleri hazırlayın', 'Bol malzeme koyun', 'Preste pişirin', 'Sıcak servis edin'], 'tags': ['ayvalık', 'dolu', 'efsane']},
    ],
    RecipeCategory.pastaneFirin: [
      {'name': 'Poğaça', 'desc': 'Yumuşak peynirli poğaça', 'ingredients': ['Un', 'Yoğurt', 'Yağ', 'Maya', 'Beyaz peynir'], 'instructions': ['Hamuru yoğurun', 'Mayalayın', 'Şekil verin', 'Fırınlayın'], 'tags': ['poğaça', 'peynirli', 'kahvaltı']},
      {'name': 'Açma', 'desc': 'Yağlı yumuşak açma', 'ingredients': ['Un', 'Maya', 'Süt', 'Yağ', 'Şeker'], 'instructions': ['Hamuru hazırlayın', 'Mayalayın', 'Şekillendirin', 'Fırınlayın'], 'tags': ['açma', 'sade', 'kahvaltı']},
      {'name': 'Simit', 'desc': 'Çıtır İstanbul simidi', 'ingredients': ['Un', 'Maya', 'Pekmez', 'Susam', 'Su'], 'instructions': ['Hamuru yoğurun', 'Halka şekli verin', 'Pekmeze batırın', 'Fırınlayın'], 'tags': ['simit', 'istanbul', 'klasik']},
      {'name': 'Kurabiye', 'desc': 'Tereyağlı un kurabiyesi', 'ingredients': ['Un', 'Tereyağı', 'Pudra şekeri', 'Yumurta'], 'instructions': ['Yağı çırpın', 'Unu ekleyin', 'Şekil verin', 'Fırınlayın'], 'tags': ['kurabiye', 'tatlı', 'ikram']},
    ],
    RecipeCategory.kahve: [
      {'name': 'Türk Kahvesi', 'desc': 'Geleneksel Türk kahvesi', 'ingredients': ['Türk kahvesi', 'Su', 'Şeker'], 'instructions': ['Cezveye su koyun', 'Kahve ekleyin', 'Kısık ateşte pişirin', 'Köpüklü servis edin'], 'tags': ['türk', 'geleneksel', 'sıcak']},
      {'name': 'Latte', 'desc': 'Sütlü espresso latte', 'ingredients': ['Espresso', 'Süt', 'Süt köpüğü'], 'instructions': ['Espresso çekin', 'Sütü köpürtün', 'Birleştirin', 'Latte art yapın'], 'tags': ['latte', 'sütlü', 'espresso']},
      {'name': 'Cappuccino', 'desc': 'İtalyan usulü cappuccino', 'ingredients': ['Espresso', 'Buharla ısıtılmış süt', 'Köpük'], 'instructions': ['Espresso hazırlayın', 'Sütü köpürtün', 'Üzerine dökün', 'Servis edin'], 'tags': ['cappuccino', 'italyan', 'köpüklü']},
      {'name': 'Filtre Kahve', 'desc': 'Amerikan usulü filtre kahve', 'ingredients': ['Öğütülmüş kahve', 'Su'], 'instructions': ['Filtreyi yerleştirin', 'Kahveyi koyun', 'Sıcak suyu dökün', 'Demleyin'], 'tags': ['filtre', 'amerikan', 'sade']},
    ],
    RecipeCategory.kahvaltiBorek: [
      {'name': 'Su Böreği', 'desc': 'El açması su böreği', 'ingredients': ['Yufka', 'Beyaz peynir', 'Maydanoz', 'Yumurta', 'Süt'], 'instructions': ['Yufkaları haşlayın', 'Peynirle doldurun', 'Tepsiye dizin', 'Fırınlayın'], 'tags': ['su böreği', 'geleneksel', 'kahvaltı']},
      {'name': 'Sigara Böreği', 'desc': 'Çıtır sigara böreği', 'ingredients': ['Yufka', 'Beyaz peynir', 'Maydanoz'], 'instructions': ['Yufkayı kesin', 'Peynir koyun', 'Sarın', 'Kızartın'], 'tags': ['sigara', 'çıtır', 'kızartma']},
      {'name': 'Menemen', 'desc': 'Klasik Türk kahvaltısı menemen', 'ingredients': ['Yumurta', 'Domates', 'Biber', 'Soğan', 'Tereyağı'], 'instructions': ['Sebzeleri kavurun', 'Yumurtaları kırın', 'Karıştırın', 'Servis edin'], 'tags': ['menemen', 'kahvaltı', 'klasik']},
      {'name': 'Gözleme', 'desc': 'Köy usulü gözleme', 'ingredients': ['Hamur', 'Ispanak', 'Peynir', 'Patates'], 'instructions': ['Hamuru açın', 'İçini doldurun', 'Sacda pişirin', 'Tereyağı sürün'], 'tags': ['gözleme', 'köy', 'ev yapımı']},
    ],
    RecipeCategory.dunyaMutfagi: [
      {'name': 'Paella', 'desc': 'İspanyol usulü paella', 'ingredients': ['Pirinç', 'Karides', 'Midye', 'Tavuk', 'Safran'], 'instructions': ['Deniz ürünlerini pişirin', 'Pirinci ekleyin', 'Safran koyun', 'Pişirin'], 'tags': ['ispanyol', 'deniz', 'pirinç']},
      {'name': 'Tacos', 'desc': 'Meksika tacosu', 'ingredients': ['Taco kabuğu', 'Kıyma', 'Fasulye', 'Peynir', 'Salsa'], 'instructions': ['Kıymayı baharatlayın', 'Kabukları ısıtın', 'Doldurun', 'Servis edin'], 'tags': ['meksika', 'taco', 'baharatlı']},
      {'name': 'Curry', 'desc': 'Hint usulü tavuk curry', 'ingredients': ['Tavuk', 'Curry baharatı', 'Hindistan cevizi sütü', 'Soğan'], 'instructions': ['Tavuğu soteleyin', 'Baharat ekleyin', 'Sütü dökün', 'Pişirin'], 'tags': ['hint', 'curry', 'baharatlı']},
      {'name': 'Moussaka', 'desc': 'Yunan usulü musakka', 'ingredients': ['Patlıcan', 'Kıyma', 'Beşamel', 'Peynir'], 'instructions': ['Patlıcanları kızartın', 'Kıymayı kavurun', 'Katları dizin', 'Fırınlayın'], 'tags': ['yunan', 'patlıcan', 'fırın']},
    ],
    RecipeCategory.corba: [
      {'name': 'Mercimek Çorbası', 'desc': 'Klasik kırmızı mercimek çorbası', 'ingredients': ['Kırmızı mercimek', 'Soğan', 'Havuç', 'Patates', 'Salça'], 'instructions': ['Sebzeleri kavurun', 'Mercimeği ekleyin', 'Haşlayın', 'Blenderdan geçirin'], 'tags': ['mercimek', 'klasik', 'vegan']},
      {'name': 'Ezogelin Çorbası', 'desc': 'Geleneksel ezogelin', 'ingredients': ['Bulgur', 'Mercimek', 'Pirinç', 'Domates salçası', 'Nane'], 'instructions': ['Malzemeleri haşlayın', 'Salçayı kavurun', 'Birleştirin', 'Pişirin'], 'tags': ['ezogelin', 'doyurucu', 'geleneksel']},
      {'name': 'Tarhana Çorbası', 'desc': 'Ev yapımı tarhana çorbası', 'ingredients': ['Tarhana', 'Su', 'Tereyağı', 'Salça'], 'instructions': ['Tarhanayı suda eritin', 'Kaynatın', 'Tereyağlı sos ekleyin', 'Servis edin'], 'tags': ['tarhana', 'ev yapımı', 'geleneksel']},
      {'name': 'Tavuk Suyu Çorba', 'desc': 'Şifalı tavuk suyu çorbası', 'ingredients': ['Tavuk', 'Havuç', 'Kereviz', 'Şehriye', 'Limon'], 'instructions': ['Tavuğu haşlayın', 'Sebzeleri ekleyin', 'Şehriye pişirin', 'Limonla servis edin'], 'tags': ['tavuk suyu', 'şifalı', 'hafif']},
    ],
  };

  // ======================= REVIEW COMMENTS =======================

  final List<String> _positiveComments = [
    'Harika bir tarif! Kesinlikle tavsiye ederim.',
    'Çok lezzetli oldu, ailem bayıldı.',
    'Tarifi denedim, sonuç mükemmeldi.',
    'Açıklamalar çok net, kolayca yaptım.',
    'Bu tarifi favorilerime ekledim.',
    'Enfes bir lezzet, teşekkürler.',
    'Yıllardır aradığım tarif buymuş.',
    'Misafirlerime yaptım, çok beğendiler.',
    'Pratik ve lezzetli, süper!',
    'Anne yemeği tadında olmuş.',
    'Malzemeler kolay bulunuyor, tarif basit.',
    'Tam kıvamında oldu, elinize sağlık.',
    'Bu tarifi herkese öneriyorum.',
    'Beklentilerimi aştı, muhteşem!',
    'Çocuklarım bile severek yedi.',
  ];

  final List<String> _neutralComments = [
    'Fena değil, biraz daha baharat ekledim.',
    'Güzel bir tarif, ama ben biraz değiştirdim.',
    'İdare eder, beklediğim kadar değildi.',
    'Yapılabilir bir tarif.',
    'Orta seviye bir lezzet.',
    'Denemek isteyenler için uygun.',
    'Fiyat/performans açısından iyi.',
    'Basit ama doyurucu.',
  ];

  final List<String> _constructiveComments = [
    'Güzel tarif, ama tuz biraz fazla olmuş bende.',
    'Pişirme süresini biraz uzattım, daha iyi oldu.',
    'Malzeme oranlarını kendime göre ayarladım.',
    'İyi tarif, ama resimler daha detaylı olabilirdi.',
    'Lezzetli ama biraz yağlı buldum.',
  ];

  // ======================= MAIN SEED METHOD =======================

  /// Ana seed metodu - tüm verileri oluşturur
  Future<void> seedDatabase({int userCount = 100}) async {
    try {
      _report('Seed işlemi başlatılıyor...', 0.0);

      // Step 1: Create users
      _report('Kullanıcılar oluşturuluyor...', 0.1);
      final users = await _createUsers(userCount);
      _report('${users.length} kullanıcı oluşturuldu.', 0.3);

      // Step 2: Create recipes
      _report('Tarifler oluşturuluyor...', 0.35);
      final recipes = await _createRecipes(users);
      _report('${recipes.length} tarif oluşturuldu.', 0.5);

      // Step 3: Create reviews
      _report('Yorumlar oluşturuluyor...', 0.55);
      await _createReviews(users, recipes);
      _report('Yorumlar ve puanlamalar tamamlandı.', 0.8);

      // Step 4: Sync to Algolia
      _report('Algolia\'ya senkronize ediliyor...', 0.85);
      await _syncToAlgolia(users, recipes);
      _report('Algolia senkronizasyonu tamamlandı.', 1.0);

      _report('Tüm işlemler başarıyla tamamlandı!', 1.0);
    } catch (e) {
      _report('Hata: $e', -1);
      rethrow;
    }
  }

  void _report(String message, double progress) {
    print(message);
    onProgress?.call(message, progress);
  }

  Future<List<Map<String, dynamic>>> _createUsers(int count) async {
    final users = <Map<String, dynamic>>[];
    final usedNames = <String>{};
    final usedEmails = <String>{};

    for (int i = 0; i < count; i++) {
      String firstName, lastName, fullName;
      do {
        firstName = _turkishFirstNames[_random.nextInt(_turkishFirstNames.length)];
        lastName = _turkishLastNames[_random.nextInt(_turkishLastNames.length)];
        fullName = '$firstName $lastName';
      } while (usedNames.contains(fullName));
      usedNames.add(fullName);

      String email;
      do {
        email = '${_normalizeForEmail(firstName)}.${_normalizeForEmail(lastName)}${_random.nextInt(9999)}@seeduser.com';
      } while (usedEmails.contains(email));
      usedEmails.add(email);

      final bio = _turkishBios[_random.nextInt(_turkishBios.length)];
      final password = 'SeedUser${_random.nextInt(999999)}Pass';

      try {
        // Auth Admin API ile kullanıcı oluştur (trigger public.users'a da ekler)
        final response = await _supabase.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
            userMetadata: {'name': fullName},
          ),
        );

        if (response.user != null) {
          final userId = response.user!.id;

          // Public users tablosunu güncelle (bio, vs.)
          await _supabase.from('users').update({
            'bio': bio,
            'recipe_ids': <String>[],
            'follower_count': 0,
            'following_count': 0,
          }).eq('id', userId);

          final user = {
            'id': userId,
            'name': fullName,
            'email': email,
            'bio': bio,
          };
          users.add(user);

          if ((i + 1) % 10 == 0) {
            _report('   ${i + 1}/$count kullanıcı...', 0.1 + (i / count) * 0.2);
          }
        }
      } catch (e) {
        debugPrint('   Kullanıcı $fullName oluşturulamadı: $e');
      }
    }

    return users;
  }

  Future<List<Map<String, dynamic>>> _createRecipes(List<Map<String, dynamic>> users) async {
    final recipes = <Map<String, dynamic>>[];
    final categories = _recipesByCategory.keys.toList();

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final category = categories[i % categories.length];
      final categoryRecipes = _recipesByCategory[category]!;
      final recipeData = categoryRecipes[_random.nextInt(categoryRecipes.length)];

      final recipeId = _uuid.v4();
      final createdAt = DateTime.now().subtract(Duration(days: _random.nextInt(30)));

      final recipe = {
        'id': recipeId,
        'name': recipeData['name'],
        'description': recipeData['desc'],
        'ingredients': recipeData['ingredients'],
        'instructions': recipeData['instructions'],
        'image_url': null,
        'image_urls': <String>[],
        'video_urls': <String>[],
        'author_id': user['id'],
        'author_name': user['name'],
        'created_at': createdAt.toIso8601String(),
        'average_rating': 0.0,
        'review_count': 0,
        'category': category.name,
        'view_count': _random.nextInt(500) + 50,
        'favorite_count': _random.nextInt(100),
        'tags': recipeData['tags'],
      };

      try {
        await _supabase.from('recipes').insert(recipe);
        recipes.add(recipe);

        // Update user's recipe_ids
        await _supabase.from('users').update({
          'recipe_ids': [recipeId]
        }).eq('id', user['id']);

        if ((i + 1) % 10 == 0) {
          _report('   ${i + 1}/${users.length} tarif...', 0.35 + (i / users.length) * 0.15);
        }
      } catch (e) {
        debugPrint('   Tarif ${recipeData['name']} oluşturulamadı: $e');
      }
    }

    return recipes;
  }

  Future<void> _createReviews(List<Map<String, dynamic>> users, List<Map<String, dynamic>> recipes) async {
    int totalReviews = 0;
    final allComments = [..._positiveComments, ..._positiveComments, ..._neutralComments, ..._constructiveComments];

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final reviewCount = _random.nextInt(16) + 15; // 15-30 arası
      final availableRecipes = recipes.where((r) => r['author_id'] != user['id']).toList();
      availableRecipes.shuffle();
      final recipesToReview = availableRecipes.take(reviewCount).toList();

      for (final recipe in recipesToReview) {
        final rating = ((_random.nextDouble() * 2 + 3) * 2).round() / 2; // 3-5 arası, 0.5 adımlarla
        final comment = allComments[_random.nextInt(allComments.length)];
        final createdAt = DateTime.now().subtract(Duration(
          days: _random.nextInt(30),
          hours: _random.nextInt(24),
        ));

        final review = {
          'id': _uuid.v4(),
          'recipe_id': recipe['id'],
          'user_id': user['id'],
          'user_name': user['name'],
          'rating': rating,
          'comment': comment,
          'created_at': createdAt.toIso8601String(),
        };

        try {
          await _supabase.from('reviews').insert(review);
          totalReviews++;
        } catch (e) {
          // Skip duplicates
        }
      }

      if ((i + 1) % 10 == 0) {
        _report('   ${i + 1}/${users.length} kullanıcı yorumları...', 0.55 + (i / users.length) * 0.25);
      }
    }

    _report('   Toplam $totalReviews yorum eklendi.', 0.78);

    // Update recipe ratings
    _report('   Tarif puanları güncelleniyor...', 0.79);
    for (final recipe in recipes) {
      try {
        final reviews = await _supabase
            .from('reviews')
            .select('rating')
            .eq('recipe_id', recipe['id']);

        if (reviews.isNotEmpty) {
          final ratings = (reviews as List).map((r) => (r['rating'] as num).toDouble()).toList();
          final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

          await _supabase.from('recipes').update({
            'average_rating': double.parse(avgRating.toStringAsFixed(2)),
            'review_count': ratings.length,
          }).eq('id', recipe['id']);
        }
      } catch (e) {
        debugPrint('   Tarif puanı güncellenemedi: $e');
      }
    }
  }

  Future<void> _syncToAlgolia(List<Map<String, dynamic>> users, List<Map<String, dynamic>> recipes) async {
    // Sync users
    _report('   Kullanıcılar Algolia\'ya ekleniyor...', 0.86);
    for (final user in users) {
      try {
        final appUser = app_user.User.fromMap(user);
        await _algoliaService.saveUser(appUser);
      } catch (e) {
        // Ignore
      }
    }

    // Sync recipes
    _report('   Tarifler Algolia\'ya ekleniyor...', 0.92);
    for (final recipeMap in recipes) {
      try {
        final freshRecipe = await _supabase
            .from('recipes')
            .select()
            .eq('id', recipeMap['id'])
            .single();

        final recipe = Recipe.fromMap(freshRecipe);
        await _algoliaService.saveRecipe(recipe);
      } catch (e) {
        debugPrint('   Algolia sync hatası: $e');
      }
    }
  }

  String _normalizeForEmail(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c');
  }
}

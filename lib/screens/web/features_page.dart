import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'components/web_layout.dart';

class FeaturesPage extends StatelessWidget {
  final Function(String)? onNavigate;

  const FeaturesPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return WebLayoutScrollable(
      onNavigate: onNavigate,
      children: [
        // Hero Section
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.darkRed],
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : 24,
            vertical: 80,
          ),
          child: Center(
            child: Column(
              children: [
                Text(
                  'Özellikler',
                  style: TextStyle(
                    fontSize: isDesktop ? 48 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Look & Cook ile neler yapabilirsiniz?',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Features List
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: Responsive.contentMaxWidth(context),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 80,
              ),
              child: Column(
                children: [
                  _FeatureSection(
                    isReversed: false,
                    icon: Icons.explore,
                    title: 'Tarif Keşfet',
                    description: 'Binlerce tarif arasından arama yapın, kategorilere göre filtreleyin ve yeni lezzetler keşfedin. '
                        'Popüler tarifler, en yüksek puanlılar ve yeni eklenenler arasından seçim yapın.',
                    features: [
                      'Kategoriye göre filtreleme',
                      'Puan ve popülerliğe göre sıralama',
                      'Gelişmiş arama',
                      'Tarif önerileri',
                    ],
                  ),
                  const SizedBox(height: 80),
                  _FeatureSection(
                    isReversed: true,
                    icon: Icons.add_photo_alternate,
                    title: 'Tarif Paylaş',
                    description: 'Kendi tariflerinizi fotoğraflarla birlikte paylaşın. Malzemeler, yapılış adımları ve püf noktalarını ekleyin. '
                        'Videolu anlatım desteği ile tariflerinizi daha etkileyici hale getirin.',
                    features: [
                      'Çoklu fotoğraf yükleme',
                      'Adım adım tarif yazımı',
                      'Video desteği',
                      'Kategori ve etiket ekleme',
                    ],
                  ),
                  const SizedBox(height: 80),
                  _FeatureSection(
                    isReversed: false,
                    icon: Icons.people,
                    title: 'Topluluk',
                    description: 'Diğer yemek tutkunlarını takip edin, tariflerine yorum yapın ve beğenin. '
                        'Takip ettiklerinizin yeni tariflerinden haberdar olun.',
                    features: [
                      'Kullanıcı takip sistemi',
                      'Yorum ve beğeni',
                      'Tarif puanlama',
                      'Aktivite bildirimleri',
                    ],
                  ),
                  const SizedBox(height: 80),
                  _FeatureSection(
                    isReversed: true,
                    icon: Icons.bookmark,
                    title: 'Kaydet ve Düzenle',
                    description: 'Beğendiğiniz tarifleri kaydedin, koleksiyonlar oluşturun. '
                        'Kendi tariflerinizi istediğiniz zaman düzenleyin veya güncelleyin.',
                    features: [
                      'Favori tarifleri kaydetme',
                      'Koleksiyon oluşturma',
                      'Tarif düzenleme',
                      'Çevrimdışı erişim',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // CTA Section
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.darkRed],
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : 24,
            vertical: 80,
          ),
          child: Column(
            children: [
              Text(
                'Hemen Deneyin!',
                style: TextStyle(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tüm özellikler ücretsiz',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => onNavigate?.call('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  'Ücretsiz Başla',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  final bool isReversed;
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const _FeatureSection({
    required this.isReversed,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppTheme.primaryRed, size: 28),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textLight,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryRed, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );

    final visual = Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 80,
          color: AppTheme.primaryRed.withOpacity(0.3),
        ),
      ),
    );

    if (!isDesktop) {
      return Column(
        children: [visual, const SizedBox(height: 32), content],
      );
    }

    return Row(
      children: isReversed
          ? [
              Expanded(child: visual),
              const SizedBox(width: 60),
              Expanded(child: content),
            ]
          : [
              Expanded(child: content),
              const SizedBox(width: 60),
              Expanded(child: visual),
            ],
    );
  }
}

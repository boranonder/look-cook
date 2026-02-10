import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'components/web_layout.dart';

class LandingPage extends StatelessWidget {
  final Function(String)? onNavigate;

  const LandingPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return WebLayoutScrollable(
      onNavigate: onNavigate,
      children: [
        _HeroSection(onNavigate: onNavigate),
        _FeaturesSection(),
        _HowItWorksSection(),
        _StatsSection(),
        _TestimonialsSection(),
        _DownloadSection(),
        _CTASection(onNavigate: onNavigate),
      ],
    );
  }
}

// Hero Section
class _HeroSection extends StatelessWidget {
  final Function(String)? onNavigate;

  const _HeroSection({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryRed,
            AppTheme.darkRed,
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : 24,
            vertical: isDesktop ? 100 : 60,
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildHeroContent(context)),
                    const SizedBox(width: 60),
                    Expanded(child: _buildHeroImage(context)),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroContent(context),
                    const SizedBox(height: 40),
                    _buildHeroImage(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Lezzetli Tarifleri\nKeşfet ve Paylaş',
          style: TextStyle(
            fontSize: isDesktop ? 52 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Binlerce tarif arasından ilham al, kendi tariflerini paylaş ve yemek tutkunlarıyla bir araya gel.',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 16,
            color: Colors.white.withOpacity(0.9),
            height: 1.6,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => onNavigate?.call('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Hemen Başla'),
            ),
            OutlinedButton(
              onPressed: () => onNavigate?.call('/explore'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Tarifleri Keşfet'),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Store Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _StoreButton(
              icon: Icons.apple,
              label: 'App Store',
              onTap: () => _launchUrl('https://apps.apple.com'),
            ),
            _StoreButton(
              icon: Icons.android,
              label: 'Google Play',
              onTap: () => _launchUrl('https://play.google.com'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Container(
      height: Responsive.isDesktop(context) ? 500 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.white.withOpacity(0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_iphone,
                  size: Responsive.isDesktop(context) ? 120 : 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Uygulama Önizleme',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StoreButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Features Section
class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
            vertical: isMobile ? 48 : 80,
          ),
          child: Column(
            children: [
              Text(
                'Neden Look & Cook?',
                style: TextStyle(
                  fontSize: isDesktop ? 40 : (isMobile ? 24 : 28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Yemek yapmanın keyfini yeniden keşfedin',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 14,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 32 : 60),
              Wrap(
                spacing: isMobile ? 16 : 30,
                runSpacing: isMobile ? 16 : 30,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureCard(
                    icon: Icons.explore,
                    title: 'Binlerce Tarif',
                    description:
                        'Her damak zevkine uygun binlerce tarif arasından seçim yapın.',
                  ),
                  _FeatureCard(
                    icon: Icons.camera_alt,
                    title: 'Kolay Paylaşım',
                    description:
                        'Fotoğraf çekin, tarifi yazın ve anında paylaşın.',
                  ),
                  _FeatureCard(
                    icon: Icons.people,
                    title: 'Topluluk',
                    description:
                        'Yemek tutkunlarıyla tanışın, ilham alın ve verin.',
                  ),
                  _FeatureCard(
                    icon: Icons.bookmark,
                    title: 'Favoriler',
                    description:
                        'Beğendiğiniz tarifleri kaydedin, koleksiyonlar oluşturun.',
                  ),
                  _FeatureCard(
                    icon: Icons.star,
                    title: 'Değerlendirmeler',
                    description:
                        'Tarifleri puanlayın ve yorumlarla katkıda bulunun.',
                  ),
                  _FeatureCard(
                    icon: Icons.category,
                    title: 'Kategoriler',
                    description:
                        'Kahvaltı, öğle yemeği, tatlılar ve daha fazlası.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isMobile ? double.infinity : 320,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.primaryRed : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: _isHovered ? Colors.white : AppTheme.primaryRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isHovered ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isHovered
                    ? Colors.white.withOpacity(0.9)
                    : AppTheme.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// How It Works Section
class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: Colors.grey[50],
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
            vertical: isMobile ? 48 : 80,
          ),
          child: Column(
            children: [
              Text(
                'Nasıl Çalışır?',
                style: TextStyle(
                  fontSize: isDesktop ? 40 : (isMobile ? 24 : 28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 32 : 60),
              isDesktop
                  ? Row(
                      children: [
                        Expanded(child: _StepCard(number: '1', title: 'Kayıt Ol', description: 'Ücretsiz hesap oluşturun')),
                        _buildArrow(),
                        Expanded(child: _StepCard(number: '2', title: 'Keşfet', description: 'Tariflere göz atın')),
                        _buildArrow(),
                        Expanded(child: _StepCard(number: '3', title: 'Paylaş', description: 'Kendi tariflerinizi ekleyin')),
                        _buildArrow(),
                        Expanded(child: _StepCard(number: '4', title: 'Bağlan', description: 'Topluluğa katılın')),
                      ],
                    )
                  : Column(
                      children: [
                        _StepCard(number: '1', title: 'Kayıt Ol', description: 'Ücretsiz hesap oluşturun'),
                        const SizedBox(height: 24),
                        _StepCard(number: '2', title: 'Keşfet', description: 'Tariflere göz atın'),
                        const SizedBox(height: 24),
                        _StepCard(number: '3', title: 'Paylaş', description: 'Kendi tariflerinizi ekleyin'),
                        const SizedBox(height: 24),
                        _StepCard(number: '4', title: 'Bağlan', description: 'Topluluğa katılın'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.arrow_forward,
        color: AppTheme.primaryRed,
        size: 24,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

// Stats Section
class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: AppTheme.primaryRed,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: isMobile ? 40 : 60,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: isMobile
              ? Wrap(
                  spacing: 40,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatItem(value: '10K+', label: 'Tarif', isMobile: true),
                    _StatItem(value: '5K+', label: 'Kullanıcı', isMobile: true),
                    _StatItem(value: '50K+', label: 'Yorum', isMobile: true),
                    _StatItem(value: '4.8', label: 'Puan', isMobile: true),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(value: '10K+', label: 'Tarif'),
                    _StatItem(value: '5K+', label: 'Kullanıcı'),
                    _StatItem(value: '50K+', label: 'Yorum'),
                    _StatItem(value: '4.8', label: 'Puan'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isMobile;

  const _StatItem({
    required this.value,
    required this.label,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 28 : 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

// Testimonials Section
class _TestimonialsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
            vertical: isMobile ? 48 : 80,
          ),
          child: Column(
            children: [
              Text(
                'Kullanıcılarımız Ne Diyor?',
                style: TextStyle(
                  fontSize: isDesktop ? 40 : (isMobile ? 24 : 28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 32 : 60),
              Wrap(
                spacing: isMobile ? 16 : 30,
                runSpacing: isMobile ? 16 : 30,
                alignment: WrapAlignment.center,
                children: [
                  _TestimonialCard(
                    name: 'Ayşe Y.',
                    comment: 'Yemek yapmayı sevmezdim ama bu uygulama sayesinde mutfakta vakit geçirmek çok keyifli hale geldi!',
                    rating: 5,
                  ),
                  _TestimonialCard(
                    name: 'Mehmet K.',
                    comment: 'Tariflerin adım adım anlatımı harika. Artık profesyonel gibi yemek yapıyorum.',
                    rating: 5,
                  ),
                  _TestimonialCard(
                    name: 'Zeynep A.',
                    comment: 'Kendi tariflerimi paylaşmak ve geri bildirim almak çok motive edici.',
                    rating: 5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String comment;
  final int rating;

  const _TestimonialCard({
    required this.name,
    required this.comment,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: isMobile ? double.infinity : 350,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 20,
                color: index < rating ? Colors.amber : Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '"$comment"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textDark,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}

// Download Section
class _DownloadSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: Colors.grey[50],
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
            vertical: isMobile ? 48 : 80,
          ),
          child: Column(
            children: [
              Text(
                'Uygulamayı İndirin',
                style: TextStyle(
                  fontSize: isDesktop ? 40 : (isMobile ? 24 : 28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'iOS ve Android için ücretsiz',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 14,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 24 : 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _AppStoreButton(
                    icon: Icons.apple,
                    store: 'App Store',
                    subtitle: "Download on the",
                  ),
                  _AppStoreButton(
                    icon: Icons.android,
                    store: 'Google Play',
                    subtitle: 'GET IT ON',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppStoreButton extends StatefulWidget {
  final IconData icon;
  final String store;
  final String subtitle;

  const _AppStoreButton({
    required this.icon,
    required this.store,
    required this.subtitle,
  });

  @override
  State<_AppStoreButton> createState() => _AppStoreButtonState();
}

class _AppStoreButtonState extends State<_AppStoreButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.primaryRed : AppTheme.textDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
                Text(
                  widget.store,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// CTA Section
class _CTASection extends StatelessWidget {
  final Function(String)? onNavigate;

  const _CTASection({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.darkRed],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
        vertical: isMobile ? 48 : 80,
      ),
      child: Column(
        children: [
          Text(
            'Hemen Başlayın!',
            style: TextStyle(
              fontSize: isDesktop ? 40 : (isMobile ? 24 : 28),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ücretsiz hesap oluşturun ve lezzetli dünyamıza katılın',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          ElevatedButton(
            onPressed: () => onNavigate?.call('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Ücretsiz Kayıt Ol'),
          ),
        ],
      ),
    );
  }
}

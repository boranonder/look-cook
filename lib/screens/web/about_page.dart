import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'components/web_layout.dart';

class AboutPage extends StatelessWidget {
  final Function(String)? onNavigate;

  const AboutPage({super.key, this.onNavigate});

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
                  'Hakkımızda',
                  style: TextStyle(
                    fontSize: isDesktop ? 48 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Look & Cook\'un hikayesini keşfedin',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Story Section
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 80,
              ),
              child: Column(
                children: [
                  Text(
                    'Hikayemiz',
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Look & Cook, yemek yapma tutkusunu paylaşan insanları bir araya getirmek amacıyla kuruldu. '
                    'Amacımız, herkesin kolayca tarif paylaşabileceği, yeni lezzetler keşfedebileceği ve '
                    'mutfakta ilham alabileceği bir platform oluşturmaktı.\n\n'
                    'Bugün, binlerce kullanıcımız ve on binlerce tarif ile büyüyen bir topluluk haline geldik. '
                    'Her gün yeni tarifler ekleniyor, yorumlar yapılıyor ve yemek tutkunları birbirleriyle bağlantı kuruyor.\n\n'
                    'Biz sadece bir tarif uygulaması değiliz - biz bir yemek topluluğuyuz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textLight,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Values Section
        Container(
          width: double.infinity,
          color: Colors.grey[50],
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
                  Text(
                    'Değerlerimiz',
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: [
                      _ValueCard(
                        icon: Icons.favorite,
                        title: 'Tutku',
                        description: 'Yemek yapmayı seviyoruz ve bu tutkuyu paylaşmak istiyoruz.',
                      ),
                      _ValueCard(
                        icon: Icons.people,
                        title: 'Topluluk',
                        description: 'Birlikte daha güçlüyüz. Paylaşmak öğrenmenin en iyi yolu.',
                      ),
                      _ValueCard(
                        icon: Icons.lightbulb,
                        title: 'İnovasyon',
                        description: 'Sürekli gelişiyor, yeni özellikler ekliyoruz.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Team Section
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
                  Text(
                    'Ekibimiz',
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Look & Cook\'u sizler için geliştiren tutkulu ekip',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: [
                      _TeamMember(
                        name: 'Boran Önder',
                        role: 'Kurucu & Geliştirici',
                        initial: 'B',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ValueCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final String initial;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryRed,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

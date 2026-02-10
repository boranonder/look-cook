import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class WebFooter extends StatelessWidget {
  final Function(String)? onNavigate;

  const WebFooter({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.textDark,
      child: Column(
        children: [
          // Main Footer Content
          Container(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.isDesktop(context) ? 64 : 24,
              vertical: 48,
            ),
            child: Responsive.isDesktop(context)
                ? _buildDesktopFooter(context)
                : _buildMobileFooter(context),
          ),

          // Bottom Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Center(
              child: Text(
                '© ${DateTime.now().year} Look & Cook. Tüm hakları saklıdır.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Section
        Expanded(
          flex: 2,
          child: _buildBrandSection(),
        ),

        // Quick Links
        Expanded(
          child: _buildLinksSection(
            title: 'Hızlı Linkler',
            links: [
              _FooterLink('Ana Sayfa', () => onNavigate?.call('/')),
              _FooterLink('Keşfet', () => onNavigate?.call('/explore')),
              _FooterLink('Özellikler', () => onNavigate?.call('/features')),
              _FooterLink('Hakkımızda', () => onNavigate?.call('/about')),
            ],
          ),
        ),

        // Support
        Expanded(
          child: _buildLinksSection(
            title: 'Destek',
            links: [
              _FooterLink('İletişim', () => onNavigate?.call('/contact')),
              _FooterLink('SSS', () => onNavigate?.call('/faq')),
              _FooterLink('Yardım Merkezi', () => onNavigate?.call('/help')),
            ],
          ),
        ),

        // Legal
        Expanded(
          child: _buildLinksSection(
            title: 'Yasal',
            links: [
              _FooterLink('Gizlilik Politikası', () => onNavigate?.call('/privacy')),
              _FooterLink('Kullanım Koşulları', () => onNavigate?.call('/terms')),
              _FooterLink('Çerez Politikası', () => onNavigate?.call('/cookies')),
            ],
          ),
        ),

        // Download
        Expanded(
          child: _buildDownloadSection(),
        ),
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      children: [
        _buildBrandSection(),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLinksSection(
                title: 'Hızlı Linkler',
                links: [
                  _FooterLink('Ana Sayfa', () => onNavigate?.call('/')),
                  _FooterLink('Keşfet', () => onNavigate?.call('/explore')),
                  _FooterLink('Hakkımızda', () => onNavigate?.call('/about')),
                ],
              ),
            ),
            Expanded(
              child: _buildLinksSection(
                title: 'Yasal',
                links: [
                  _FooterLink('Gizlilik', () => onNavigate?.call('/privacy')),
                  _FooterLink('Koşullar', () => onNavigate?.call('/terms')),
                  _FooterLink('İletişim', () => onNavigate?.call('/contact')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildDownloadSection(),
      ],
    );
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Look & Cook',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Lezzetli tarifleri keşfet, kendi tariflerini paylaş ve yemek tutkunlarıyla bağlantı kur.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        // Social Links
        Row(
          children: [
            _SocialButton(
              icon: Icons.facebook,
              onTap: () => _launchUrl('https://facebook.com'),
            ),
            const SizedBox(width: 12),
            _SocialButton(
              icon: Icons.camera_alt,
              onTap: () => _launchUrl('https://instagram.com'),
            ),
            const SizedBox(width: 12),
            _SocialButton(
              icon: Icons.alternate_email,
              onTap: () => _launchUrl('https://twitter.com'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinksSection({
    required String title,
    required List<_FooterLink> links,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FooterLinkWidget(link: link),
            )),
      ],
    );
  }

  Widget _buildDownloadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uygulamayı İndir',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _StoreButton(
          label: 'App Store',
          icon: Icons.apple,
          onTap: () => _launchUrl('https://apps.apple.com'),
        ),
        const SizedBox(height: 12),
        _StoreButton(
          label: 'Google Play',
          icon: Icons.android,
          onTap: () => _launchUrl('https://play.google.com'),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _FooterLink {
  final String title;
  final VoidCallback onTap;

  _FooterLink(this.title, this.onTap);
}

class _FooterLinkWidget extends StatefulWidget {
  final _FooterLink link;

  const _FooterLinkWidget({required this.link});

  @override
  State<_FooterLinkWidget> createState() => _FooterLinkWidgetState();
}

class _FooterLinkWidgetState extends State<_FooterLinkWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.link.onTap,
        child: Text(
          widget.link.title,
          style: TextStyle(
            color: _isHovered ? AppTheme.primaryRed : Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryRed : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _StoreButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_StoreButton> createState() => _StoreButtonState();
}

class _StoreButtonState extends State<_StoreButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryRed : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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

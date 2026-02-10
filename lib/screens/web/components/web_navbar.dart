import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/auth_provider.dart';

class WebNavbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogoTap;
  final Function(String)? onNavigate;

  const WebNavbar({
    super.key,
    this.onLogoTap,
    this.onNavigate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Logo
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onLogoTap ?? () => onNavigate?.call('/'),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.primaryRed,
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Look & Cook',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Navigation Links (Desktop only)
              if (Responsive.isDesktop(context)) ...[
                _NavLink(
                  title: 'Ana Sayfa',
                  onTap: () => onNavigate?.call('/'),
                ),
                _NavLink(
                  title: 'Özellikler',
                  onTap: () => onNavigate?.call('/features'),
                ),
                _NavLink(
                  title: 'Keşfet',
                  onTap: () => onNavigate?.call('/explore'),
                ),
                _NavLink(
                  title: 'Hakkımızda',
                  onTap: () => onNavigate?.call('/about'),
                ),
                _NavLink(
                  title: 'İletişim',
                  onTap: () => onNavigate?.call('/contact'),
                ),
                const SizedBox(width: 24),
              ],

              // Auth Buttons
              if (isLoggedIn) ...[
                _NavIconButton(
                  icon: Icons.search,
                  onTap: () => onNavigate?.call('/search'),
                ),
                const SizedBox(width: 8),
                _NavIconButton(
                  icon: Icons.add_circle_outline,
                  onTap: () => onNavigate?.call('/add-recipe'),
                ),
                const SizedBox(width: 8),
                _UserAvatar(
                  onTap: () => onNavigate?.call('/profile'),
                  userName: authProvider.currentUser?.name ?? 'U',
                  imageUrl: authProvider.currentUser?.profileImageUrl,
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => onNavigate?.call('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRed,
                    side: const BorderSide(color: AppTheme.primaryRed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Giriş Yap'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => onNavigate?.call('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Kayıt Ol'),
                ),
              ],

              // Mobile Menu Button
              if (!Responsive.isDesktop(context)) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _showMobileMenu(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MobileMenuItem(
              title: 'Ana Sayfa',
              icon: Icons.home,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/');
              },
            ),
            _MobileMenuItem(
              title: 'Özellikler',
              icon: Icons.star,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/features');
              },
            ),
            _MobileMenuItem(
              title: 'Keşfet',
              icon: Icons.explore,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/explore');
              },
            ),
            _MobileMenuItem(
              title: 'Hakkımızda',
              icon: Icons.info,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/about');
              },
            ),
            _MobileMenuItem(
              title: 'İletişim',
              icon: Icons.mail,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/contact');
              },
            ),
            const Divider(height: 32),
            _MobileMenuItem(
              title: 'Gizlilik Politikası',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/privacy');
              },
            ),
            _MobileMenuItem(
              title: 'Kullanım Koşulları',
              icon: Icons.description_outlined,
              onTap: () {
                Navigator.pop(context);
                onNavigate?.call('/terms');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _NavLink({
    required this.title,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _isHovered ? AppTheme.primaryRed : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryRed.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? AppTheme.primaryRed : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final VoidCallback onTap;
  final String userName;
  final String? imageUrl;

  const _UserAvatar({
    required this.onTap,
    required this.userName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primaryRed,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MobileMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryRed),
      title: Text(title),
      onTap: onTap,
    );
  }
}

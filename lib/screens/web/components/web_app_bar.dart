import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String)? onNavigate;
  final VoidCallback? onLogout;

  const WebAppBar({
    super.key,
    this.onNavigate,
    this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Back to Landing
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onNavigate?.call('/'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.primaryRed,
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Look & Cook',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Quick nav links
            _QuickNavButton(
              icon: Icons.home_outlined,
              tooltip: 'Ana Sayfa',
              onTap: () => onNavigate?.call('/'),
            ),
            const SizedBox(width: 8),
            _QuickNavButton(
              icon: Icons.info_outline,
              tooltip: 'Hakkımızda',
              onTap: () => onNavigate?.call('/about'),
            ),
            const SizedBox(width: 8),
            _QuickNavButton(
              icon: Icons.mail_outline,
              tooltip: 'İletişim',
              onTap: () => onNavigate?.call('/contact'),
            ),

            const SizedBox(width: 16),
            Container(
              height: 24,
              width: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 16),

            // User info
            if (authProvider.currentUser != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryRed,
                backgroundImage: authProvider.currentUser!.profileImageUrl != null
                    ? NetworkImage(authProvider.currentUser!.profileImageUrl!)
                    : null,
                child: authProvider.currentUser!.profileImageUrl == null
                    ? Text(
                        authProvider.currentUser!.name.isNotEmpty
                            ? authProvider.currentUser!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                authProvider.currentUser!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 16),
            ],

            // Logout button
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Çıkış'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNavButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_QuickNavButton> createState() => _QuickNavButtonState();
}

class _QuickNavButtonState extends State<_QuickNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
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
              size: 20,
              color: _isHovered ? AppTheme.primaryRed : AppTheme.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart' show globalAuthRefreshToken;

/// Email dogrulama sayfasi - sadece email linki ile erisilebilir
class AuthVerifyPage extends StatefulWidget {
  final VoidCallback onGoToLogin;

  const AuthVerifyPage({super.key, required this.onGoToLogin});

  @override
  State<AuthVerifyPage> createState() => _AuthVerifyPageState();
}

class _AuthVerifyPageState extends State<AuthVerifyPage> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _processAuthToken();
  }

  Future<void> _processAuthToken() async {
    debugPrint('=== AuthVerifyPage START ===');
    debugPrint('globalAuthRefreshToken exists: ${globalAuthRefreshToken != null}');

    // Supabase'in URL'yi islemesi icin kisa bekle
    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Mevcut session/user kontrol et (Supabase otomatik isledi mi?)
    final existingUser = Supabase.instance.client.auth.currentUser;
    if (existingUser != null) {
      debugPrint('User found: ${existingUser.email}, verified: ${existingUser.emailConfirmedAt != null}');
      if (existingUser.emailConfirmedAt != null) {
        await _handleVerification(existingUser);
        return;
      }
    }

    // 2. Global token var mi? (main.dart'ta yakalandi)
    if (globalAuthRefreshToken != null && globalAuthRefreshToken!.isNotEmpty) {
      debugPrint('Using captured globalAuthRefreshToken');
      try {
        final response = await Supabase.instance.client.auth.setSession(globalAuthRefreshToken!);
        debugPrint('setSession success: ${response.session != null}');
        if (response.session != null && response.user != null) {
          await _handleVerification(response.user);
          return;
        }
      } catch (e) {
        debugPrint('setSession error: $e');
      }
    }

    // 3. PKCE code var mi? (fallback)
    final code = Uri.base.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      debugPrint('PKCE code found - assuming verification happened server-side');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _message = 'E-posta adresiniz dogrulandi!\nArtik giris yapabilirsiniz.';
        });
      }
      return;
    }

    // Token bulunamadi
    debugPrint('No valid token found');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'Dogrulama linki gecersiz veya suresi dolmus.';
      });
    }
  }

  Future<void> _handleVerification(User? user) async {
    if (user == null || user.emailConfirmedAt == null) return;
    if (!_isLoading) return; // Zaten islendi

    try {
      // Kullanici zaten var mi kontrol et
      final existing = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // Kullanici yok, olustur
        final metadata = user.userMetadata;
        final name = metadata?['name'] ?? user.email?.split('@').first ?? 'User';

        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'name': name,
          'email': user.email,
          'bio': '',
          'profile_image_url': null,
          'follower_count': 0,
          'following_count': 0,
          'recipe_count': 0,
          'is_admin': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Cikis yap - kullanici giris ekranindan girecek
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _message = 'E-posta adresiniz dogrulandi!\nArtik giris yapabilirsiniz.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _message = 'Bir hata olustu: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryRed, AppTheme.darkRed],
          ),
        ),
        child: Center(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _isLoading ? _buildLoading() : _buildResult(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppTheme.primaryRed),
        SizedBox(height: 24),
        Text(
          'E-posta dogrulanıyor...',
          style: TextStyle(fontSize: 16, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _isSuccess ? Colors.green[50] : Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isSuccess ? Icons.check_circle : Icons.error,
            size: 48,
            color: _isSuccess ? Colors.green[600] : Colors.red[600],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isSuccess ? 'Basarili!' : 'Hata',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppTheme.textLight),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onGoToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Giris Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart' show globalAuthRefreshToken;

/// Sifre sifirlama sayfasi - sadece email linki ile erisilebilir
class AuthResetPasswordPage extends StatefulWidget {
  final VoidCallback onGoToLogin;

  const AuthResetPasswordPage({super.key, required this.onGoToLogin});

  @override
  State<AuthResetPasswordPage> createState() => _AuthResetPasswordPageState();
}

class _AuthResetPasswordPageState extends State<AuthResetPasswordPage> {
  bool _isLoading = true;
  bool _isValidToken = false;
  bool _isSuccess = false;
  String _message = '';

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processAuthToken();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _processAuthToken() async {
    await _listenToAuth();
  }

  Future<void> _listenToAuth() async {
    debugPrint('=== AuthResetPasswordPage START ===');
    debugPrint('globalAuthRefreshToken exists: ${globalAuthRefreshToken != null}');

    // Supabase'in URL'yi islemesi icin kisa bekle
    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Mevcut session kontrol et (Supabase otomatik isledi mi?)
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      debugPrint('Existing session found');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isValidToken = true;
        });
      }
      return;
    }

    // 2. Global token var mi? (main.dart'ta yakalandi)
    if (globalAuthRefreshToken != null && globalAuthRefreshToken!.isNotEmpty) {
      debugPrint('Using captured globalAuthRefreshToken');
      try {
        final response = await Supabase.instance.client.auth.setSession(globalAuthRefreshToken!);
        debugPrint('setSession success: ${response.session != null}');
        if (response.session != null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isValidToken = true;
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('setSession error: $e');
      }
    }

    // Token bulunamadi
    debugPrint('No valid token/session found');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isValidToken = false;
        _message = 'Sifre sifirlama linki gecersiz veya suresi dolmus.';
      });
    }
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Validasyon
    if (password.length < 8) {
      setState(() => _errorMessage = 'Sifre en az 8 karakter olmali');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Sifreler eslesmiyor');
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      // Cikis yap
      await Supabase.instance.client.auth.signOut();

      setState(() {
        _isUpdating = false;
        _isValidToken = false;
        _isSuccess = true;
        _message = 'Sifreniz basariyla guncellendi!\nYeni sifrenizle giris yapabilirsiniz.';
      });
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _errorMessage = 'Sifre guncellenemedi. Lutfen tekrar deneyin.';
      });
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
          child: SingleChildScrollView(
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
              child: _isLoading
                  ? _buildLoading()
                  : _isValidToken
                      ? _buildPasswordForm()
                      : _buildResult(),
            ),
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
          'Dogrulaniyor...',
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

  Widget _buildPasswordForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            size: 48,
            color: Colors.blue[600],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Yeni Sifre Belirle',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Yeni sifrenizi girin',
          style: TextStyle(fontSize: 14, color: AppTheme.textLight),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Yeni Sifre',
            hintText: 'En az 8 karakter',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Sifre Tekrar',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppTheme.primaryRed.withOpacity(0.6),
            ),
            child: _isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Sifreyi Guncelle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

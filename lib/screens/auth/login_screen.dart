import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showEmailVerificationMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _showEmailVerificationMessage = false;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }

    // Comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }
    if (!_isLogin) {
      // Stronger validation for registration
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Şifre en az bir büyük harf içermeli';
      }
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return 'Şifre en az bir küçük harf içermeli';
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Şifre en az bir rakam içermeli';
      }
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }
    if (value != _passwordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim gerekli';
    }
    if (value.length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }
    if (value.length > 50) {
      return 'İsim en fazla 50 karakter olabilir';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isLogin) {
        // Login
        final success = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!success && mounted) {
          _showErrorSnackBar('E-posta veya şifre hatalı');
        }
      } else {
        // Register - returns: null = error, true = logged in, false = needs verification
        final result = await authProvider.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (mounted) {
          if (result == false) {
            // Needs email verification
            setState(() {
              _showEmailVerificationMessage = true;
            });
            _showSuccessSnackBar(
              'Hesabınız oluşturuldu! E-posta adresinize gönderilen doğrulama linkine tıklayın.',
            );
          } else if (result == true) {
            // Successfully registered and logged in (shouldn't happen with email verification)
            _showSuccessSnackBar('Hesabınız oluşturuldu!');
          } else {
            // Error
            _showErrorSnackBar('Kayıt oluşturulamadı. Bu e-posta zaten kullanılıyor olabilir.');
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        // Handle specific auth errors
        if (e.message.contains('doğrulanmamış') || e.message.contains('Email not confirmed')) {
          setState(() {
            _showEmailVerificationMessage = true;
          });
          _showErrorSnackBar('E-posta doğrulanmamış. Lütfen e-posta kutunuzu kontrol edin.');
        } else {
          _showErrorSnackBar(e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Bir hata oluştu. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Lütfen e-posta adresinizi girin');
      return;
    }

    if (_validateEmail(email) != null) {
      _showErrorSnackBar('Geçerli bir e-posta adresi girin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.resetPassword(email);

      if (mounted) {
        _showSuccessSnackBar(
          'Şifre sıfırlama linki e-posta adresinize gönderildi',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Şifre sıfırlama e-postası gönderilemedi');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryRed,
              AppTheme.darkRed,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo and Title
                  _buildHeader(l10n),

                  const SizedBox(height: 32),

                  // Email Verification Message
                  if (_showEmailVerificationMessage)
                    _buildEmailVerificationCard()
                  else
                    // Auth Form
                    _buildAuthForm(l10n, size),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.appName,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Pacifico',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lezzetli tarifleri keşfet ve paylaş',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read,
              size: 48,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'E-posta Doğrulama Gerekli',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_emailController.text} adresine bir doğrulama e-postası gönderdik.\n\nLütfen e-postanızdaki linke tıklayarak hesabınızı doğrulayın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showEmailVerificationMessage = false;
                _isLogin = true;
              });
            },
            icon: const Icon(Icons.login),
            label: const Text('Giriş Yap'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              // Resend verification email
              try {
                await Supabase.instance.client.auth.resend(
                  type: OtpType.signup,
                  email: _emailController.text.trim(),
                  emailRedirectTo: 'https://lookcookapp.com',
                );
                if (mounted) {
                  _showSuccessSnackBar('Doğrulama e-postası tekrar gönderildi');
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('E-posta gönderilemedi');
                }
              }
            },
            child: const Text('Doğrulama e-postasını tekrar gönder'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm(AppLocalizations l10n, Size size) {
    return Container(
      width: size.width > 400 ? 400 : double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Name field (only for registration)
            if (!_isLogin) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: _validateEmail,
            ),

            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: _validatePassword,
            ),

            // Confirm Password (only for registration)
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
              ),
            ],

            // Password requirements hint (for registration)
            if (!_isLogin) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Şifre gereksinimleri:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• En az 8 karakter\n• En az bir büyük harf\n• En az bir küçük harf\n• En az bir rakam',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Forgot password (only for login)
            if (_isLogin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  child: const Text('Şifremi Unuttum'),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Toggle auth mode
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Hesabınız yok mu? ' : 'Zaten hesabınız var mı? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Terms (for registration)
            if (!_isLogin) ...[
              const SizedBox(height: 12),
              Text(
                'Kayıt olarak Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmiş olursunuz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

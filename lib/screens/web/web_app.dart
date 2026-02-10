import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show globalAuthCallbackType;
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../main/main_navigation_screen.dart';
import 'components/web_app_bar.dart';
import 'landing_page.dart';
import 'about_page.dart';
import 'contact_page.dart';
import 'features_page.dart';
import 'privacy_page.dart';
import 'terms_page.dart';
import 'auth_verify_page.dart';
import 'auth_reset_password_page.dart';

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  String _currentRoute = '/';
  String? _authType;

  @override
  void initState() {
    super.initState();
    _checkAuthCallback();
    _listenToAuthChanges();
  }

  void _checkAuthCallback() {
    // Path'den sayfa tipini kontrol et
    final uri = Uri.base;
    final path = uri.path;

    debugPrint('=== AUTH CALLBACK CHECK ===');
    debugPrint('URL: ${uri.toString()}');
    debugPrint('Path: $path');

    if (path == '/verify' || path == '/verify/') {
      debugPrint('>>> EMAIL VERIFY page requested');
      setState(() {
        _authType = 'signup';
        _currentRoute = '/auth/verify';
      });
    } else if (path == '/reset' || path == '/reset/') {
      debugPrint('>>> PASSWORD RESET page requested');
      setState(() {
        _authType = 'recovery';
        _currentRoute = '/auth/reset-password';
      });
    }
  }

  void _listenToAuthChanges() {
    // Auth state degisikliklerini dinle (ek guvenlik)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('Auth state change: ${data.event}');
    });
  }

  void _navigate(String route) {
    setState(() {
      _currentRoute = route;
      _authType = null;
    });
  }

  void _goToLogin() {
    setState(() {
      _currentRoute = '/login';
      _authType = null;
    });
    // URL'yi temizle
    _clearUrlFragment();
  }

  void _clearUrlFragment() {
    // Browser URL'sini temizle (fragment'i kaldir)
    // Bu web-only bir islem
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    setState(() {
      _currentRoute = '/';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // GIZLI SAYFALAR - sadece email linki ile erisilebilir
    // Token yoksa bu sayfalara erisim yok
    if (_currentRoute == '/auth/verify' && _authType == 'signup') {
      return AuthVerifyPage(onGoToLogin: _goToLogin);
    }
    if (_currentRoute == '/auth/reset-password' && _authType == 'recovery') {
      return AuthResetPasswordPage(onGoToLogin: _goToLogin);
    }

    // Eger biri direkt /auth/... URL'sine gitmeye calisirsa ana sayfaya yonlendir
    if (_currentRoute.startsWith('/auth/')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigate('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Auth gerektiren rotalar
    if (_currentRoute == '/app' ||
        _currentRoute == '/profile' ||
        _currentRoute == '/add-recipe' ||
        _currentRoute == '/search') {
      if (!authProvider.isAuthenticated) {
        return _buildLoginScreen();
      }
      return _buildAppWithBar();
    }

    // Login/Register
    if (_currentRoute == '/login' || _currentRoute == '/register') {
      if (authProvider.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigate('/app');
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _buildLoginScreen();
    }

    // Public sayfalar
    switch (_currentRoute) {
      case '/':
        return LandingPage(onNavigate: _navigate);
      case '/about':
        return AboutPage(onNavigate: _navigate);
      case '/contact':
        return ContactPage(onNavigate: _navigate);
      case '/features':
        return FeaturesPage(onNavigate: _navigate);
      case '/privacy':
        return PrivacyPage(onNavigate: _navigate);
      case '/terms':
        return TermsPage(onNavigate: _navigate);
      case '/explore':
        if (authProvider.isAuthenticated) {
          return _buildAppWithBar();
        }
        return LandingPage(onNavigate: _navigate);
      default:
        return LandingPage(onNavigate: _navigate);
    }
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      body: Stack(
        children: [
          const LoginScreen(),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _navigate('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 18, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          'Ana Sayfa',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppWithBar() {
    return Scaffold(
      body: Column(
        children: [
          WebAppBar(
            onNavigate: _navigate,
            onLogout: _logout,
          ),
          Expanded(
            child: MainNavigationScreen(key: mainNavigationKey),
          ),
        ],
      ),
    );
  }
}

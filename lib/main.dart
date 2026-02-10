import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/follow_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_navigation_screen.dart';
import 'screens/web/web_app.dart';
import 'services/algolia_service.dart';

// Global: Web icin auth callback (Supabase islemeden once yakala)
String? globalAuthCallbackType;
String? globalAuthRefreshToken;
String? globalAuthAccessToken;

// Auth callback screen for mobile deep links
class AuthCallbackScreen extends StatefulWidget {
  final String type;
  final VoidCallback onComplete;

  const AuthCallbackScreen({
    super.key,
    required this.type,
    required this.onComplete,
  });

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = '';
  String? _errorMessage;

  // For password reset
  bool _showPasswordForm = false;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCallback() async {
    // Give Supabase time to process the tokens
    await Future.delayed(const Duration(milliseconds: 1500));

    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('Auth callback - Session: ${session != null}, User: ${user?.email}, Type: ${widget.type}');

    if (widget.type == 'recovery') {
      setState(() {
        _isLoading = false;
        if (session != null) {
          _showPasswordForm = true;
          _isSuccess = true;
          _message = 'Yeni şifrenizi belirleyin';
        } else {
          _isSuccess = false;
          _errorMessage = 'Şifre sıfırlama linki geçersiz veya süresi dolmuş.';
        }
      });
    } else if (widget.type == 'signup') {
      // Email verification - create user record and sign out
      if (user != null && user.emailConfirmedAt != null) {
        try {
          final existing = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (existing == null) {
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
            debugPrint('User record created for ${user.email}');
          }

          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          debugPrint('Error in email verification: $e');
        }
      }

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = 'E-posta adresiniz doğrulandı!\nArtık giriş yapabilirsiniz.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _isSuccess = session != null;
        _message = _isSuccess ? 'İşlem başarılı!' : 'Link geçersiz veya süresi dolmuş.';
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Şifre en az 8 karakter olmalı');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      await Supabase.instance.client.auth.signOut();

      setState(() {
        _showPasswordForm = false;
        _message = 'Şifreniz başarıyla değiştirildi!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Şifre değiştirilemedi: $e';
      });
    } finally {
      setState(() => _isUpdating = false);
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? _buildLoading()
                  : _showPasswordForm
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 24),
        Text(
          'İşleniyor...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.error,
            size: 64,
            color: _isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            _isSuccess ? _message : 'Bir Hata Oluştu',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          ],
          if (_isSuccess && widget.type == 'signup') ...[
            const SizedBox(height: 12),
            const Text(
              'Artık uygulamaya giriş yapabilirsiniz.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onComplete,
            child: const Text('Giriş Ekranına Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_reset, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Yeni Şifre Belirle',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Şifre Tekrar',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updatePassword,
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Şifreyi Değiştir'),
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WEB: URL'yi Supabase islemeden ONCE yakala
  if (kIsWeb) {
    _captureAuthCallbackFromUrl();
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase - implicit flow (PKCE farkli tarayici/cihazda calismaz)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
    debug: true,
  );

  // Initialize Algolia
  AlgoliaService().initialize();

  runApp(const LookCookApp());
}

// Web icin URL'den auth type ve token'lari yakala
void _captureAuthCallbackFromUrl() {
  try {
    // Uri.base ile URL'yi al
    final fullUrl = Uri.base.toString();
    debugPrint('=== CAPTURING AUTH CALLBACK ===');
    debugPrint('Full URL: $fullUrl');

    // # isaretinden sonrasini manuel parse et
    final hashIndex = fullUrl.indexOf('#');
    if (hashIndex != -1 && hashIndex < fullUrl.length - 1) {
      final fragment = fullUrl.substring(hashIndex + 1);
      debugPrint('Fragment length: ${fragment.length}');

      final params = Uri.splitQueryString(fragment);

      final type = params['type'];
      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'];

      debugPrint('Type: $type');
      debugPrint('Has access_token: ${accessToken != null && accessToken.isNotEmpty}');
      debugPrint('Has refresh_token: ${refreshToken != null && refreshToken.isNotEmpty}');

      // Token'lari kaydet
      if (accessToken != null && accessToken.isNotEmpty) {
        globalAuthAccessToken = accessToken;
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        globalAuthRefreshToken = refreshToken;
      }

      // Type'i kaydet
      if (type == 'signup' || type == 'magiclink' || type == 'email') {
        globalAuthCallbackType = 'signup';
        debugPrint('>>> globalAuthCallbackType = signup');
      } else if (type == 'recovery') {
        globalAuthCallbackType = 'recovery';
        debugPrint('>>> globalAuthCallbackType = recovery');
      } else if (accessToken != null && accessToken.isNotEmpty) {
        globalAuthCallbackType = 'signup';
        debugPrint('>>> globalAuthCallbackType = signup (has token)');
      }
    } else {
      debugPrint('No fragment in URL');
    }
  } catch (e) {
    debugPrint('Error capturing auth callback: $e');
  }
}

class LookCookApp extends StatelessWidget {
  const LookCookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        ChangeNotifierProvider(create: (context) => FollowProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  String? _lastLoadedUserId;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Deep link handling
  String? _authCallbackType;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initDeepLinks();
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened from a link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('Initial deep link: $initialLink');
      _handleDeepLink(initialLink);
    }

    // Listen for incoming links while app is running
    _appLinks.uriLinkStream.listen((Uri uri) {
      debugPrint('Stream deep link: $uri');
      _handleDeepLink(uri);
    });

    // Also listen for auth state changes to detect successful auth
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('Mobile auth state change: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn && _authCallbackType == 'signup') {
        // Email verified - user just signed in via email link
        _handleEmailVerified(data.session?.user);
      } else if (data.event == AuthChangeEvent.passwordRecovery) {
        // Password recovery - show password form
        setState(() {
          _authCallbackType = 'recovery';
        });
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    debugPrint('Fragment: ${uri.fragment}');
    debugPrint('Query params: ${uri.queryParameters}');

    String? type;

    // Check query parameters first (our custom ?type=signup)
    type = uri.queryParameters['type'];
    debugPrint('Type from query: $type');

    // Also check fragment for type (Supabase adds it there too)
    if (type == null && uri.fragment.isNotEmpty) {
      final params = Uri.splitQueryString(uri.fragment);
      type = params['type'];
      debugPrint('Type from fragment: $type');
    }

    if (type != null) {
      debugPrint('Setting _authCallbackType to: $type');
      setState(() {
        _authCallbackType = type;
      });
    }
  }

  void _handleEmailVerified(User? user) async {
    if (user == null) return;
    debugPrint('Email verified for user: ${user.email}');

    // Create user record if needed
    if (user.emailConfirmedAt != null) {
      try {
        final existing = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (existing == null) {
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
      } catch (e) {
        debugPrint('Error creating user record: $e');
      }

      // Sign out so user goes through normal login
      await Supabase.instance.client.auth.signOut();
    }
  }

  void _clearAuthCallback() {
    setState(() {
      _authCallbackType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, AuthProvider>(
      builder: (context, languageProvider, authProvider, child) {
        // Load user data when authenticated and not already loaded for this user
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          final userId = authProvider.currentUser!.id;
          if (_lastLoadedUserId != userId) {
            _lastLoadedUserId = userId;
            // Schedule the data loading after the build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final followProvider = Provider.of<FollowProvider>(context, listen: false);
                followProvider.loadFollowData(userId);
                followProvider.subscribeToRealtimeUpdates(userId);

                final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
                favoritesProvider.loadUserFavorites(userId);
              }
            });
          }
        } else if (!authProvider.isAuthenticated && _lastLoadedUserId != null) {
          // User logged out - clear the loaded user ID and data
          _lastLoadedUserId = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final followProvider = Provider.of<FollowProvider>(context, listen: false);
              followProvider.clearData();

              final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
              favoritesProvider.clearFavorites();
            }
          });
        }

        // Handle auth callback for mobile
        Widget home;
        if (kIsWeb) {
          home = const WebApp();
        } else if (_authCallbackType != null) {
          // Show auth callback screen
          home = AuthCallbackScreen(
            type: _authCallbackType!,
            onComplete: _clearAuthCallback,
          );
        } else if (authProvider.isAuthenticated) {
          home = MainNavigationScreen(key: mainNavigationKey);
        } else {
          home = const LoginScreen();
        }

        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Look & Cook',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        );
      },
    );
  }
}

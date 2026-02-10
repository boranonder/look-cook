import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  app_user.User? _currentUser;
  bool _isLoading = false;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((AuthState state) async {
      final user = state.session?.user;

      // EMAIL DOGRULANMAMISSA GIRIS YOK
      if (user != null && user.emailConfirmedAt != null) {
        // Email dogrulanmis - public.users'dan kullanici bilgisi al
        _currentUser = await _authService.getUserDocument(user.id);

        // Eger public.users'da yoksa olustur (ilk giris)
        if (_currentUser == null) {
          final metadata = user.userMetadata;
          final name = metadata?['name'] ?? user.email?.split('@').first ?? 'User';
          await _authService.createUserDocument(user.id, user.email!, name);
          _currentUser = await _authService.getUserDocument(user.id);
        }
      } else {
        // Email dogrulanmamis veya session yok - giris yok
        _currentUser = null;
        if (user != null && user.emailConfirmedAt == null) {
          // Dogrulanmamis kullanici - cikis yap
          await Supabase.instance.client.auth.signOut();
        }
      }
      notifyListeners();
    });

    // Mevcut session kontrol et
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    // EMAIL DOGRULANMAMISSA GIRIS YOK
    if (user != null && user.emailConfirmedAt != null) {
      _currentUser = await _authService.getUserDocument(user.id);

      if (_currentUser == null) {
        final metadata = user.userMetadata;
        final name = metadata?['name'] ?? user.email?.split('@').first ?? 'User';
        await _authService.createUserDocument(user.id, user.email!, name);
        _currentUser = await _authService.getUserDocument(user.id);
      }
    } else if (user != null && user.emailConfirmedAt == null) {
      // Dogrulanmamis - cikis yap
      await Supabase.instance.client.auth.signOut();
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithEmailAndPassword(email, password);
      if (result.user != null) {
        _currentUser = await _authService.getUserDocument(result.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Returns: null = error, true = success (logged in), false = needs email confirmation
  Future<bool?> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.registerWithEmailAndPassword(email, password, name);

      if (result.response.user != null) {
        if (result.needsEmailConfirmation) {
          // Kullanıcı kaydedildi ama email doğrulaması gerekiyor
          // NOT: users tablosuna henüz kayıt YAPILMADI
          // Email doğrulandıktan sonra ilk girişte oluşturulacak
          _isLoading = false;
          notifyListeners();
          return false; // Email doğrulaması gerekiyor
        } else {
          // Email zaten doğrulanmış (normalde olmaz)
          _currentUser = await _authService.getUserDocument(result.response.user!.id);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Register error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null; // Hata oluştu
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(app_user.User user) async {
    await _authService.updateUserDocument(user);
    _currentUser = user;
    notifyListeners();
  }

  void updateCurrentUser(app_user.User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    await _authService.deleteAccount();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  Future<void> resendVerificationEmail(String email) async {
    await _authService.resendVerificationEmail(email);
  }

  Future<bool> verifyPassword(String password) async {
    return await _authService.verifyPassword(password);
  }
}

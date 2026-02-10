import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if current user's email is verified
  bool get isEmailVerified {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);

    // EMAIL DOGRULANMAMISSA GIRIS YOK - KESINLIKLE
    if (response.user != null && response.user!.emailConfirmedAt == null) {
      await _supabase.auth.signOut();
      throw AuthException('Email adresiniz doğrulanmamış. Lütfen email kutunuzu kontrol edip doğrulama linkine tıklayın.');
    }

    // Email dogrulanmis - public.users tablosunda kayit var mi kontrol et
    if (response.user != null) {
      final existingUser = await getUserDocument(response.user!.id);
      if (existingUser == null) {
        // Ilk giris - public.users tablosuna kayit olustur
        final metadata = response.user!.userMetadata;
        final name = metadata?['name'] ?? email.split('@').first;
        await createUserDocument(response.user!.id, email, name);
      }
    }

    return response;
  }

  // Redirect URL'ler - web ve mobil ayni
  static const String _verifyRedirectUrl = 'https://look-cook.pages.dev/verify';
  static const String _resetRedirectUrl = 'https://look-cook.pages.dev/reset';

  // Register - sadece Supabase auth'a kaydet, users tablosuna KAYDETME
  // Users tablosuna kayıt, email doğrulandıktan sonra ilk girişte yapılacak
  Future<({AuthResponse response, bool needsEmailConfirmation, String name})> registerWithEmailAndPassword(
      String email, String password, String name) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _verifyRedirectUrl,
      data: {'name': name}, // İsmi metadata olarak sakla, sonra kullanacağız
    );

    bool needsConfirmation = false;

    if (response.user != null) {
      // Email confirmation gerekiyor mu kontrol et
      needsConfirmation = response.user!.emailConfirmedAt == null;

      // Confirmation gerekiyorsa sign out yap
      // Users tablosuna KAYIT YAPMA - email doğrulanınca yapılacak
      if (needsConfirmation) {
        await _supabase.auth.signOut();
      } else {
        // Email zaten doğrulanmış (normalde olmaz ama olursa)
        await createUserDocument(response.user!.id, email, name);
      }
    }

    return (response: response, needsEmailConfirmation: needsConfirmation, name: name);
  }

  Future<void> createUserDocument(String id, String email, String name) async {
    try {
      await _supabase.from('users').insert({
        'id': id,
        'name': name,
        'email': email,
        'bio': '',
        'profile_image_url': null,
        'follower_count': 0,
        'following_count': 0,
        'recipe_count': 0,
        'is_admin': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Create user document error: $e');
    }
  }

  Future<app_user.User?> getUserDocument(String uid) async {
    try {
      final response = await _supabase.from('users').select().eq('id', uid).maybeSingle();
      if (response != null) {
        return app_user.User.fromMap(_convertSnakeCase(response));
      }
      return null;
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  Future<void> updateUserDocument(app_user.User user) async {
    try {
      await _supabase.from('users').update({
        'name': user.name,
        'bio': user.bio,
        'profile_image_url': user.profileImageUrl,
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Update user error: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('recipes').delete().eq('author_id', user.id);
        await _supabase.from('users').delete().eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: _resetRedirectUrl,
    );
  }

  // Verify current password by re-authenticating
  Future<bool> verifyPassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) return false;

      final response = await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      debugPrint('Verify password error: $e');
      return false;
    }
  }

  // Update password (after reset link clicked)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _verifyRedirectUrl,
    );
  }

  Map<String, dynamic> _convertSnakeCase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'email': data['email'],
      'profileImageUrl': data['profile_image_url'],
      'bio': data['bio'] ?? '',
      'createdAt': data['created_at'] != null
          ? DateTime.parse(data['created_at']).millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      'recipeIds': data['recipe_ids'] ?? [],
      'followerCount': data['follower_count'] ?? 0,
      'followingCount': data['following_count'] ?? 0,
      'recipeCount': data['recipe_count'] ?? 0,
      'isAdmin': data['is_admin'] ?? false,
    };
  }
}

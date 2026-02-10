import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user by ID
  Future<app_user.User?> getUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return app_user.User.fromMap(_convertSnakeCase(response));
      }
      return null;
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  // Get user stream
  Stream<app_user.User?> getUserStream(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
      if (data.isNotEmpty) {
        return app_user.User.fromMap(_convertSnakeCase(data.first));
      }
      return null;
    });
  }

  // Update user
  Future<void> updateUser(app_user.User user) async {
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

  // Search users by name
  Future<List<app_user.User>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List)
          .map((data) => app_user.User.fromMap(_convertSnakeCase(data)))
          .toList();
    } catch (e) {
      debugPrint('Search users error: $e');
      return [];
    }
  }

  // Get top chefs
  Future<List<app_user.User>> getTopChefs({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .gt('recipe_count', 0)
          .order('follower_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => app_user.User.fromMap(_convertSnakeCase(data)))
          .toList();
    } catch (e) {
      debugPrint('Get top chefs error: $e');
      return [];
    }
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

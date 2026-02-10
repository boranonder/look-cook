import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Add recipe to favorites
  // Note: favorite_count is updated by database trigger
  Future<void> addToFavorites(String userId, String recipeId) async {
    try {
      await _supabase.from('user_favorites').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    } catch (e) {
      debugPrint('Add to favorites error: $e');
    }
  }

  // Remove recipe from favorites
  // Note: favorite_count is updated by database trigger
  Future<void> removeFromFavorites(String userId, String recipeId) async {
    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
    } catch (e) {
      debugPrint('Remove from favorites error: $e');
    }
  }

  // Check if recipe is in favorites
  Future<bool> isFavorite(String userId, String recipeId) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check favorite error: $e');
      return false;
    }
  }

  // Get user's favorite recipe IDs
  Future<List<String>> getUserFavoriteIds(String userId) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select('recipe_id')
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      return (response as List).map((item) => item['recipe_id'] as String).toList();
    } catch (e) {
      debugPrint('Get user favorites error: $e');
      return [];
    }
  }

  // Get user's favorite recipes as stream
  Stream<List<String>> getUserFavorites(String userId) {
    return _supabase
        .from('user_favorites')
        .stream(primaryKey: ['user_id', 'recipe_id'])
        .eq('user_id', userId)
        .order('added_at', ascending: false)
        .map((data) => data.map((item) => item['recipe_id'] as String).toList());
  }

  // Get most favorited recipes
  Stream<List<String>> getMostFavoritedRecipes({int limit = 10}) {
    return _supabase
        .from('recipes')
        .stream(primaryKey: ['id'])
        .order('favorite_count', ascending: false)
        .limit(limit)
        .map((data) => data.map((item) => item['id'] as String).toList());
  }
}

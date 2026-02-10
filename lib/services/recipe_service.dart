import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';

class RecipeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'recipes';

  // Get all recipes
  Stream<List<Recipe>> getRecipes({int limit = 50}) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) => data.map((item) => Recipe.fromMap(_convertSnakeCase(item))).toList());
  }

  // Get recipes by user ID
  Stream<List<Recipe>> getUserRecipes(String userId, {int limit = 50}) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('author_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) => data.map((item) => Recipe.fromMap(_convertSnakeCase(item))).toList());
  }

  // Get recipes by multiple user IDs (for following feed)
  Future<List<Recipe>> getRecipesByAuthors(List<String> authorIds, {int limit = 50}) async {
    if (authorIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from(_table)
          .select()
          .inFilter('author_id', authorIds)
          .order('created_at', ascending: false)
          .limit(limit);

      if (response is List) {
        return response.map((data) => Recipe.fromMap(_convertSnakeCase(data as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get recipes by authors error: $e');
      return [];
    }
  }

  // Get top rated recipes
  Stream<List<Recipe>> getTopRatedRecipes({int limit = 20}) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('average_rating', ascending: false)
        .order('review_count', ascending: false)
        .limit(limit)
        .map((data) => data.map((item) => Recipe.fromMap(_convertSnakeCase(item))).toList());
  }

  // Get most reviewed recipes
  Stream<List<Recipe>> getMostReviewedRecipes({int limit = 20}) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('review_count', ascending: false)
        .limit(limit)
        .map((data) => data.map((item) => Recipe.fromMap(_convertSnakeCase(item))).toList());
  }

  // Get trending recipes (recent recipes with activity)
  Stream<List<Recipe>> getTrendingRecipes({int limit = 20}) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('view_count', ascending: false)
        .order('review_count', ascending: false)
        .limit(limit)
        .map((data) => data.map((item) => Recipe.fromMap(_convertSnakeCase(item))).toList());
  }

  // Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(RecipeCategory category, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('category', category.name)
          .order('created_at', ascending: false)
          .limit(limit);

      if (response is List) {
        return response.map((data) => Recipe.fromMap(_convertSnakeCase(data as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get recipes by category error: $e');
      return [];
    }
  }

  // Add new recipe
  Future<String?> addRecipe(Recipe recipe) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(recipe.toMap())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Add recipe error: $e');
      return null;
    }
  }

  // Update recipe
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _supabase
          .from(_table)
          .update(recipe.toMap())
          .eq('id', recipe.id);
    } catch (e) {
      debugPrint('Update recipe error: $e');
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('id', recipeId);
    } catch (e) {
      debugPrint('Delete recipe error: $e');
    }
  }

  // Get single recipe with reviews
  Future<Recipe?> getRecipe(String recipeId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', recipeId)
          .maybeSingle();

      if (response == null) return null;

      // Also fetch reviews for this recipe
      final reviewsResponse = await _supabase
          .from('reviews')
          .select()
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false);

      final reviewsList = reviewsResponse is List ? reviewsResponse : [];
      final reviews = reviewsList.map((r) {
        return {
          'id': r['id'],
          'recipeId': r['recipe_id'],
          'userId': r['user_id'],
          'userName': r['user_name'],
          'rating': r['rating'],
          'comment': r['comment'],
          'createdAt': r['created_at'] != null
              ? DateTime.parse(r['created_at']).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
        };
      }).toList();

      final recipeData = _convertSnakeCase(response);
      recipeData['reviews'] = reviews;

      return Recipe.fromMap(recipeData);
    } catch (e) {
      debugPrint('Get recipe error: $e');
      return null;
    }
  }

  // Increment views count
  Future<void> incrementViews(String recipeId) async {
    try {
      await _supabase.rpc('increment_recipe_views', params: {'recipe_id': recipeId});
    } catch (e) {
      debugPrint('Increment views error: $e');
    }
  }

  // Like/Unlike recipe (Beğenme)
  Future<void> toggleLike(String recipeId, String userId) async {
    try {
      final existing = await _supabase
          .from('recipe_likes')
          .select()
          .eq('recipe_id', recipeId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Like
        await _supabase
            .from('recipe_likes')
            .insert({
              'recipe_id': recipeId,
              'user_id': userId,
            });
      } else {
        // Unlike
        await _supabase
            .from('recipe_likes')
            .delete()
            .eq('recipe_id', recipeId)
            .eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('Toggle like error: $e');
    }
  }

  // Check if user liked recipe
  Future<bool> isLiked(String recipeId, String userId) async {
    try {
      final response = await _supabase
          .from('recipe_likes')
          .select()
          .eq('recipe_id', recipeId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Is liked error: $e');
      return false;
    }
  }

  // Get like count for a recipe
  Future<int> getLikeCount(String recipeId) async {
    try {
      final response = await _supabase
          .from('recipe_likes')
          .select()
          .eq('recipe_id', recipeId);

      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Get like count error: $e');
      return 0;
    }
  }

  // Helper to convert snake_case to camelCase
  Map<String, dynamic> _convertSnakeCase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'description': data['description'],
      'ingredients': data['ingredients'],
      'instructions': data['instructions'],
      'imageUrl': data['image_url'],
      'imageUrls': data['image_urls'] ?? [],
      'videoUrls': data['video_urls'] ?? [],
      'authorId': data['author_id'],
      'authorName': data['author_name'],
      'createdAt': data['created_at'] != null
          ? DateTime.parse(data['created_at']).millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      'averageRating': data['average_rating'] ?? 0.0,
      'reviewCount': data['review_count'] ?? 0,
      'reviews': data['reviews'] ?? [],
      'category': data['category'],
      'viewCount': data['view_count'] ?? 0,
      'favoriteCount': data['favorite_count'] ?? 0,
      'likeCount': data['like_count'] ?? 0,
      'tags': data['tags'] ?? [],
    };
  }

  // Helper to convert camelCase to snake_case for database
  Map<String, dynamic> _convertToSnakeCase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'description': data['description'],
      'ingredients': data['ingredients'],
      'instructions': data['instructions'],
      'image_url': data['image_url'],
      'image_urls': data['image_urls'] ?? [],
      'video_urls': data['video_urls'] ?? [],
      'author_id': data['author_id'],
      'author_name': data['author_name'],
      'category': data['category'],
      'tags': data['tags'],
    };
  }
}

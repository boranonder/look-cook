import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get reviews for a recipe
  Stream<List<Review>> getRecipeReviews(String recipeId) {
    return _supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Review.fromMap(_convertSnakeCase(item))).toList());
  }

  // Add a review
  Future<void> addReview(Review review) async {
    try {
      await _supabase.from('reviews').insert({
        'recipe_id': review.recipeId,
        'user_id': review.userId,
        'user_name': review.userName,
        'rating': review.rating,
        'comment': review.comment,
        'created_at': review.createdAt.toIso8601String(),
      });

      // Update recipe rating and review count
      await _updateRecipeRating(review.recipeId);
    } catch (e) {
      debugPrint('Add review error: $e');
    }
  }

  // Update a review
  Future<void> updateReview(Review review) async {
    try {
      await _supabase
          .from('reviews')
          .update({
            'rating': review.rating,
            'comment': review.comment,
          })
          .eq('id', review.id);

      // Update recipe rating
      await _updateRecipeRating(review.recipeId);
    } catch (e) {
      debugPrint('Update review error: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId, String recipeId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);

      // Update recipe rating
      await _updateRecipeRating(recipeId);
    } catch (e) {
      debugPrint('Delete review error: $e');
    }
  }

  // Update recipe rating and review count
  Future<void> _updateRecipeRating(String recipeId) async {
    try {
      // Get all reviews for this recipe
      final reviewsResponse = await _supabase
          .from('reviews')
          .select()
          .eq('recipe_id', recipeId);

      final reviews = reviewsResponse as List;

      if (reviews.isEmpty) {
        await _supabase.from('recipes').update({
          'average_rating': 0.0,
          'review_count': 0,
        }).eq('id', recipeId);
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var review in reviews) {
        totalRating += (review['rating'] as num).toDouble();
      }

      final averageRating = totalRating / reviews.length;
      final reviewCount = reviews.length;

      // Update recipe document
      await _supabase.from('recipes').update({
        'average_rating': averageRating,
        'review_count': reviewCount,
      }).eq('id', recipeId);
    } catch (e) {
      debugPrint('Update recipe rating error: $e');
    }
  }

  // Get user's review for a recipe
  Future<Review?> getUserReview(String recipeId, String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('recipe_id', recipeId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return Review.fromMap(_convertSnakeCase(response));
      }

      return null;
    } catch (e) {
      debugPrint('Get user review error: $e');
      return null;
    }
  }

  // Check if user has reviewed a recipe
  Future<bool> hasUserReviewed(String recipeId, String userId) async {
    final review = await getUserReview(recipeId, userId);
    return review != null;
  }

  // Get reviews by user
  Stream<List<Review>> getUserReviews(String userId) {
    return _supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Review.fromMap(_convertSnakeCase(item))).toList());
  }

  // Helper to convert snake_case to camelCase
  Map<String, dynamic> _convertSnakeCase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'recipeId': data['recipe_id'],
      'userId': data['user_id'],
      'userName': data['user_name'],
      'rating': data['rating'],
      'comment': data['comment'],
      'createdAt': data['created_at'] != null
          ? DateTime.parse(data['created_at']).millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
    };
  }
}

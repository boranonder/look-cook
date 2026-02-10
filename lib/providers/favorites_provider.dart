import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Set<String> _favoriteRecipeIds = {};
  String? _currentUserId;
  RealtimeChannel? _favoritesChannel;

  Set<String> get favoriteRecipeIds => _favoriteRecipeIds;

  bool isFavorite(String recipeId) {
    return _favoriteRecipeIds.contains(recipeId);
  }

  // Load user favorites from database
  Future<void> loadUserFavorites(String userId, {bool forceReload = false}) async {
    if (_currentUserId == userId && !forceReload) return; // Already loaded

    _currentUserId = userId;
    try {
      final favoriteIds = await _favoritesService.getUserFavoriteIds(userId);
      _favoriteRecipeIds.clear();
      _favoriteRecipeIds.addAll(favoriteIds);
      notifyListeners();

      // Subscribe to realtime updates
      subscribeToRealtimeUpdates(userId);
    } catch (e) {
      debugPrint('Load user favorites error: $e');
    }
  }

  // Subscribe to realtime updates for favorites
  void subscribeToRealtimeUpdates(String userId) {
    // Unsubscribe from previous channel if exists
    _favoritesChannel?.unsubscribe();

    // Subscribe to user_favorites table changes for this user
    _favoritesChannel = _supabase
        .channel('user_favorites_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_favorites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final recipeId = payload.newRecord['recipe_id'] as String?;
            if (recipeId != null && !_favoriteRecipeIds.contains(recipeId)) {
              _favoriteRecipeIds.add(recipeId);
              debugPrint('Realtime: Added favorite $recipeId');
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'user_favorites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final recipeId = payload.oldRecord['recipe_id'] as String?;
            if (recipeId != null && _favoriteRecipeIds.contains(recipeId)) {
              _favoriteRecipeIds.remove(recipeId);
              debugPrint('Realtime: Removed favorite $recipeId');
              notifyListeners();
            }
          },
        )
        .subscribe();

    debugPrint('Subscribed to realtime favorite updates for user: $userId');
  }

  // Unsubscribe from realtime updates
  void unsubscribeFromRealtimeUpdates() {
    _favoritesChannel?.unsubscribe();
    _favoritesChannel = null;
  }

  Future<void> toggleFavorite(String recipeId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_favoriteRecipeIds.contains(recipeId)) {
      _favoriteRecipeIds.remove(recipeId);
      notifyListeners();
      await _favoritesService.removeFromFavorites(user.id, recipeId);
    } else {
      _favoriteRecipeIds.add(recipeId);
      notifyListeners();
      await _favoritesService.addToFavorites(user.id, recipeId);
    }
  }

  void addFavorite(String recipeId) {
    _favoriteRecipeIds.add(recipeId);
    notifyListeners();
  }

  void removeFavorite(String recipeId) {
    _favoriteRecipeIds.remove(recipeId);
    notifyListeners();
  }

  void clearFavorites() {
    unsubscribeFromRealtimeUpdates();
    _favoriteRecipeIds.clear();
    _currentUserId = null;
    notifyListeners();
  }
}

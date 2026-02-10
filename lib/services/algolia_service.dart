import 'package:algolia/algolia.dart';
import '../config/algolia_config.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import '../models/recipe_category.dart';

class AlgoliaService {
  static final AlgoliaService _instance = AlgoliaService._internal();
  factory AlgoliaService() => _instance;
  AlgoliaService._internal();

  late Algolia _algolia;
  bool _isInitialized = false;

  // Initialize Algolia for searching (uses Search API Key)
  void initialize() {
    if (_isInitialized) return;
    
    _algolia = Algolia.init(
      applicationId: AlgoliaConfig.applicationId,
      apiKey: AlgoliaConfig.searchApiKey,
    );
    _isInitialized = true;
  }

  // Initialize Algolia for writing (uses Admin API Key)
  Algolia _getAdminAlgolia() {
    return Algolia.init(
      applicationId: AlgoliaConfig.applicationId,
      apiKey: AlgoliaConfig.adminApiKey, // Write permissions
    );
  }

  // Check if Algolia is configured
  bool isConfigured() {
    return AlgoliaConfig.applicationId.isNotEmpty &&
           AlgoliaConfig.searchApiKey.isNotEmpty;
  }

  // SEARCH OPERATIONS

  /// Search recipes with query
  Future<List<Recipe>> searchRecipes(
    String query, {
    RecipeCategory? category,
    int hitsPerPage = 20,
  }) async {
    if (!isConfigured()) {
      throw Exception('Algolia is not configured. Please update algolia_config.dart');
    }

    try {
      var algoliaQuery = _algolia.instance
          .index(AlgoliaConfig.recipesIndex)
          .query(query)
          .setHitsPerPage(hitsPerPage);

      if (category != null) {
        algoliaQuery = algoliaQuery.filters('category:${category.name}');
      }

      final snapshot = await algoliaQuery.getObjects();
      
      return snapshot.hits.map((hit) {
        final data = hit.data;
        data['id'] = hit.objectID;
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      print('Algolia search error: $e');
      return [];
    }
  }

  /// Get trending recipes (last 7 days activity)
  Future<List<Recipe>> getTrendingRecipes({int limit = 10}) async {
    if (!isConfigured()) {
      throw Exception('Algolia is not configured');
    }

    try {
      final snapshot = await _algolia.instance
          .index(AlgoliaConfig.recipesTrendingIndex)
          .setHitsPerPage(limit)
          .getObjects();
      
      return snapshot.hits.map((hit) {
        final data = hit.data;
        data['id'] = hit.objectID;
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      print('Algolia trending error: $e');
      return [];
    }
  }

  /// Get top rated recipes with minimum review count
  Future<List<Recipe>> getTopRatedRecipes({
    int limit = 10,
    int minReviews = 5,
  }) async {
    if (!isConfigured()) {
      throw Exception('Algolia is not configured');
    }

    try {
      final snapshot = await _algolia.instance
          .index(AlgoliaConfig.recipesTopRatedIndex)
          .filters('reviewCount>=$minReviews')
          .setHitsPerPage(limit)
          .getObjects();
      
      return snapshot.hits.map((hit) {
        final data = hit.data;
        data['id'] = hit.objectID;
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      print('Algolia top rated error: $e');
      return [];
    }
  }

  /// Get recipes by category with sorting
  Future<List<Recipe>> getRecipesByCategory(
    RecipeCategory category, {
    String sortBy = 'rating', // 'rating', 'newest', 'popular'
    int limit = 20,
  }) async {
    if (!isConfigured()) {
      throw Exception('Algolia is not configured');
    }

    try {
      var query = _algolia.instance
          .index(AlgoliaConfig.recipesIndex)
          .filters('category:${category.name}')
          .setHitsPerPage(limit);

      // Note: Custom ranking should be configured in Algolia dashboard
      // Use replica indices for different sorting strategies

      final snapshot = await query.getObjects();
      
      return snapshot.hits.map((hit) {
        final data = hit.data;
        data['id'] = hit.objectID;
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      print('Algolia category recipes error: $e');
      return [];
    }
  }

  /// Get most favorited recipes
  Future<List<Recipe>> getMostFavoritedRecipes({int limit = 10}) async {
    if (!isConfigured()) {
      throw Exception('Algolia is not configured');
    }

    try {
      // Note: Custom ranking by favoriteCount should be configured in Algolia dashboard
      final snapshot = await _algolia.instance
          .index(AlgoliaConfig.recipesIndex)
          .setHitsPerPage(limit)
          .getObjects();
      
      return snapshot.hits.map((hit) {
        final data = hit.data;
        data['id'] = hit.objectID;
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      print('Algolia most favorited error: $e');
      return [];
    }
  }

  /// Search users
  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    if (!isConfigured()) {
      throw Exception('Algolia is not configured');
    }

    try {
      final snapshot = await _algolia.instance
          .index(AlgoliaConfig.usersIndex)
          .query(query)
          .setHitsPerPage(limit)
          .getObjects();
      
      return snapshot.hits.map((hit) {
        final data = hit.data;
        data['id'] = hit.objectID;
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      print('Algolia user search error: $e');
      return [];
    }
  }

  // DATA SYNC OPERATIONS (for mock data initialization)

  /// Save recipe to Algolia
  Future<void> saveRecipe(Recipe recipe) async {
    if (!isConfigured()) return;

    try {
      final adminAlgolia = _getAdminAlgolia();
      final data = recipe.toMap();
      
      // Save to main recipes index
      await adminAlgolia.instance
          .index(AlgoliaConfig.recipesIndex)
          .object(recipe.id)
          .setData(data);

      // If it's trending (recent + popular), also save to trending index
      final daysSinceCreated = DateTime.now().difference(recipe.createdAt).inDays;
      if (daysSinceCreated <= 7 && recipe.reviewCount > 0) {
        await adminAlgolia.instance
            .index(AlgoliaConfig.recipesTrendingIndex)
            .object(recipe.id)
            .setData(data);
      }

      // If it's highly rated, save to top rated index
      if (recipe.averageRating >= 4.0 && recipe.reviewCount >= 5) {
        await adminAlgolia.instance
            .index(AlgoliaConfig.recipesTopRatedIndex)
            .object(recipe.id)
            .setData(data);
      }
    } catch (e) {
      print('Algolia save recipe error: $e');
    }
  }

  /// Save user to Algolia
  Future<void> saveUser(User user) async {
    if (!isConfigured()) return;

    try {
      final adminAlgolia = _getAdminAlgolia();
      await adminAlgolia.instance
          .index(AlgoliaConfig.usersIndex)
          .object(user.id)
          .setData(user.toMap());
    } catch (e) {
      print('Algolia save user error: $e');
    }
  }

  /// Batch save recipes
  Future<void> batchSaveRecipes(List<Recipe> recipes) async {
    if (!isConfigured()) return;

    for (var recipe in recipes) {
      await saveRecipe(recipe);
    }
  }

  /// Batch save users
  Future<void> batchSaveUsers(List<User> users) async {
    if (!isConfigured()) return;

    for (var user in users) {
      await saveUser(user);
    }
  }

  /// Delete recipe from Algolia
  Future<void> deleteRecipe(String recipeId) async {
    if (!isConfigured()) return;

    try {
      final adminAlgolia = _getAdminAlgolia();
      await adminAlgolia.instance
          .index(AlgoliaConfig.recipesIndex)
          .object(recipeId)
          .deleteObject();
    } catch (e) {
      print('Algolia delete recipe error: $e');
    }
  }
}


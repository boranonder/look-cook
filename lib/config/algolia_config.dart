import 'package:flutter_dotenv/flutter_dotenv.dart';

// Algolia Configuration - reads from .env file
class AlgoliaConfig {
  // Get these from environment variables
  static String get applicationId => dotenv.env['ALGOLIA_APP_ID'] ?? '';
  static String get searchApiKey => dotenv.env['ALGOLIA_SEARCH_API_KEY'] ?? '';
  static String get adminApiKey => dotenv.env['ALGOLIA_AparppDMIN_API_KEY'] ?? '';

  // Index names
  static const String recipesIndex = 'recipes';
  static const String recipesTrendingIndex = 'recipes_trending';
  static const String recipesTopRatedIndex = 'recipes_top_rated';
  static const String usersIndex = 'users';

  // Algolia settings
  static const int defaultHitsPerPage = 20;
  static const int maxHitsPerPage = 100;
}

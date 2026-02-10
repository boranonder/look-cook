import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../recipe/recipe_detail_screen.dart';

class PopularRecipesScreen extends StatefulWidget {
  const PopularRecipesScreen({super.key});

  @override
  State<PopularRecipesScreen> createState() => _PopularRecipesScreenState();
}

class _PopularRecipesScreenState extends State<PopularRecipesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPopularRecipes();
  }

  Future<void> _loadPopularRecipes() async {
    setState(() => _isLoading = true);

    try {
      // Get most favorited recipes
      final response = await _supabase
          .from('recipes')
          .select()
          .order('favorite_count', ascending: false)
          .limit(50);

      final recipesList = response is List ? response : [];
      setState(() {
        _recipes = recipesList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading popular recipes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Populer Tarifler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Henuz populer tarif yok',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPopularRecipes,
                  color: AppTheme.primaryRed,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return _RecipeListItem(
                        recipe: recipe,
                        rank: index + 1,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _RecipeListItem extends StatelessWidget {
  final Recipe recipe;
  final int rank;
  final VoidCallback onTap;

  const _RecipeListItem({
    required this.recipe,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    Color rankTextColor = Colors.white;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankTextColor = Colors.black87;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankTextColor = Colors.black87;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = AppTheme.primaryRed;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rankColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rankTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Recipe image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildPlaceholder(),
                          errorWidget: (context, url, error) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Recipe info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.authorName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: recipe.averageRating,
                          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.averageRating.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.favoriteCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightRed.withOpacity(0.3),
            AppTheme.primaryRed.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(recipe.category.emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

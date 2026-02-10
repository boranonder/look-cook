import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/recipe_category.dart';
import '../../models/user.dart' as app_user;
import '../recipe/recipe_detail_screen.dart';
import '../profile/other_user_profile_screen.dart';
import '../category/category_recipes_screen.dart';
import '../search/search_screen.dart';
import '../rankings/rankings_screen.dart';
import 'popular_recipes_screen.dart';
import 'popular_chefs_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;

  List<Recipe> _popularRecipes = [];
  List<app_user.User> _topChefs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Load all data in parallel
      await Future.wait([
        _loadPopular(),
        _loadTopChefs(),
      ]);
    } catch (e) {
      debugPrint('Error loading discover data: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPopular() async {
    try {
      // Get most favorited recipes (by favorite_count)
      final response = await _supabase
          .from('recipes')
          .select()
          .order('favorite_count', ascending: false)
          .limit(10);

      final recipesList = response is List ? response : [];

      if (recipesList.isEmpty) {
        _popularRecipes = [];
        return;
      }

      _popularRecipes = recipesList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading popular: $e');
    }
  }

  Future<void> _loadTopChefs() async {
    try {
      // Get users with most followers
      final response = await _supabase
          .from('users')
          .select()
          .order('follower_count', ascending: false)
          .limit(6);

      final usersList = response is List ? response : [];
      _topChefs = usersList.map((u) => app_user.User.fromMap(u as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading top chefs: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.primaryRed),
                      const SizedBox(height: 16),
                      Text(l10n.error, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                        child: Text(l10n.retry, style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.primaryRed,
              child: CustomScrollView(
                slivers: [
                  // App Bar with Search
                  SliverAppBar(
                    expandedHeight: 130,
                    floating: true,
                    pinned: true,
                    backgroundColor: AppTheme.primaryRed,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryRed, AppTheme.darkRed],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      l10n.discover,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildSearchBar(context, l10n),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Categories
                        _buildSectionTitle(l10n.categories, l10n),
                        const SizedBox(height: 12),
                        _buildCategoriesRow(),

                        const SizedBox(height: 24),

                        // Rankings Section
                        _buildRankingsCard(l10n),

                        const SizedBox(height: 24),

                        // Popular Recipes (Most Favorited in Last Week)
                        if (_popularRecipes.isNotEmpty) ...[
                          _buildSectionTitle(l10n.popularRecipes, l10n, onSeeAll: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PopularRecipesScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          _buildHorizontalRecipeList(_popularRecipes, l10n),
                          const SizedBox(height: 24),
                        ],

                        // Popular Chefs (Most Favorited in Last Week)
                        if (_topChefs.isNotEmpty) ...[
                          _buildSectionTitle(l10n.popularChefs, l10n, onSeeAll: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PopularChefsScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          _buildTopChefsRow(),
                          const SizedBox(height: 24),
                        ],

                        const SizedBox(height: 80), // Bottom padding for navigation bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.searchPlaceholder,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, color: AppTheme.primaryRed, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    l10n.filter,
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppLocalizations l10n, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                l10n.seeAll,
                style: const TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: RecipeCategory.values.length,
        itemBuilder: (context, index) {
          final category = RecipeCategory.values[index];
          final colors = CategoryColors.categoryGradients[category] ?? [0xFFE53E3E, 0xFFC53030];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryRecipesScreen(category: category),
                ),
              );
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Color(colors[0]), Color(colors[1])],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(colors[0]).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      category.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankingsCard(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RankingsScreen()),
          );
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background medals
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.emoji_events,
                  size: 100,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  Icons.military_tech,
                  size: 80,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '🏆',
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.rankings,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _buildMedalChip('1.', const Color(0xFFFFD700)),
                              _buildMedalChip('2.', const Color(0xFFC0C0C0)),
                              _buildMedalChip('3.', const Color(0xFFCD7F32)),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'Top 10',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildMedalChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color == const Color(0xFFCD7F32) ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Recipe recipe) {
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
        child: Text(
          recipe.category.emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  Widget _buildHorizontalRecipeList(List<Recipe> recipes, AppLocalizations l10n) {
    if (recipes.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(child: Text(l10n.noRecipesYet)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    recipe.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: recipe.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildImagePlaceholder(recipe),
                            errorWidget: (context, url, error) => _buildImagePlaceholder(recipe),
                          )
                        : _buildImagePlaceholder(recipe),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.category.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        recipe.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' (${recipe.reviewCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopChefsRow() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _topChefs.length,
        itemBuilder: (context, index) {
          final chef = _topChefs[index];
          return _buildChefCard(chef);
        },
      ),
    );
  }

  Widget _buildChefCard(app_user.User chef) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtherUserProfileScreen(userId: chef.id),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
              backgroundImage: chef.profileImageUrl != null
                  ? NetworkImage(chef.profileImageUrl!)
                  : null,
              child: chef.profileImageUrl == null
                  ? Text(
                      chef.name.isNotEmpty ? chef.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                chef.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: AppTheme.primaryRed, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${chef.followerCount}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

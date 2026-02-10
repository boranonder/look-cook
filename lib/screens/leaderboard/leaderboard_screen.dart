import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/user.dart' as app_user;
import '../recipe/recipe_detail_screen.dart';
import '../profile/other_user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Recipe> _topRatedRecipes = [];
  List<Recipe> _mostReviewedRecipes = [];
  List<Recipe> _trendingRecipes = [];
  List<_ChefData> _topChefs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadTopRated(),
        _loadMostReviewed(),
        _loadTrending(),
        _loadTopChefs(),
      ]);
    } catch (e) {
      debugPrint('Error loading leaderboards: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTopRated() async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .gte('review_count', 3)
          .order('average_rating', ascending: false)
          .limit(20);

      _topRatedRecipes = (response as List).map((r) => Recipe.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error loading top rated: $e');
    }
  }

  Future<void> _loadMostReviewed() async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .order('review_count', ascending: false)
          .limit(20);

      _mostReviewedRecipes = (response as List).map((r) => Recipe.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error loading most reviewed: $e');
    }
  }

  Future<void> _loadTrending() async {
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      final response = await _supabase
          .from('recipes')
          .select()
          .gte('created_at', oneWeekAgo.toIso8601String())
          .order('favorite_count', ascending: false)
          .limit(20);

      _trendingRecipes = (response as List).map((r) => Recipe.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error loading trending: $e');
    }
  }

  Future<void> _loadTopChefs() async {
    try {
      // Get users with follower counts
      final usersResponse = await _supabase
          .from('users')
          .select()
          .order('follower_count', ascending: false)
          .limit(20);

      final users = (usersResponse as List).map((u) => app_user.User.fromMap(u)).toList();

      // Get recipe counts and average ratings for each user
      List<_ChefData> chefDataList = [];
      for (var user in users) {
        final recipesResponse = await _supabase
            .from('recipes')
            .select('average_rating')
            .eq('author_id', user.id);

        final recipes = recipesResponse as List;
        final recipeCount = recipes.length;
        final averageRating = recipeCount > 0
            ? recipes.fold<double>(0, (sum, r) => sum + (r['average_rating'] as num).toDouble()) / recipeCount
            : 0.0;

        chefDataList.add(_ChefData(
          user: user,
          recipeCount: recipeCount,
          averageRating: averageRating,
        ));
      }

      // Sort by average rating and recipe count
      chefDataList.sort((a, b) {
        final ratingCompare = b.averageRating.compareTo(a.averageRating);
        if (ratingCompare != 0) return ratingCompare;
        return b.recipeCount.compareTo(a.recipeCount);
      });

      _topChefs = chefDataList.take(20).toList();
    } catch (e) {
      debugPrint('Error loading top chefs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboard),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.topRated),
            Tab(text: l10n.mostReviewed),
            Tab(text: l10n.trending),
            const Tab(text: 'En İyi Aşçılar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : RefreshIndicator(
              onRefresh: _loadLeaderboards,
              color: AppTheme.primaryRed,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LeaderboardList(
                    recipes: _topRatedRecipes,
                    showRating: true,
                  ),
                  _LeaderboardList(
                    recipes: _mostReviewedRecipes,
                    showReviewCount: true,
                  ),
                  _LeaderboardList(
                    recipes: _trendingRecipes,
                    showDate: true,
                  ),
                  _ChefLeaderboard(chefs: _topChefs),
                ],
              ),
            ),
    );
  }
}

class _ChefData {
  final app_user.User user;
  final int recipeCount;
  final double averageRating;

  _ChefData({
    required this.user,
    required this.recipeCount,
    required this.averageRating,
  });
}

class _LeaderboardList extends StatelessWidget {
  final List<Recipe> recipes;
  final bool showRating;
  final bool showReviewCount;
  final bool showDate;

  const _LeaderboardList({
    required this.recipes,
    this.showRating = false,
    this.showReviewCount = false,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz veri yok',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final rank = index + 1;

        return _LeaderboardItem(
          recipe: recipe,
          rank: rank,
          showRating: showRating,
          showReviewCount: showReviewCount,
          showDate: showDate,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(recipe: recipe),
              ),
            );
          },
        );
      },
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final Recipe recipe;
  final int rank;
  final bool showRating;
  final bool showReviewCount;
  final bool showDate;
  final VoidCallback onTap;

  const _LeaderboardItem({
    required this.recipe,
    required this.rank,
    required this.onTap,
    this.showRating = false,
    this.showReviewCount = false,
    this.showDate = false,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.textLight;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else {
      return '$difference gün önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(rank).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRankColor(rank),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: rank <= 3
                      ? Icon(
                          Icons.emoji_events,
                          color: _getRankColor(rank),
                          size: 20,
                        )
                      : Text(
                          '$rank',
                          style: TextStyle(
                            color: _getRankColor(rank),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              const SizedBox(width: 16),

              // Recipe Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'by ${recipe.authorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (showRating)
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: recipe.averageRating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.averageRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                    if (showReviewCount)
                      Row(
                        children: [
                          const Icon(
                            Icons.rate_review,
                            size: 16,
                            color: AppTheme.primaryRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.reviewCount} yorum',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                    if (showDate)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.primaryRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(recipe.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textLight,
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

class _ChefLeaderboard extends StatelessWidget {
  final List<_ChefData> chefs;

  const _ChefLeaderboard({required this.chefs});

  @override
  Widget build(BuildContext context) {
    if (chefs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz veri yok',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chefs.length,
      itemBuilder: (context, index) {
        final chefData = chefs[index];
        final rank = index + 1;

        return _ChefLeaderboardItem(
          chefData: chefData,
          rank: rank,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OtherUserProfileScreen(userId: chefData.user.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChefLeaderboardItem extends StatelessWidget {
  final _ChefData chefData;
  final int rank;
  final VoidCallback onTap;

  const _ChefLeaderboardItem({
    required this.chefData,
    required this.rank,
    required this.onTap,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chef = chefData.user;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(rank).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRankColor(rank),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: rank <= 3
                      ? Icon(
                          Icons.emoji_events,
                          color: _getRankColor(rank),
                          size: 20,
                        )
                      : Text(
                          '$rank',
                          style: TextStyle(
                            color: _getRankColor(rank),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Chef Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryRed,
                backgroundImage: chef.profileImageUrl != null
                    ? NetworkImage(chef.profileImageUrl!)
                    : null,
                child: chef.profileImageUrl == null
                    ? Text(
                        chef.name.isNotEmpty ? chef.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // Chef Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chef.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${chef.followerCount} takipçi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: chefData.averageRating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${chefData.averageRating.toStringAsFixed(1)} • ${chefData.recipeCount} tarif',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

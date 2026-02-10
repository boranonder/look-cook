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

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, List<Recipe>> _categoryRankings = {};
  List<app_user.User> _chefRankings = [];
  List<Recipe> _allRecipesRankings = [];

  // Tab categories: All Recipes + each RecipeCategory + Chefs
  List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  void _initTabs() {
    _tabs = [
      'all', // All Recipes
      ...RecipeCategory.values.map((c) => c.name),
      'chefs', // Chefs
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadDataForTab(_tabController.index);
      }
    });
    _loadDataForTab(0);
  }

  Future<void> _loadDataForTab(int index) async {
    final tabKey = _tabs[index];

    // Check if already loaded
    if (tabKey == 'all' && _allRecipesRankings.isNotEmpty) return;
    if (tabKey == 'chefs' && _chefRankings.isNotEmpty) return;
    if (_categoryRankings.containsKey(tabKey) && _categoryRankings[tabKey]!.isNotEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (tabKey == 'all') {
        await _loadAllRecipesRankings();
      } else if (tabKey == 'chefs') {
        await _loadChefRankings();
      } else {
        await _loadCategoryRankings(tabKey);
      }
    } catch (e) {
      debugPrint('Error loading rankings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAllRecipesRankings() async {
    // Get top 10 recipes with 50+ reviews first, then fill with 25+ reviews
    final qualityResponse = await _supabase
        .from('recipes')
        .select()
        .gte('review_count', 50)
        .order('average_rating', ascending: false)
        .order('review_count', ascending: false)
        .limit(10);

    final qualityList = qualityResponse is List ? qualityResponse : [];

    if (qualityList.length >= 10) {
      _allRecipesRankings = qualityList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();
    } else {
      final remaining = 10 - qualityList.length;
      final additionalResponse = await _supabase
          .from('recipes')
          .select()
          .gte('review_count', 10)
          .lt('review_count', 50)
          .order('average_rating', ascending: false)
          .limit(remaining);

      final additionalList = additionalResponse is List ? additionalResponse : [];
      _allRecipesRankings = [
        ...qualityList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)),
        ...additionalList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)),
      ];

      // If still not enough, fill with any high-rated recipes
      if (_allRecipesRankings.length < 10) {
        final fillRemaining = 10 - _allRecipesRankings.length;
        final existingIds = _allRecipesRankings.map((r) => r.id).toList();
        final fillResponse = await _supabase
            .from('recipes')
            .select()
            .order('average_rating', ascending: false)
            .limit(fillRemaining + existingIds.length);

        final fillList = fillResponse is List ? fillResponse : [];
        for (final item in fillList) {
          final recipe = Recipe.fromMap(item as Map<String, dynamic>);
          if (!existingIds.contains(recipe.id) && _allRecipesRankings.length < 10) {
            _allRecipesRankings.add(recipe);
          }
        }
      }
    }
  }

  Future<void> _loadCategoryRankings(String categoryName) async {
    // Get top 10 recipes in category with quality priority
    final qualityResponse = await _supabase
        .from('recipes')
        .select()
        .eq('category', categoryName)
        .gte('review_count', 25)
        .order('average_rating', ascending: false)
        .order('review_count', ascending: false)
        .limit(10);

    final qualityList = qualityResponse is List ? qualityResponse : [];

    if (qualityList.length >= 10) {
      _categoryRankings[categoryName] = qualityList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();
    } else {
      // Fill with any recipes in this category
      final remaining = 10 - qualityList.length;
      final existingIds = qualityList.map((r) => (r as Map<String, dynamic>)['id'] as String).toList();

      final additionalResponse = await _supabase
          .from('recipes')
          .select()
          .eq('category', categoryName)
          .lt('review_count', 25)
          .order('average_rating', ascending: false)
          .limit(remaining + existingIds.length);

      final additionalList = additionalResponse is List ? additionalResponse : [];
      final recipes = qualityList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();

      for (final item in additionalList) {
        final recipe = Recipe.fromMap(item as Map<String, dynamic>);
        if (!existingIds.contains(recipe.id) && recipes.length < 10) {
          recipes.add(recipe);
        }
      }

      _categoryRankings[categoryName] = recipes;
    }
  }

  Future<void> _loadChefRankings() async {
    // Get top 10 chefs by follower count, with recipes
    final response = await _supabase
        .from('users')
        .select()
        .gt('recipe_count', 0)
        .order('follower_count', ascending: false)
        .limit(10);

    final responseList = response is List ? response : [];
    _chefRankings = responseList.map((u) => app_user.User.fromMap(u as Map<String, dynamic>)).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTabLabel(String tabKey) {
    if (tabKey == 'all') {
      return AppLocalizations.of(context)?.allRecipes ?? 'Tum Tarifler';
    }
    if (tabKey == 'chefs') {
      return AppLocalizations.of(context)?.chefs ?? 'Ascilar';
    }
    try {
      final category = RecipeCategory.values.firstWhere((c) => c.name == tabKey);
      return '${category.emoji} ${category.displayName}';
    } catch (e) {
      return tabKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: Text(l10n.rankings),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.primaryRed,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: _tabs.map((tab) => Tab(text: _getTabLabel(tab))).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
      ),
    );
  }

  Widget _buildTabContent(String tabKey) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (tabKey == 'chefs') {
      return _buildChefRankings();
    }

    final recipes = tabKey == 'all' ? _allRecipesRankings : (_categoryRankings[tabKey] ?? []);

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henuz siralama yok',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return _buildRecipeRankings(recipes);
  }

  Widget _buildRecipeRankings(List<Recipe> recipes) {
    // Ensure we have at least top 3 for the podium
    final top3 = recipes.take(3).toList();
    final remaining = recipes.length > 3 ? recipes.sublist(3) : <Recipe>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Podium for top 3
          _buildPodium(top3),
          const SizedBox(height: 24),

          // Remaining rankings (4-10)
          if (remaining.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            ...remaining.asMap().entries.map((entry) {
              final index = entry.key;
              final recipe = entry.value;
              return _buildRankingListItem(recipe, index + 4);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPodium(List<Recipe> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place (Silver)
        if (top3.length > 1)
          _buildPodiumItem(top3[1], 2, const Color(0xFFC0C0C0), 100)
        else
          const SizedBox(width: 100),

        const SizedBox(width: 8),

        // 1st place (Gold)
        if (top3.isNotEmpty)
          _buildPodiumItem(top3[0], 1, const Color(0xFFFFD700), 130),

        const SizedBox(width: 8),

        // 3rd place (Bronze)
        if (top3.length > 2)
          _buildPodiumItem(top3[2], 3, const Color(0xFFCD7F32), 80)
        else
          const SizedBox(width: 100),
      ],
    );
  }

  Widget _buildPodiumItem(Recipe recipe, int rank, Color medalColor, double height) {
    final isFirst = rank == 1;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Column(
        children: [
          // Medal
          Container(
            width: isFirst ? 56 : 48,
            height: isFirst ? 56 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor,
              boxShadow: [
                BoxShadow(
                  color: medalColor.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: isFirst ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: rank <= 2 ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Recipe card
          Container(
            width: isFirst ? 110 : 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: medalColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: medalColor, width: 2),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: isFirst ? 80 : 70,
                    width: double.infinity,
                    child: recipe.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: recipe.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildImagePlaceholder(recipe),
                            errorWidget: (context, url, error) => _buildImagePlaceholder(recipe),
                          )
                        : _buildImagePlaceholder(recipe),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        recipe.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isFirst ? 12 : 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            recipe.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

          // Podium base
          Container(
            width: isFirst ? 110 : 100,
            height: height,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  medalColor,
                  medalColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                _getRankLabel(rank),
                style: TextStyle(
                  color: rank <= 2 ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRankLabel(int rank) {
    switch (rank) {
      case 1:
        return 'ALTIN';
      case 2:
        return 'GUMUS';
      case 3:
        return 'BRONZ';
      default:
        return '$rank.';
    }
  }

  Widget _buildRankingListItem(Recipe recipe, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildImagePlaceholder(recipe),
                          errorWidget: (context, url, error) => _buildImagePlaceholder(recipe),
                        )
                      : _buildImagePlaceholder(recipe),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
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
                    const SizedBox(height: 2),
                    Text(
                      recipe.authorName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        recipe.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '(${recipe.reviewCount})',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChefRankings() {
    if (_chefRankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henuz siralama yok',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final top3 = _chefRankings.take(3).toList();
    final remaining = _chefRankings.length > 3 ? _chefRankings.sublist(3) : <app_user.User>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Podium for top 3 chefs
          _buildChefPodium(top3),
          const SizedBox(height: 24),

          // Remaining rankings (4-10)
          if (remaining.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            ...remaining.asMap().entries.map((entry) {
              final index = entry.key;
              final chef = entry.value;
              return _buildChefListItem(chef, index + 4);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChefPodium(List<app_user.User> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place (Silver)
        if (top3.length > 1)
          _buildChefPodiumItem(top3[1], 2, const Color(0xFFC0C0C0), 100)
        else
          const SizedBox(width: 100),

        const SizedBox(width: 8),

        // 1st place (Gold)
        if (top3.isNotEmpty)
          _buildChefPodiumItem(top3[0], 1, const Color(0xFFFFD700), 130),

        const SizedBox(width: 8),

        // 3rd place (Bronze)
        if (top3.length > 2)
          _buildChefPodiumItem(top3[2], 3, const Color(0xFFCD7F32), 80)
        else
          const SizedBox(width: 100),
      ],
    );
  }

  Widget _buildChefPodiumItem(app_user.User chef, int rank, Color medalColor, double height) {
    final isFirst = rank == 1;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtherUserProfileScreen(userId: chef.id),
          ),
        );
      },
      child: Column(
        children: [
          // Medal
          Container(
            width: isFirst ? 56 : 48,
            height: isFirst ? 56 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor,
              boxShadow: [
                BoxShadow(
                  color: medalColor.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: isFirst ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: rank <= 2 ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Chef card
          Container(
            width: isFirst ? 110 : 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: medalColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: medalColor, width: 2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isFirst ? 32 : 28,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
                  backgroundImage: chef.profileImageUrl != null
                      ? NetworkImage(chef.profileImageUrl!)
                      : null,
                  child: chef.profileImageUrl == null
                      ? Text(
                          chef.name.isNotEmpty ? chef.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: isFirst ? 24 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  chef.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isFirst ? 12 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 12, color: AppTheme.primaryRed),
                    const SizedBox(width: 2),
                    Text(
                      '${chef.followerCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Podium base
          Container(
            width: isFirst ? 110 : 100,
            height: height,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  medalColor,
                  medalColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                _getRankLabel(rank),
                style: TextStyle(
                  color: rank <= 2 ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefListItem(app_user.User chef, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(userId: chef.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
                backgroundImage: chef.profileImageUrl != null
                    ? NetworkImage(chef.profileImageUrl!)
                    : null,
                child: chef.profileImageUrl == null
                    ? Text(
                        chef.name.isNotEmpty ? chef.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chef.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${chef.recipeCount} tarif',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Followers
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: AppTheme.primaryRed, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        '${chef.followerCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'takipci',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

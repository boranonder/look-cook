import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/recipe_service.dart';
import '../recipe/recipe_detail_screen.dart';
import '../search/search_screen.dart';
import '../main/main_navigation_screen.dart';
import '../profile/other_user_profile_screen.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  final RecipeService _recipeService = RecipeService();
  final ScrollController _scrollController = ScrollController();
  List<Recipe> _followingRecipes = [];
  bool _isLoading = true;
  Set<String> _lastFollowingIds = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingRecipes(Set<String> followingIds) async {
    if (followingIds.isEmpty) {
      setState(() {
        _followingRecipes = [];
        _isLoading = false;
      });
      return;
    }

    // Only reload if following list changed or forced
    if (_lastFollowingIds.toString() == followingIds.toString() && !_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    final recipes = await _recipeService.getRecipesByAuthors(
      followingIds.toList(),
      limit: 100,
    );

    if (mounted) {
      setState(() {
        _followingRecipes = recipes;
        _isLoading = false;
        _lastFollowingIds = followingIds;
      });
    }
  }

  Future<void> _refreshFollowingRecipes(Set<String> followingIds) async {
    _lastFollowingIds = {}; // Force reload
    await _loadFollowingRecipes(followingIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final currentUser = authProvider.currentUser;
    final followingIds = currentUser != null
        ? followProvider.getFollowing(currentUser.id)
        : <String>{};
    final hasFollowing = followingIds.isNotEmpty;

    // Load recipes when following list changes
    if (hasFollowing && _lastFollowingIds.toString() != followingIds.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFollowingRecipes(followingIds);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () => _refreshFollowingRecipes(followingIds),
        color: AppTheme.primaryRed,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              pinned: true,
              backgroundColor: AppTheme.primaryRed,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Look & Cook',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Content
            if (!hasFollowing)
              // Empty state when not following anyone
              SliverFillRemaining(
                child: _buildEmptyState(context, l10n),
              )
            else if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(64),
                    child: CircularProgressIndicator(color: AppTheme.primaryRed),
                  ),
                ),
              )
            else if (_followingRecipes.isEmpty)
              SliverToBoxAdapter(
                child: _buildNoRecipesFromFollowing(context, l10n),
              )
            else
              SliverToBoxAdapter(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _followingRecipes.length,
                  itemBuilder: (context, index) {
                    return _FeedRecipeCard(recipe: _followingRecipes[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.primaryRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noFollowingYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.discoverChefs,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to discover tab
                mainNavigationKey.currentState?.navigateToTab(1);
              },
              icon: const Icon(Icons.explore),
              label: Text(l10n.goToDiscover),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecipesFromFollowing(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noRecipesFromFollowing,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                mainNavigationKey.currentState?.navigateToTab(1);
              },
              icon: const Icon(Icons.explore),
              label: Text(l10n.discoverMore),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: const BorderSide(color: AppTheme.primaryRed),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Feed recipe card (Instagram-like)
class _FeedRecipeCard extends StatefulWidget {
  final Recipe recipe;

  const _FeedRecipeCard({required this.recipe});

  @override
  State<_FeedRecipeCard> createState() => _FeedRecipeCardState();
}

class _FeedRecipeCardState extends State<_FeedRecipeCard> {
  final RecipeService _recipeService = RecipeService();
  bool _isLiked = false;
  bool _showHeart = false;
  int _likeCount = 0;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.recipe.likeCount;
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final liked = await _recipeService.isLiked(widget.recipe.id, user.id);
      if (mounted) {
        setState(() {
          _isLiked = liked;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.loginToLike ?? 'Please login to like'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    await _recipeService.toggleLike(widget.recipe.id, user.id);
  }

  void _onDoubleTap() {
    if (!_isLiked) {
      _toggleLike();
    }
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _shareRecipe() {
    final recipeUrl = 'https://lookcook.app/recipe/${widget.recipe.id}';
    final shareText = '${widget.recipe.name} - ${widget.recipe.authorName} tarafindan\n\n'
        '${widget.recipe.description}\n\n'
        '$recipeUrl\n\n'
        'Look & Cook uygulamasinda bu tarifi dene!';

    Share.share(shareText, subject: widget.recipe.name);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(recipe.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OtherUserProfileScreen(
                    userId: recipe.authorId,
                    userName: recipe.authorName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryRed,
                    child: Text(
                      recipe.authorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${recipe.category.emoji} ${recipe.category.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recipe images with PageView
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipe: recipe),
                ),
              );
            },
            onDoubleTap: _onDoubleTap,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  // Images or placeholder
                  if (recipe.imageUrls.isNotEmpty || recipe.imageUrl != null)
                    PageView.builder(
                      itemCount: recipe.imageUrls.isNotEmpty
                          ? recipe.imageUrls.length
                          : (recipe.imageUrl != null ? 1 : 0),
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = recipe.imageUrls.isNotEmpty
                            ? recipe.imageUrls[index]
                            : recipe.imageUrl!;
                        return CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.lightRed.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryRed),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.lightRed.withOpacity(0.3),
                                  AppTheme.primaryRed.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(recipe.category.emoji, style: const TextStyle(fontSize: 64)),
                                  const SizedBox(height: 8),
                                  const Icon(Icons.restaurant, size: 32, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.lightRed.withOpacity(0.3),
                            AppTheme.primaryRed.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(recipe.category.emoji, style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 8),
                            const Icon(Icons.restaurant, size: 32, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  // Page indicator
                  if ((recipe.imageUrls.length > 1) || (recipe.imageUrls.isEmpty && recipe.imageUrl == null))
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          recipe.imageUrls.isNotEmpty ? recipe.imageUrls.length : 0,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Heart animation
                  if (_showHeart)
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 100,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black87,
                    size: 28,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 26),
                  onPressed: _shareRecipe,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite ? AppTheme.primaryRed : Colors.black87,
                    size: 28,
                  ),
                  onPressed: () {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) {
                      final l10n = AppLocalizations.of(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.loginToSave ?? 'Kaydetmek için giriş yapmalısınız'),
                          backgroundColor: AppTheme.primaryRed,
                        ),
                      );
                      return;
                    }
                    favoritesProvider.toggleFavorite(recipe.id);
                  },
                ),
              ],
            ),
          ),

          // Like count
          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_likeCount begeni',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          // Recipe info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              recipe.description,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rating
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${recipe.averageRating.toStringAsFixed(1)} (${recipe.reviewCount} yorum)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

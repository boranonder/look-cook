import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../services/recipe_service.dart';
import '../../services/user_service.dart';
import '../recipe/recipe_detail_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final UserService _userService = UserService();
  final RecipeService _recipeService = RecipeService();
  User? _user;
  List<Recipe> _userRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Load follow data for this user to get accurate follower count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final followProvider = Provider.of<FollowProvider>(context, listen: false);
      followProvider.loadFollowData(widget.userId, forceReload: true);
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userService.getUser(widget.userId);

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }

      _recipeService.getUserRecipes(widget.userId).listen((recipes) {
        if (mounted) {
          setState(() {
            _userRecipes = recipes;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final currentUser = authProvider.currentUser;
    final isFollowing = currentUser != null
        ? followProvider.isFollowing(currentUser.id, widget.userId)
        : false;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName ?? 'Profil'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Kullanıcı bulunamadı'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.name),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: _user!.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _user!.profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              _user!.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_user!.bio != null && _user!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _user!.bio!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Tarif', _userRecipes.length.toString()),
                        _buildStat('Takipçi', followProvider.getFollowerCount(widget.userId).toString()),
                        _buildStat('Takip', followProvider.getFollowingCount(widget.userId).toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (currentUser != null && currentUser.id != widget.userId)
                      ElevatedButton(
                        onPressed: () {
                          followProvider.toggleFollow(
                            currentUser.id,
                            widget.userId,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFollowing ? Colors.white : AppTheme.lightRed,
                          foregroundColor:
                              isFollowing ? AppTheme.primaryRed : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Takipten Çık' : 'Takip Et',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Recipes Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tarifler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // Recipes List
          _userRecipes.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text('Henüz tarif yok'),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = _userRecipes[index];
                      return _buildRecipeCard(recipe);
                    },
                    childCount: _userRecipes.length,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.lightRed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: recipe.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipe.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                ),
        ),
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text('${recipe.averageRating.toStringAsFixed(1)}'),
            const SizedBox(width: 8),
            Text('(${recipe.reviewCount} yorum)'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
      ),
    );
  }
}

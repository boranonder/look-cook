import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/user.dart';
import '../../providers/language_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/recipe_service.dart';
import '../../services/user_service.dart';
import 'edit_profile_screen.dart';
import '../recipe/recipe_detail_screen.dart';
import '../auth/account_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  final UserService _userService = UserService();
  User? _user;
  List<Recipe> _userRecipes = [];
  bool _isCurrentUser = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final targetUserId = widget.userId ?? currentUser?.id;

    if (targetUserId != null) {
      setState(() => _isLoading = true);

      try {
        final user = await _userService.getUser(targetUserId);

        // Load follow data for the target user (to show follower/following counts)
        await followProvider.loadFollowData(targetUserId);

        if (mounted) {
          setState(() {
            _user = user ?? currentUser;
            _isCurrentUser = targetUserId == currentUser?.id;
            _isLoading = false;
          });
        }

        // Listen to user's recipes
        _recipeService.getUserRecipes(targetUserId).listen((recipes) {
          if (mounted) {
            setState(() {
              _userRecipes = recipes;
            });
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _user = currentUser;
            _isCurrentUser = true;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _user!),
      ),
    );
    
    if (result == true) {
      _loadUserData(); // Refresh user data
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final followProvider = Provider.of<FollowProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isFollowing = currentUser != null && _user != null 
        ? followProvider.isFollowing(currentUser.id, _user!.id)
        : false;

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.profile),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryRed,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCurrentUser ? l10n.profile : _user!.name),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showSettingsDialog(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
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
                  // Profile Image
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
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryRed,
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    _user!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _user!.bio!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Edit Profile / Follow Button
                  if (_isCurrentUser)
                    ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Profili Düzenle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                    )
                  else if (currentUser != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        followProvider.toggleFollow(currentUser.id, _user!.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFollowing 
                                  ? '${_user!.name} takipten çıkarıldı'
                                  : '${_user!.name} takip edildi',
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppTheme.primaryRed,
                          ),
                        );
                      },
                      icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
                      label: Text(isFollowing ? 'Takipten Çık' : 'Takip Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey[300] : Colors.white,
                        foregroundColor: isFollowing ? AppTheme.textDark : AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        label: 'Tarifler',
                        value: '${_user!.recipeCount > 0 ? _user!.recipeCount : _userRecipes.length}',
                      ),
                      _StatItem(
                        label: 'Takipçi',
                        value: '${_user!.followerCount > 0 ? _user!.followerCount : followProvider.getFollowerCount(_user!.id)}',
                      ),
                      _StatItem(
                        label: 'Takip',
                        value: '${_user!.followingCount > 0 ? _user!.followingCount : followProvider.getFollowingCount(_user!.id)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryRed,
            unselectedLabelColor: AppTheme.textLight,
            indicatorColor: AppTheme.primaryRed,
            tabs: [
              Tab(text: l10n.myRecipes),
              const Tab(text: 'Favoriler'),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RecipesList(recipes: _userRecipes),
                const _FavoritesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryRed),
              title: const Text('Hesap Ayarları'),
              subtitle: const Text('Şifre, e-posta değiştir'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Dil Değiştir'),
              onTap: () {
                Navigator.pop(context);
                _showLanguageDialog(this.context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Türkçe'),
                leading: const Icon(Icons.language),
                trailing: languageProvider.isTurkish 
                    ? const Icon(Icons.check, color: AppTheme.primaryRed)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('tr');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('English'),
                leading: const Icon(Icons.language),
                trailing: languageProvider.isEnglish 
                    ? const Icon(Icons.check, color: AppTheme.primaryRed)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _RecipesList extends StatelessWidget {
  final List<Recipe> recipes;

  const _RecipesList({required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: AppTheme.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz tarif yok',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 16,
              ),
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
        return _RecipeCard(
          recipe: recipe,
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

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              // Recipe Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.lightRed.withOpacity(0.3),
                      AppTheme.primaryRed.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 32,
                  ),
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
                      recipe.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
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
                          '(${recipe.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
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

class _FavoritesList extends StatefulWidget {
  const _FavoritesList();

  @override
  State<_FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<_FavoritesList> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final favoriteIds = favoritesProvider.favoriteRecipeIds.toList();

    if (favoriteIds.isEmpty) {
      setState(() {
        _favoriteRecipes = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch favorite recipes directly from database
      final recipes = await Future.wait(
        favoriteIds.map((id) => _recipeService.getRecipe(id)),
      );

      if (mounted) {
        setState(() {
          _favoriteRecipes = recipes.whereType<Recipe>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load favorites error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final favoriteIds = favoritesProvider.favoriteRecipeIds;

        // Reload if favorites changed
        if (!_isLoading && favoriteIds.length != _favoriteRecipes.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadFavorites();
          });
        }

        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        if (favoriteIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz kaydedilen tarif yok',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (_favoriteRecipes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadFavorites,
          color: AppTheme.primaryRed,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _favoriteRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _favoriteRecipes[index];
              return _RecipeCard(
                recipe: recipe,
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
        );
      },
    );
  }
}
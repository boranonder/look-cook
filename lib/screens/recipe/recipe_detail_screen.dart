import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../providers/favorites_provider.dart';
import '../../services/recipe_service.dart';
import '../../services/review_service.dart';
import '../profile/profile_screen.dart';
import 'edit_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  final TextEditingController _reviewController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  final ReviewService _reviewService = ReviewService();
  double _userRating = 5.0;
  int _currentImageIndex = 0;

  // Like state (Beğenme)
  bool _isLiked = false;
  int _likeCount = 0;

  // User's existing review (for edit mode)
  Review? _existingReview;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _likeCount = widget.recipe.likeCount;
    _checkLikeStatus();
    _incrementViewCount();
    _loadFullRecipe();
  }

  Future<void> _loadFullRecipe() async {
    // Load full recipe with reviews
    final fullRecipe = await _recipeService.getRecipe(_recipe.id);
    if (fullRecipe != null && mounted) {
      setState(() {
        _recipe = fullRecipe;
      });
    }
  }

  Future<void> _incrementViewCount() async {
    // Increment view count when recipe is opened
    await _recipeService.incrementViews(_recipe.id);
  }

  Future<void> _checkLikeStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final liked = await _recipeService.isLiked(_recipe.id, user.id);
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

    await _recipeService.toggleLike(_recipe.id, user.id);
  }

  void _shareRecipe() {
    final recipeUrl = 'https://lookcook.app/recipe/${_recipe.id}';
    final shareText = '${_recipe.name} - ${_recipe.authorName} tarafından\n\n'
        '${_recipe.description}\n\n'
        '$recipeUrl\n\n'
        'Look & Cook uygulamasında bu tarifi dene!';

    Share.share(shareText, subject: _recipe.name);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _addRatingOnly() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puan vermek için giriş yapmalısınız'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    // Get user profile for name
    final userProfile = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    final userName = userProfile?['name'] ?? user.email?.split('@')[0] ?? 'Kullanıcı';

    // Check if user already has a review
    final existingReview = await _reviewService.getUserReview(_recipe.id, user.id);

    if (existingReview != null) {
      // Update existing review with new rating only
      final updatedReview = Review(
        id: existingReview.id,
        recipeId: _recipe.id,
        userId: user.id,
        userName: userName,
        rating: _userRating,
        comment: existingReview.comment, // Keep existing comment
        createdAt: existingReview.createdAt,
      );
      await _reviewService.updateReview(updatedReview);
    } else {
      // Add new rating-only review
      final review = Review(
        id: const Uuid().v4(),
        recipeId: _recipe.id,
        userId: user.id,
        userName: userName,
        rating: _userRating,
        comment: '',
        createdAt: DateTime.now(),
      );
      await _reviewService.addReview(review);
    }

    // Update local state
    setState(() {
      _userRating = 5.0;
    });

    // Refresh recipe
    final updatedRecipe = await _recipeService.getRecipe(_recipe.id);
    if (updatedRecipe != null && mounted) {
      setState(() {
        _recipe = updatedRecipe;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puan başarıyla verildi!'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  Future<void> _saveReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Get user profile for name
    final userProfile = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    final userName = userProfile?['name'] ?? user.email?.split('@')[0] ?? 'Kullanıcı';

    if (_existingReview != null) {
      // Update existing review
      final updatedReview = Review(
        id: _existingReview!.id,
        recipeId: _recipe.id,
        userId: user.id,
        userName: userName,
        rating: _userRating,
        comment: _reviewController.text.trim(),
        createdAt: _existingReview!.createdAt,
      );

      await _reviewService.updateReview(updatedReview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum güncellendi!'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } else {
      // Add new review
      final review = Review(
        id: const Uuid().v4(),
        recipeId: _recipe.id,
        userId: user.id,
        userName: userName,
        rating: _userRating,
        comment: _reviewController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _reviewService.addReview(review);

      if (mounted) {
        final message = _reviewController.text.trim().isEmpty
            ? 'Puan başarıyla verildi!'
            : 'Yorum başarıyla eklendi!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }

    // Clear state
    setState(() {
      _reviewController.clear();
      _userRating = 5.0;
      _existingReview = null;
    });

    // Refresh recipe
    final updatedRecipe = await _recipeService.getRecipe(_recipe.id);
    if (updatedRecipe != null && mounted) {
      setState(() {
        _recipe = updatedRecipe;
      });
    }
  }

  Future<void> _showAddReviewDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loginToComment),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    // Check if user already has a review
    _existingReview = await _reviewService.getUserReview(_recipe.id, user.id);

    // Pre-fill if editing existing review
    if (_existingReview != null) {
      _userRating = _existingReview!.rating;
      _reviewController.text = _existingReview!.comment;
    } else {
      _userRating = 5.0;
      _reviewController.clear();
    }

    if (!mounted) return;

    final isEditing = _existingReview != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Yorumu Düzenle' : l10n.addReview,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                l10n.rating,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              RatingBar.builder(
                initialRating: _userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 40,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  _userRating = rating;
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  hintText: 'Yorumunuzu yazın...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _addRatingOnly();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Sadece Puan'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _saveReview();
                        Navigator.of(context).pop();
                      },
                      child: Text(isEditing ? 'Güncelle' : l10n.save),
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

  Widget _buildImageSection() {
    final allImages = <String>[];
    if (_recipe.imageUrls.isNotEmpty) {
      allImages.addAll(_recipe.imageUrls);
    } else if (_recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty) {
      allImages.add(_recipe.imageUrl!);
    }

    if (allImages.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.lightRed.withOpacity(0.3),
              AppTheme.primaryRed.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 100,
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: allImages.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: allImages[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppTheme.lightRed.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.lightRed.withOpacity(0.3),
                      AppTheme.primaryRed.withOpacity(0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        // Page indicator
        if (allImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 12 : 8,
                  height: _currentImageIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(_recipe.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            actions: [
              // Edit button (only for owner)
              if (Supabase.instance.client.auth.currentUser?.id == _recipe.authorId)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    final updatedRecipe = await Navigator.push<Recipe>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRecipeScreen(recipe: _recipe),
                      ),
                    );
                    if (updatedRecipe != null && mounted) {
                      setState(() {
                        _recipe = updatedRecipe;
                      });
                    }
                  },
                  tooltip: 'Düzenle',
                ),
              // Share button (Paylaş)
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareRecipe,
                tooltip: 'Paylaş',
              ),
              // Like button (Beğenme)
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _toggleLike,
                tooltip: 'Beğen',
              ),
              // Save/Favorite button (Kaydetme)
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorite ? Colors.amber : Colors.white,
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
                  favoritesProvider.toggleFavorite(_recipe.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Kaydedilenlerden çıkarıldı'
                            : 'Kaydedildi',
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppTheme.primaryRed,
                    ),
                  );
                },
                tooltip: 'Kaydet',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSection(),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Title and Author
                  Text(
                    _recipe.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: _recipe.authorId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 20,
                          color: AppTheme.primaryRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'by ${_recipe.authorName}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    _recipe.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rating and Reviews
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: _recipe.averageRating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_recipe.averageRating.toStringAsFixed(1)} (${_recipe.reviewCount} ${l10n.reviews.toLowerCase()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ingredients Section
                  _SectionTitle(
                    title: l10n.ingredients,
                    icon: Icons.shopping_cart,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recipe.ingredients.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _recipe.ingredients[index],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Instructions Section
                  _SectionTitle(
                    title: l10n.instructions,
                    icon: Icons.list_alt,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recipe.instructions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryRed,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _recipe.instructions[index],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title: l10n.reviews,
                        icon: Icons.rate_review,
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addReview),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (_recipe.reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Henüz yorum yok',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recipe.reviews.where((r) => r.comment.isNotEmpty).length,
                      itemBuilder: (context, index) {
                        final reviewsWithComments = _recipe.reviews.where((r) => r.comment.isNotEmpty).toList();
                        final review = reviewsWithComments[index];
                        return _ReviewItem(review: review);
                      },
                    ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryRed,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;

  const _ReviewItem({required this.review});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else {
      return '${difference} gün önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryRed,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 16,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
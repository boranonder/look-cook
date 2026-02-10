import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/recipe_category.dart';
import 'recipe_detail_screen.dart';

enum SortOption {
  highestRating,
  newest,
  mostReviewed,
  mostFavorited,
  mostLiked,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.highestRating:
        return 'En Yuksek Puan';
      case SortOption.newest:
        return 'En Yeni';
      case SortOption.mostReviewed:
        return 'En Cok Yorumlanan';
      case SortOption.mostFavorited:
        return 'En Cok Kaydedilen';
      case SortOption.mostLiked:
        return 'En Cok Begenilen';
    }
  }

  String get description {
    switch (this) {
      case SortOption.highestRating:
        return 'Puana gore sirala';
      case SortOption.newest:
        return 'Yeni eklenenler once';
      case SortOption.mostReviewed:
        return 'Cok degerlendirilen once';
      case SortOption.mostFavorited:
        return 'Cok kaydedilen once';
      case SortOption.mostLiked:
        return 'Cok begenilen once';
    }
  }

  String get column {
    switch (this) {
      case SortOption.highestRating:
        return 'average_rating';
      case SortOption.newest:
        return 'created_at';
      case SortOption.mostReviewed:
        return 'review_count';
      case SortOption.mostFavorited:
        return 'favorite_count';
      case SortOption.mostLiked:
        return 'like_count';
    }
  }
}

enum MinReviewFilter {
  all,
  min10,
  min25,
  min50,
  min100,
}

extension MinReviewFilterExtension on MinReviewFilter {
  String get displayName {
    switch (this) {
      case MinReviewFilter.all:
        return 'Tumu';
      case MinReviewFilter.min10:
        return '10+ yorum';
      case MinReviewFilter.min25:
        return '25+ yorum';
      case MinReviewFilter.min50:
        return '50+ yorum';
      case MinReviewFilter.min100:
        return '100+ yorum';
    }
  }

  int get value {
    switch (this) {
      case MinReviewFilter.all:
        return 0;
      case MinReviewFilter.min10:
        return 10;
      case MinReviewFilter.min25:
        return 25;
      case MinReviewFilter.min50:
        return 50;
      case MinReviewFilter.min100:
        return 100;
    }
  }
}

enum MinRatingFilter {
  all,
  min3,
  min35,
  min4,
  min45,
}

extension MinRatingFilterExtension on MinRatingFilter {
  String get displayName {
    switch (this) {
      case MinRatingFilter.all:
        return 'Tumu';
      case MinRatingFilter.min3:
        return '3.0+ puan';
      case MinRatingFilter.min35:
        return '3.5+ puan';
      case MinRatingFilter.min4:
        return '4.0+ puan';
      case MinRatingFilter.min45:
        return '4.5+ puan';
    }
  }

  double get value {
    switch (this) {
      case MinRatingFilter.all:
        return 0;
      case MinRatingFilter.min3:
        return 3.0;
      case MinRatingFilter.min35:
        return 3.5;
      case MinRatingFilter.min4:
        return 4.0;
      case MinRatingFilter.min45:
        return 4.5;
    }
  }
}

class RecipesListScreen extends StatefulWidget {
  final String title;
  final SortOption initialSort;
  final RecipeCategory? initialCategory;
  final String? searchQuery;
  final MinReviewFilter initialMinReview;
  final MinRatingFilter initialMinRating;

  const RecipesListScreen({
    super.key,
    required this.title,
    this.initialSort = SortOption.highestRating,
    this.initialCategory,
    this.searchQuery,
    this.initialMinReview = MinReviewFilter.all,
    this.initialMinRating = MinRatingFilter.all,
  });

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();

  List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  late SortOption _currentSort;
  RecipeCategory? _selectedCategory;
  late MinReviewFilter _minReviewFilter;
  late MinRatingFilter _minRatingFilter;

  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentSort = widget.initialSort;
    _selectedCategory = widget.initialCategory;
    _minReviewFilter = widget.initialMinReview;
    _minRatingFilter = widget.initialMinRating;
    _loadRecipes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRecipes();
    }
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _recipes = [];
      _hasMore = true;
    });

    try {
      var query = _supabase.from('recipes').select();

      if (_selectedCategory != null) {
        query = query.eq('category', _selectedCategory!.name);
      }
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        query = query.or('name.ilike.%${widget.searchQuery}%,description.ilike.%${widget.searchQuery}%');
      }
      if (_minReviewFilter.value > 0) {
        query = query.gte('review_count', _minReviewFilter.value);
      }
      if (_minRatingFilter.value > 0) {
        query = query.gte('average_rating', _minRatingFilter.value);
      }

      final response = await query
          .order(_currentSort.column, ascending: false)
          .limit(100);

      final responseList = response is List ? response : [];
      final allRecipes = responseList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();

      setState(() {
        _recipes = allRecipes;
        _isLoading = false;
        _hasMore = false;
      });
    } catch (e) {
      debugPrint('Error loading recipes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final start = _currentPage * _pageSize;
      final end = start + _pageSize - 1;

      var query = _supabase.from('recipes').select();

      if (_selectedCategory != null) {
        query = query.eq('category', _selectedCategory!.name);
      }
      if (_minReviewFilter.value > 0) {
        query = query.gte('review_count', _minReviewFilter.value);
      }
      if (_minRatingFilter.value > 0) {
        query = query.gte('average_rating', _minRatingFilter.value);
      }

      final response = await query
          .order(_currentSort.column, ascending: false)
          .range(start, end);

      final responseList = response is List ? response : [];
      setState(() {
        _recipes.addAll(responseList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)));
        _isLoadingMore = false;
        _hasMore = responseList.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('Error loading more recipes: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Siralama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...SortOption.values.map((option) => ListTile(
                    leading: Icon(
                      _getSortIcon(option),
                      color: _currentSort == option ? AppTheme.primaryRed : Colors.grey,
                    ),
                    title: Text(option.displayName),
                    subtitle: Text(option.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    trailing: _currentSort == option
                        ? const Icon(Icons.check, color: AppTheme.primaryRed)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentSort != option) {
                        setState(() {
                          _currentSort = option;
                        });
                        _loadRecipes();
                      }
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return Icons.schedule;
      case SortOption.highestRating:
        return Icons.star;
      case SortOption.mostReviewed:
        return Icons.chat_bubble;
      case SortOption.mostFavorited:
        return Icons.bookmark;
      case SortOption.mostLiked:
        return Icons.favorite;
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Filtreler',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Category filter
                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tumu'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedCategory = null;
                            });
                          },
                          selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                        ),
                        ...RecipeCategory.values.map((cat) => FilterChip(
                              label: Text('${cat.emoji} ${cat.displayName}'),
                              selected: _selectedCategory == cat,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedCategory = selected ? cat : null;
                                });
                              },
                              selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                            )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Min review filter
                    const Text('Minimum Degerlendirme', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MinReviewFilter.values.map((filter) => FilterChip(
                            label: Text(filter.displayName),
                            selected: _minReviewFilter == filter,
                            onSelected: (selected) {
                              setModalState(() {
                                _minReviewFilter = selected ? filter : MinReviewFilter.all;
                              });
                            },
                            selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                          )).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Min rating filter
                    const Text('Minimum Puan', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MinRatingFilter.values.map((filter) => FilterChip(
                            label: Text(filter.displayName),
                            selected: _minRatingFilter == filter,
                            onSelected: (selected) {
                              setModalState(() {
                                _minRatingFilter = selected ? filter : MinRatingFilter.all;
                              });
                            },
                            selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                          )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                          _loadRecipes();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Uygula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_minReviewFilter != MinReviewFilter.all) count++;
    if (_minRatingFilter != MinRatingFilter.all) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _getActiveFilterCount();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterOptions,
                tooltip: 'Filtrele',
              ),
              if (filterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sirala',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters display
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getSortIcon(_currentSort), size: 14, color: AppTheme.primaryRed),
                        const SizedBox(width: 4),
                        Text(
                          _currentSort.displayName,
                          style: const TextStyle(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedCategory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_selectedCategory!.emoji} ${_selectedCategory!.displayName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${_recipes.length} tarif',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Recipe list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryRed),
                  )
                : _recipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tarif bulunamadi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Filtreleri degistirmeyi deneyin',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecipes,
                        color: AppTheme.primaryRed,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _recipes.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _recipes.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                                ),
                              );
                            }

                            final recipe = _recipes[index];

                            return _RecipeCard(
                              recipe: recipe,
                              rank: index + 1,
                              sortOption: _currentSort,
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
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int rank;
  final SortOption sortOption;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.rank,
    required this.sortOption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rank <= 3 ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
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

              // Recipe Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(recipe.category.emoji, style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.authorName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          recipe.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.reviewCount}',
                          style: TextStyle(
                            color: recipe.reviewCount >= 50 ? Colors.green[700] : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: recipe.reviewCount >= 50 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite_border, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.likeCount}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
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

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppTheme.primaryRed;
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
        child: Text(recipe.category.emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/recipe_category.dart';
import '../../models/user.dart' as app_user;
import '../../services/algolia_service.dart';
import '../recipe/recipe_detail_screen.dart';
import '../category/category_recipes_screen.dart';
import '../profile/other_user_profile_screen.dart';
import '../recipe/recipes_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AlgoliaService _algoliaService = AlgoliaService();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;

  List<Recipe> _searchResults = [];
  List<app_user.User> _userResults = [];
  RecipeCategory? _selectedCategory;
  SortOption _sortOption = SortOption.highestRating;
  MinReviewFilter _minReviewFilter = MinReviewFilter.all;
  MinRatingFilter _minRatingFilter = MinRatingFilter.all;
  bool _isSearching = false;
  bool _isLoading = false;
  bool _useAlgolia = false;
  bool _showCategories = true;
  int _selectedTabIndex = 0; // 0: Tarifler, 1: Kullanıcılar

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        _performSearch();
      }
    });
    _useAlgolia = _algoliaService.isConfigured();
    _searchController.addListener(_onSearchChanged);
    // Auto focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      _showCategories = query.isEmpty && _selectedCategory == null;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty && _selectedCategory == null) {
      setState(() {
        _searchResults = [];
        _userResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedTabIndex == 0) {
        // Search recipes
        List<Recipe> results;

        if (_useAlgolia && query.isNotEmpty) {
          // Use Algolia for text search
          results = await _algoliaService.searchRecipes(
            query,
            category: _selectedCategory,
          );
        } else {
          // Standard sorting
          var queryBuilder = _supabase.from('recipes').select();

          if (_selectedCategory != null) {
            queryBuilder = queryBuilder.eq('category', _selectedCategory!.name);
          }
          if (query.isNotEmpty) {
            queryBuilder = queryBuilder.or('name.ilike.%$query%,description.ilike.%$query%,author_name.ilike.%$query%');
          }
          if (_minReviewFilter.value > 0) {
            queryBuilder = queryBuilder.gte('review_count', _minReviewFilter.value);
          }
          if (_minRatingFilter.value > 0) {
            queryBuilder = queryBuilder.gte('average_rating', _minRatingFilter.value);
          }

          final response = await queryBuilder
              .order(_sortOption.column, ascending: false)
              .limit(50);

          final responseList = response is List ? response : [];
          results = responseList.map((r) => Recipe.fromMap(r as Map<String, dynamic>)).toList();
        }

        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } else {
        // Search users
        if (query.isEmpty) {
          setState(() {
            _userResults = [];
            _isLoading = false;
          });
          return;
        }

        final response = await _supabase
            .from('users')
            .select()
            .or('name.ilike.%$query%,email.ilike.%$query%')
            .order('follower_count', ascending: false)
            .limit(50);

        setState(() {
          _userResults = (response as List).map((u) => app_user.User.fromMap(u)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults = [];
        _userResults = [];
        _isLoading = false;
      });
    }
  }

  void _selectCategory(RecipeCategory? category) {
    setState(() {
      _selectedCategory = category;
      _showCategories = false;
    });
    _performSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
      _searchResults = [];
      _userResults = [];
      _isSearching = false;
      _showCategories = true;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
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
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      shrinkWrap: true,
                      children: SortOption.values.map((option) => ListTile(
                            leading: Icon(
                              _getSortIcon(option),
                              color: _sortOption == option ? AppTheme.primaryRed : Colors.grey,
                            ),
                            title: Text(option.displayName),
                            subtitle: Text(option.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            trailing: _sortOption == option
                                ? const Icon(Icons.check, color: AppTheme.primaryRed)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              if (_sortOption != option) {
                                setState(() {
                                  _sortOption = option;
                                });
                                _performSearch();
                              }
                            },
                          )).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
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
                      'Gelismis Filtreler',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Min review filter
                    const Text('Minimum Degerlendirme Sayisi', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          _performSearch();
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
    if (_minReviewFilter != MinReviewFilter.all) count++;
    if (_minRatingFilter != MinRatingFilter.all) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            hintText: _selectedTabIndex == 0
                ? 'Tarif veya malzeme ara...'
                : 'Kullanici ara...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        actions: [
          if (_selectedTabIndex == 0) ...[
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87),
                  onPressed: _showFilterOptions,
                  tooltip: 'Filtrele',
                ),
                if (_getActiveFilterCount() > 0)
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
                        '${_getActiveFilterCount()}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.sort, color: Colors.black87),
              onPressed: _showSortOptions,
              tooltip: 'Sirala',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryRed,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryRed,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 18),
                      SizedBox(width: 8),
                      Text('Tarifler'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 18),
                      SizedBox(width: 8),
                      Text('Kullanıcılar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tarifler Tab
          Column(
            children: [
              // Category filter chips and sort info (only for recipes)
              if ((_selectedCategory != null || _isSearching) && _selectedTabIndex == 0)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Sort chip
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                        child: Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: _showSortOptions,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getSortIcon(_sortOption), size: 16, color: AppTheme.primaryRed),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _sortOption.displayName,
                                          style: const TextStyle(
                                            color: AppTheme.primaryRed,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primaryRed),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_searchResults.length} sonuc',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Category chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: 'Tumu',
                              emoji: '',
                              isSelected: _selectedCategory == null,
                              onTap: () => _selectCategory(null),
                            ),
                            ...RecipeCategory.values.map((category) => _CategoryChip(
                                  label: category.displayName,
                                  emoji: category.emoji,
                                  isSelected: _selectedCategory == category,
                                  onTap: () => _selectCategory(category),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Content
              Expanded(
                child: _showCategories
                    ? _buildCategoriesGrid()
                    : _buildSearchResults(),
              ),
            ],
          ),

          // Kullanıcılar Tab
          _buildUserResults(),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    if (_isLoading && _selectedTabIndex == 1) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (!_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Kullanıcı Ara',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İsim veya e-posta ile arayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_userResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Kullanıcı bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir isim deneyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _UserResultCard(
          user: user,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OtherUserProfileScreen(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategorilere Göz At',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: RecipeCategory.values.length,
            itemBuilder: (context, index) {
              final category = RecipeCategory.values[index];
              final colors = CategoryColors.categoryGradients[category] ??
                  [0xFFE53E3E, 0xFFC53030];

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryRecipesScreen(category: category),
                    ),
                  );
                },
                child: Container(
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
                      Text(category.emoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi deneyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final recipe = _searchResults[index];
        return _SearchResultCard(
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryRed : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryRed : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.recipe,
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
                          placeholder: (context, url) =>
                              _buildPlaceholder(recipe),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(recipe),
                        )
                      : _buildPlaceholder(recipe),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            recipe.category.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
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
                          '${recipe.averageRating.toStringAsFixed(1)} (${recipe.reviewCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          recipe.authorName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryRed,
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
      ),
    );
  }

  Widget _buildPlaceholder(Recipe recipe) {
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
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  final app_user.User user;
  final VoidCallback onTap;

  const _UserResultCard({
    required this.user,
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
              // User Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${user.followerCount} takipçi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.restaurant_menu, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${user.recipeCount} tarif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

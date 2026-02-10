import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart' as app_user;
import '../profile/other_user_profile_screen.dart';

class PopularChefsScreen extends StatefulWidget {
  const PopularChefsScreen({super.key});

  @override
  State<PopularChefsScreen> createState() => _PopularChefsScreenState();
}

class _PopularChefsScreenState extends State<PopularChefsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<app_user.User> _chefs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPopularChefs();
  }

  Future<void> _loadPopularChefs() async {
    setState(() => _isLoading = true);

    try {
      // Get users with most followers
      final response = await _supabase
          .from('users')
          .select()
          .order('follower_count', ascending: false)
          .limit(50);

      final usersList = response is List ? response : [];
      setState(() {
        _chefs = usersList.map((u) => app_user.User.fromMap(u as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading popular chefs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Populer Ascilar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _chefs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Henuz populer asci yok',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPopularChefs,
                  color: AppTheme.primaryRed,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chefs.length,
                    itemBuilder: (context, index) {
                      final chef = _chefs[index];
                      return _ChefListItem(
                        chef: chef,
                        rank: index + 1,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OtherUserProfileScreen(userId: chef.id),
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

class _ChefListItem extends StatelessWidget {
  final app_user.User chef;
  final int rank;
  final VoidCallback onTap;

  const _ChefListItem({
    required this.chef,
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
              // Chef avatar
              CircleAvatar(
                radius: 30,
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
              const SizedBox(width: 12),
              // Chef info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chef.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chef.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.amber, size: 12),
                                SizedBox(width: 2),
                                Text(
                                  'Admin',
                                  style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (chef.bio != null && chef.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        chef.bio!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${chef.followerCount} takipci',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.restaurant_menu, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${chef.recipeCount} tarif',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

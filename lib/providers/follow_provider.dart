import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // userId -> Set<followingUserId>
  final Map<String, Set<String>> _followingMap = {};

  // userId -> Set<followerUserId>
  final Map<String, Set<String>> _followersMap = {};

  // Track loading state per user
  final Set<String> _loadedUsers = {};

  // Realtime subscription
  RealtimeChannel? _followsChannel;
  String? _currentUserId;

  // Check if currentUser follows targetUser
  bool isFollowing(String currentUserId, String targetUserId) {
    return _followingMap[currentUserId]?.contains(targetUserId) ?? false;
  }

  // Get following list for a user
  Set<String> getFollowing(String userId) {
    return _followingMap[userId] ?? {};
  }

  // Get followers list for a user
  Set<String> getFollowers(String userId) {
    return _followersMap[userId] ?? {};
  }

  // Get following count
  int getFollowingCount(String userId) {
    return _followingMap[userId]?.length ?? 0;
  }

  // Get follower count
  int getFollowerCount(String userId) {
    return _followersMap[userId]?.length ?? 0;
  }

  // Load follow data from Supabase for a user
  Future<void> loadFollowData(String userId, {bool forceReload = false}) async {
    if (_loadedUsers.contains(userId) && !forceReload) return;

    try {
      // Load who this user is following
      final followingResponse = await _supabase
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (followingResponse as List)
          .map((r) => r['following_id'] as String)
          .toSet();

      _followingMap[userId] = followingIds;

      // Load who is following this user
      final followersResponse = await _supabase
          .from('user_follows')
          .select('follower_id')
          .eq('following_id', userId);

      final followerIds = (followersResponse as List)
          .map((r) => r['follower_id'] as String)
          .toSet();

      _followersMap[userId] = followerIds;

      _loadedUsers.add(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading follow data: $e');
    }
  }

  // Subscribe to realtime updates for follows
  void subscribeToRealtimeUpdates(String userId) {
    if (_currentUserId == userId && _followsChannel != null) return;

    // Unsubscribe from previous channel if exists
    _followsChannel?.unsubscribe();
    _currentUserId = userId;

    // Subscribe to user_follows table changes
    _followsChannel = _supabase
        .channel('user_follows_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_follows',
          callback: (payload) {
            _handleFollowInsert(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'user_follows',
          callback: (payload) {
            _handleFollowDelete(payload.oldRecord);
          },
        )
        .subscribe();

    debugPrint('Subscribed to realtime follow updates for user: $userId');
  }

  void _handleFollowInsert(Map<String, dynamic> newRecord) {
    final followerId = newRecord['follower_id'] as String?;
    final followingId = newRecord['following_id'] as String?;

    if (followerId == null || followingId == null) return;

    // Update following map
    _followingMap.putIfAbsent(followerId, () => {});
    _followingMap[followerId]!.add(followingId);

    // Update followers map
    _followersMap.putIfAbsent(followingId, () => {});
    _followersMap[followingId]!.add(followerId);

    debugPrint('Realtime: $followerId now follows $followingId');
    notifyListeners();
  }

  void _handleFollowDelete(Map<String, dynamic> oldRecord) {
    final followerId = oldRecord['follower_id'] as String?;
    final followingId = oldRecord['following_id'] as String?;

    if (followerId == null || followingId == null) return;

    // Update following map
    _followingMap[followerId]?.remove(followingId);

    // Update followers map
    _followersMap[followingId]?.remove(followerId);

    debugPrint('Realtime: $followerId unfollowed $followingId');
    notifyListeners();
  }

  // Unsubscribe from realtime updates
  void unsubscribeFromRealtimeUpdates() {
    _followsChannel?.unsubscribe();
    _followsChannel = null;
    _currentUserId = null;
  }

  // Follow a user (with Supabase sync)
  Future<void> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return;
    if (isFollowing(currentUserId, targetUserId)) return;

    // Optimistic update
    _followingMap.putIfAbsent(currentUserId, () => {});
    _followingMap[currentUserId]!.add(targetUserId);

    _followersMap.putIfAbsent(targetUserId, () => {});
    _followersMap[targetUserId]!.add(currentUserId);

    notifyListeners();

    try {
      // Insert into Supabase
      // Note: follower_count and following_count are updated by database trigger
      await _supabase.from('user_follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });
    } catch (e) {
      // Rollback on error
      _followingMap[currentUserId]?.remove(targetUserId);
      _followersMap[targetUserId]?.remove(currentUserId);
      notifyListeners();
      debugPrint('Error following user: $e');
    }
  }

  // Unfollow a user (with Supabase sync)
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    if (!isFollowing(currentUserId, targetUserId)) return;

    // Optimistic update
    _followingMap[currentUserId]?.remove(targetUserId);
    _followersMap[targetUserId]?.remove(currentUserId);

    notifyListeners();

    try {
      // Delete from Supabase
      // Note: follower_count and following_count are updated by database trigger
      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);
    } catch (e) {
      // Rollback on error
      _followingMap.putIfAbsent(currentUserId, () => {});
      _followingMap[currentUserId]!.add(targetUserId);
      _followersMap.putIfAbsent(targetUserId, () => {});
      _followersMap[targetUserId]!.add(currentUserId);
      notifyListeners();
      debugPrint('Error unfollowing user: $e');
    }
  }

  // Toggle follow/unfollow
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    if (isFollowing(currentUserId, targetUserId)) {
      await unfollowUser(currentUserId, targetUserId);
    } else {
      await followUser(currentUserId, targetUserId);
    }
  }

  // Clear data on logout
  void clearData() {
    unsubscribeFromRealtimeUpdates();
    _followingMap.clear();
    _followersMap.clear();
    _loadedUsers.clear();
    notifyListeners();
  }

  // Initialize with mock data (kept for backwards compatibility)
  void initializeFollowData(Map<String, List<String>> followingData) {
    followingData.forEach((userId, followingList) {
      _followingMap[userId] = Set<String>.from(followingList);

      for (var followedUserId in followingList) {
        _followersMap.putIfAbsent(followedUserId, () => {});
        _followersMap[followedUserId]!.add(userId);
      }
    });

    notifyListeners();
  }
}


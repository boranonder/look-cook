class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final DateTime createdAt;
  final List<String> recipeIds;
  final int followerCount;
  final int followingCount;
  final int recipeCount;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.bio,
    required this.createdAt,
    this.recipeIds = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    this.recipeCount = 0,
    this.isAdmin = false,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? bio,
    DateTime? createdAt,
    List<String>? recipeIds,
    int? followerCount,
    int? followingCount,
    int? recipeCount,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      recipeIds: recipeIds ?? this.recipeIds,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      recipeCount: recipeCount ?? this.recipeCount,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'recipeIds': recipeIds,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'recipeCount': recipeCount,
      'isAdmin': isAdmin,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    // Handle both snake_case (Supabase) and camelCase formats
    DateTime createdAtDate;
    final createdAtValue = map['created_at'] ?? map['createdAt'];
    if (createdAtValue is String) {
      createdAtDate = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else if (createdAtValue is int) {
      createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else {
      createdAtDate = DateTime.now();
    }

    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profile_image_url'] ?? map['profileImageUrl'],
      bio: map['bio'],
      createdAt: createdAtDate,
      recipeIds: List<String>.from(map['recipe_ids'] ?? map['recipeIds'] ?? []),
      followerCount: map['follower_count'] ?? map['followerCount'] ?? 0,
      followingCount: map['following_count'] ?? map['followingCount'] ?? 0,
      recipeCount: map['recipe_count'] ?? map['recipeCount'] ?? 0,
      isAdmin: map['is_admin'] ?? map['isAdmin'] ?? false,
    );
  }
}

import 'recipe_category.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final double averageRating;
  final int reviewCount;
  final List<Review> reviews;
  final RecipeCategory category;
  final int viewCount;
  final int favoriteCount;
  final int likeCount;
  final List<String> tags;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.reviews = const [],
    required this.category,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.likeCount = 0,
    this.tags = const [],
  });

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    String? imageUrl,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    double? averageRating,
    int? reviewCount,
    List<Review>? reviews,
    RecipeCategory? category,
    int? viewCount,
    int? favoriteCount,
    int? likeCount,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      reviews: reviews ?? this.reviews,
      category: category ?? this.category,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      likeCount: likeCount ?? this.likeCount,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      'average_rating': averageRating,
      'review_count': reviewCount,
      'category': category.name,
      'view_count': viewCount,
      'favorite_count': favoriteCount,
      'like_count': likeCount,
      'tags': tags,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
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

    return Recipe(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      imageUrl: map['image_url'] ?? map['imageUrl'],
      imageUrls: List<String>.from(map['image_urls'] ?? map['imageUrls'] ?? []),
      videoUrls: List<String>.from(map['video_urls'] ?? map['videoUrls'] ?? []),
      authorId: map['author_id'] ?? map['authorId'] ?? '',
      authorName: map['author_name'] ?? map['authorName'] ?? '',
      createdAt: createdAtDate,
      averageRating: (map['average_rating'] ?? map['averageRating'] ?? 0.0).toDouble(),
      reviewCount: map['review_count'] ?? map['reviewCount'] ?? 0,
      reviews: List<Review>.from(
        (map['reviews'] ?? []).map((x) => Review.fromMap(x)),
      ),
      category: RecipeCategory.fromString(map['category'] ?? 'evYemekleri'),
      viewCount: map['view_count'] ?? map['viewCount'] ?? 0,
      favoriteCount: map['favorite_count'] ?? map['favoriteCount'] ?? 0,
      likeCount: map['like_count'] ?? map['likeCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class Review {
  final String id;
  final String recipeId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Review copyWith({
    String? id,
    String? recipeId,
    String? userId,
    String? userName,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
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

    return Review(
      id: map['id'] ?? '',
      recipeId: map['recipe_id'] ?? map['recipeId'] ?? '',
      userId: map['user_id'] ?? map['userId'] ?? '',
      userName: map['user_name'] ?? map['userName'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: createdAtDate,
    );
  }
}
// category_model.dart
class Category {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.isActive,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}

// food_item.dart
class FoodItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final String categoryId;
  final bool isAvailable;
  final bool isPopular;
  final String createdAt;
  final String updatedAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.isAvailable,
    required this.isPopular,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    try {
      print('FoodItem.fromJson - Processing: ${json['name']}');
      print('FoodItem.fromJson - Raw data: $json');

      final foodItem = FoodItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: _parsePrice(json['price']),
        imageUrl: json['imageUrl']?.toString() ?? '',
        categoryId: json['categoryId']?.toString() ?? '',
        isAvailable: _parseBool(json['isAvailable']),
        isPopular: _parseBool(json['isPopular']),
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
      );

      print('FoodItem.fromJson - Success: ${foodItem.name} (${foodItem.categoryId})');
      return foodItem;
    } catch (e, stackTrace) {
      print('FoodItem.fromJson - ERROR: $e');
      print('FoodItem.fromJson - Stack trace: $stackTrace');
      print('FoodItem.fromJson - Failed data: $json');
      rethrow;
    }
  }

  // Helper method để parse price an toàn
  static int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.toInt();
    if (price is String) {
      return int.tryParse(price) ?? 0;
    }
    return 0;
  }

  // Helper method để parse boolean an toàn
  static bool _parseBool(dynamic value) {
    if (value == null) return true; // Default to true for isAvailable
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) return value == 1;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Format price to Vietnamese currency
  String get formattedPrice {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? imageUrl,
    String? categoryId,
    bool? isAvailable,
    bool? isPopular,
    String? createdAt,
    String? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FoodItem{id: $id, name: $name, categoryId: $categoryId, isAvailable: $isAvailable}';
  }
}
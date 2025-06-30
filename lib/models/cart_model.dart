// models/cart.dart
import 'cart_item_model.dart';

class Cart {
  final String userId;
  final Map<String, CartItem> items;
  final String updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.updatedAt,
  });

  factory Cart.fromJson(String userId, Map<String, dynamic> json) {
    Map<String, CartItem> itemsMap = {};

    if (json['items'] != null) {
      json['items'].forEach((key, value) {
        itemsMap[key] = CartItem.fromJson(value);
      });
    }

    return Cart(
      userId: userId,
      items: itemsMap,
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> itemsJson = {};
    items.forEach((key, value) {
      itemsJson[key] = value.toJson();
    });

    return {
      'userId': userId,
      'items': itemsJson,
      'updatedAt': updatedAt,
    };
  }

  // Calculate total items count
  int get totalItems {
    return items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // Calculate total price
  int get totalPrice {
    return items.values.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  Cart copyWith({
    String? userId,
    Map<String, CartItem>? items,
    String? updatedAt,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
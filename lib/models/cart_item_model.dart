class CartItem {
  final String foodId;
  final int quantity;
  final int price;
  final String addedAt;

  CartItem({
    required this.foodId,
    required this.quantity,
    required this.price,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      foodId: json['foodId'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      addedAt: json['addedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'quantity': quantity,
      'price': price,
      'addedAt': addedAt,
    };
  }

  // Calculate total price for this item
  int get totalPrice => price * quantity;

  CartItem copyWith({
    String? foodId,
    int? quantity,
    int? price,
    String? addedAt,
  }) {
    return CartItem(
      foodId: foodId ?? this.foodId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}


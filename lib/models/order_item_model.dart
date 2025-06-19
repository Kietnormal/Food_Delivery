class OrderItem {
  final String foodId;
  final String foodName;
  final int quantity;
  final int price;
  final int total;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['foodId'] ?? '',
      foodName: json['foodName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  OrderItem copyWith({
    String? foodId,
    String? foodName,
    int? quantity,
    int? price,
    int? total,
  }) {
    return OrderItem(
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
    );
  }
}
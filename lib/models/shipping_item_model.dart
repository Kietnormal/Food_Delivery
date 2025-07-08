class ShippingItem {
  final String name;
  final int quantity;
  final int height; // cm
  final int weight; // gram
  final int length; // cm
  final int width; // cm

  ShippingItem({
    required this.name,
    required this.quantity,
    this.height = 10,
    this.weight = 100,
    this.length = 10,
    this.width = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'height': height,
      'weight': weight,
      'length': length,
      'width': width,
    };
  }
}
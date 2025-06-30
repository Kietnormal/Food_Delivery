// services/cart_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/category_model.dart';

class CartService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Helper method để convert dữ liệu Firebase an toàn
  Map<String, dynamic> _safeConvertToMap(dynamic data) {
    if (data == null) return {};

    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  // Helper method để xử lý dữ liệu items từ Firebase (có thể là Map hoặc List)
  Map<String, dynamic> _processFirebaseItems(dynamic itemsData) {
    if (itemsData == null) return {};

    Map<String, dynamic> processedItems = {};

    if (itemsData is Map<dynamic, dynamic>) {
      // Xử lý như Map
      for (var entry in itemsData.entries) {
        if (entry.value != null) {
          final itemData = _safeConvertToMap(entry.value);
          processedItems[entry.key.toString()] = {
            'foodId': itemData['foodId']?.toString() ?? entry.key.toString(),
            'quantity': itemData['quantity'] is int ? itemData['quantity'] : 1,
            'price': itemData['price'] is num ? itemData['price'] : 0.0,
            'addedAt': itemData['addedAt']?.toString() ?? DateTime.now().toIso8601String(),
          };
        }
      }
    } else if (itemsData is List) {
      // Xử lý như List (bỏ qua null items)
      for (int i = 0; i < itemsData.length; i++) {
        final item = itemsData[i];
        if (item != null && item is Map) {
          final itemData = _safeConvertToMap(item);
          final itemId = itemData['foodId']?.toString() ?? i.toString();

          processedItems[itemId] = {
            'foodId': itemId,
            'quantity': itemData['quantity'] is int ? itemData['quantity'] : 1,
            'price': itemData['price'] is num ? itemData['price'] : 0.0,
            'addedAt': itemData['addedAt']?.toString() ?? DateTime.now().toIso8601String(),
          };
        }
      }
    }

    return processedItems;
  }

  // Thêm món vào giỏ hàng
  Future<void> addToCart(String userId, FoodItem foodItem, {int quantity = 1}) async {
    try {
      final cartRef = _database.child('carts').child(userId);
      final snapshot = await cartRef.get();

      Map<String, dynamic> cartData = {};
      if (snapshot.exists && snapshot.value != null) {
        cartData = _safeConvertToMap(snapshot.value);
      }

      // Khởi tạo items nếu chưa có
      if (cartData['items'] == null) {
        cartData['items'] = {};
      }

      Map<String, dynamic> items = _processFirebaseItems(cartData['items']);

      // Kiểm tra món đã có trong giỏ hàng chưa
      if (items.containsKey(foodItem.id)) {
        // Tăng số lượng - Cast an toàn
        final currentItem = _safeConvertToMap(items[foodItem.id]);
        final currentQuantity = currentItem['quantity'] ?? 0;
        final newQuantity = (currentQuantity is int ? currentQuantity : 0) + quantity;

        items[foodItem.id] = {
          'foodId': foodItem.id,
          'quantity': newQuantity,
          'price': foodItem.price,
          'addedAt': currentItem['addedAt'] ?? DateTime.now().toIso8601String(),
        };
      } else {
        // Thêm món mới
        items[foodItem.id] = {
          'foodId': foodItem.id,
          'quantity': quantity,
          'price': foodItem.price,
          'addedAt': DateTime.now().toIso8601String(),
        };
      }

      // Cập nhật giỏ hàng
      await cartRef.set({
        'userId': userId,
        'items': items,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('CartService - Added ${foodItem.name} to cart');
    } catch (e) {
      print('CartService - Error adding to cart: $e');
      throw Exception('Không thể thêm vào giỏ hàng: $e');
    }
  }

  // Lấy giỏ hàng của user
  Future<Cart?> getCart(String userId) async {
    try {
      final snapshot = await _database.child('carts').child(userId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = _safeConvertToMap(snapshot.value);

        // Xử lý items với helper method
        Map<String, dynamic> cleanItems = {};
        if (data['items'] != null) {
          cleanItems = _processFirebaseItems(data['items']);
        }

        final cleanData = {
          'userId': userId,
          'items': cleanItems,
          'updatedAt': data['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
        };

        return Cart.fromJson(userId, cleanData);
      }

      // Trả về giỏ hàng rỗng nếu chưa có
      return Cart(
        userId: userId,
        items: {},
        updatedAt: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('CartService - Error getting cart: $e');
      print('CartService - Stack trace: ${StackTrace.current}');
      throw Exception('Không thể tải giỏ hàng: $e');
    }
  }

  // Cập nhật số lượng món trong giỏ hàng
  Future<void> updateQuantity(String userId, String foodId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeFromCart(userId, foodId);
        return;
      }

      await _database
          .child('carts')
          .child(userId)
          .child('items')
          .child(foodId)
          .child('quantity')
          .set(newQuantity);

      await _database
          .child('carts')
          .child(userId)
          .child('updatedAt')
          .set(DateTime.now().toIso8601String());

      print('CartService - Updated quantity for $foodId to $newQuantity');
    } catch (e) {
      print('CartService - Error updating quantity: $e');
      throw Exception('Không thể cập nhật số lượng: $e');
    }
  }

  // Xóa món khỏi giỏ hàng
  Future<void> removeFromCart(String userId, String foodId) async {
    try {
      await _database
          .child('carts')
          .child(userId)
          .child('items')
          .child(foodId)
          .remove();

      await _database
          .child('carts')
          .child(userId)
          .child('updatedAt')
          .set(DateTime.now().toIso8601String());

      print('CartService - Removed $foodId from cart');
    } catch (e) {
      print('CartService - Error removing from cart: $e');
      throw Exception('Không thể xóa khỏi giỏ hàng: $e');
    }
  }

  // Xóa toàn bộ giỏ hàng
  Future<void> clearCart(String userId) async {
    try {
      await _database.child('carts').child(userId).remove();
      print('CartService - Cart cleared for user $userId');
    } catch (e) {
      print('CartService - Error clearing cart: $e');
      throw Exception('Không thể xóa giỏ hàng: $e');
    }
  }

  // Lắng nghe thay đổi giỏ hàng realtime
  Stream<Cart> watchCart(String userId) async* {
    await for (final snapshot in _database.child('carts').child(userId).onValue) {
      try {
        if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
          final data = _safeConvertToMap(snapshot.snapshot.value);

          // Xử lý items với helper method
          Map<String, dynamic> cleanItems = {};
          if (data['items'] != null) {
            cleanItems = _processFirebaseItems(data['items']);
          }

          final cleanData = {
            'userId': userId,
            'items': cleanItems,
            'updatedAt': data['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          };

          yield Cart.fromJson(userId, cleanData);
        } else {
          yield Cart(
            userId: userId,
            items: {},
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
      } catch (e) {
        print('CartService - Error in watchCart stream: $e');
        yield Cart(
          userId: userId,
          items: {},
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
    }
  }
}
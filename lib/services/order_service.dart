// services/order_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/cart_model.dart';
import '../services/food_service.dart';

class OrderService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FoodService _foodService = FoodService();

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

  // Helper method để xử lý dữ liệu orders từ Firebase (có thể là Map hoặc List)
  List<Order> _processFirebaseOrders(dynamic ordersData) {
    if (ordersData == null) return [];

    List<Order> processedOrders = [];

    if (ordersData is Map<dynamic, dynamic>) {
      // Xử lý như Map
      for (var entry in ordersData.entries) {
        if (entry.value != null) {
          try {
            final orderData = _safeConvertToMap(entry.value);
            final order = Order.fromJson(entry.key.toString(), orderData);
            processedOrders.add(order);
          } catch (e) {
            print('OrderService - Error processing Map order ${entry.key}: $e');
          }
        }
      }
    } else if (ordersData is List) {
      // Xử lý như List (bỏ qua null items)
      for (int i = 0; i < ordersData.length; i++) {
        final orderData = ordersData[i];
        if (orderData != null && orderData is Map) {
          try {
            final orderMap = _safeConvertToMap(orderData);
            // Sử dụng id từ data hoặc index làm id
            final orderId = orderMap['id']?.toString() ?? i.toString();
            final order = Order.fromJson(orderId, orderMap);
            processedOrders.add(order);
          } catch (e) {
            print('OrderService - Error processing List order $i: $e');
          }
        }
      }
    }

    return processedOrders;
  }

  // Tạo đơn hàng mới từ giỏ hàng
  Future<String> createOrder({
    required String userId,
    required Cart cart,
    required String deliveryAddress,
    required String phone,
    required int deliveryFee,
    String? notes,
  }) async {
    try {
      if (cart.items.isEmpty) {
        throw Exception('Giỏ hàng trống');
      }

      print('OrderService - Creating order for user: $userId');

      // Tạo order ID mới
      final orderRef = _database.child('orders').push();
      final orderId = orderRef.key!;

      // Lấy thông tin món ăn để có tên đầy đủ
      List<dynamic> allFoodItems = [];
      Map<String, String> foodItemsMap = {}; // foodId -> foodName

      try {
        allFoodItems = await _foodService.getFoodItems();
        for (var food in allFoodItems) {
          foodItemsMap[food.id] = food.name;
        }
        print('OrderService - Loaded ${foodItemsMap.length} food items for naming');
      } catch (e) {
        print('OrderService - Warning: Could not load food items for naming: $e');
        // Tiếp tục tạo đơn hàng mà không có tên món ăn
      }

      // Tính toán tổng tiền
      int subtotal = 0;
      List<Map<String, dynamic>> orderItems = [];

      for (var cartItem in cart.items.values) {
        final itemTotal = cartItem.price * cartItem.quantity;
        subtotal += itemTotal;

        orderItems.add({
          'foodId': cartItem.foodId,
          'foodName': foodItemsMap[cartItem.foodId] ?? 'Món ăn #${cartItem.foodId}',
          'quantity': cartItem.quantity,
          'price': cartItem.price,
          'total': itemTotal,
        });
      }

      final total = subtotal + deliveryFee;

      // Tạo order data
      final orderData = {
        'id': orderId,
        'userId': userId,
        'items': orderItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': OrderStatus.pending.value,
        'deliveryAddress': deliveryAddress,
        'phone': phone,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      print('OrderService - Attempting to save order: $orderId');

      try {
        // Lưu order vào Firebase
        await orderRef.set(orderData);
        print('OrderService - Created order $orderId with total: $total');
        return orderId;
      } catch (firebaseError) {
        print('OrderService - Firebase write error: $firebaseError');

        // Kiểm tra nếu là lỗi permission
        if (firebaseError.toString().contains('PERMISSION_DENIED') ||
            firebaseError.toString().contains('Index not defined')) {
          throw Exception('Lỗi quyền truy cập Firebase. Vui lòng kiểm tra Database Rules.');
        }

        throw Exception('Lỗi lưu đơn hàng: $firebaseError');
      }
    } catch (e) {
      print('OrderService - Error creating order: $e');
      throw Exception('Không thể tạo đơn hàng: $e');
    }
  }

  // Lấy đơn hàng theo ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      print('OrderService - Getting order by ID: $orderId');

      final snapshot = await _database.child('orders').child(orderId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = _safeConvertToMap(snapshot.value);
        return Order.fromJson(orderId, data);
      }

      print('OrderService - Order not found: $orderId');
      return null;
    } catch (e) {
      print('OrderService - Error getting order by id: $e');

      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Không có quyền truy cập đơn hàng');
      }

      throw Exception('Không thể lấy thông tin đơn hàng: $e');
    }
  }

  // Lấy tất cả đơn hàng của user
  Future<List<Order>> getUserOrders(String userId, {bool forceRefresh = false}) async {
    try {
      print('OrderService - Getting orders for user: $userId');

      // Thử truy cập trực tiếp trước
      try {
        final snapshot = await _database
            .child('orders')
            .orderByChild('userId')
            .equalTo(userId)
            .get();

        if (snapshot.exists && snapshot.value != null) {
          final ordersData = snapshot.value;
          final orders = _processFirebaseOrders(ordersData);

          // Sắp xếp theo thời gian tạo (mới nhất trước)
          orders.sort((a, b) {
            final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.now();
            final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          print('OrderService - Found ${orders.length} orders for user $userId');
          return orders;
        }

        print('OrderService - No orders found for user $userId');
        return [];
      } catch (queryError) {
        print('OrderService - Query error: $queryError');

        // Nếu lỗi do index, thử lấy tất cả và filter
        if (queryError.toString().contains('Index not defined')) {
          print('OrderService - Index not defined, trying to get all orders and filter');
          return await _getAllOrdersAndFilter(userId);
        }

        throw queryError;
      }
    } catch (e) {
      print('OrderService - Error getting user orders: $e');

      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Không có quyền truy cập danh sách đơn hàng');
      }

      throw Exception('Không thể tải danh sách đơn hàng: $e');
    }
  }

  // Phương thức backup: lấy tất cả đơn hàng và filter theo userId
  Future<List<Order>> _getAllOrdersAndFilter(String userId) async {
    try {
      print('OrderService - Getting all orders and filtering by userId: $userId');

      final snapshot = await _database.child('orders').get();

      if (snapshot.exists && snapshot.value != null) {
        final ordersData = snapshot.value;
        final allOrders = _processFirebaseOrders(ordersData);

        // Filter theo userId
        final userOrders = allOrders.where((order) => order.userId == userId).toList();

        // Sắp xếp theo thời gian tạo (mới nhất trước)
        userOrders.sort((a, b) {
          final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.now();
          final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        print('OrderService - Found ${userOrders.length} orders for user $userId (filtered from ${allOrders.length} total)');
        return userOrders;
      }

      return [];
    } catch (e) {
      print('OrderService - Error in _getAllOrdersAndFilter: $e');
      throw e;
    }
  }

  // Lấy tất cả đơn hàng (cho admin)
  Future<List<Order>> getAllOrders({bool forceRefresh = false}) async {
    try {
      print('OrderService - Getting all orders');

      final snapshot = await _database.child('orders').get();

      if (snapshot.exists && snapshot.value != null) {
        final ordersData = snapshot.value;
        final orders = _processFirebaseOrders(ordersData);

        // Sắp xếp theo thời gian tạo (mới nhất trước)
        orders.sort((a, b) {
          final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.now();
          final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        print('OrderService - Found ${orders.length} total orders');
        return orders;
      }

      print('OrderService - No orders found');
      return [];
    } catch (e) {
      print('OrderService - Error getting all orders: $e');

      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Không có quyền truy cập tất cả đơn hàng');
      }

      throw Exception('Không thể tải danh sách đơn hàng: $e');
    }
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      print('OrderService - Updating order $orderId status to ${newStatus.value}');

      await _database
          .child('orders')
          .child(orderId)
          .child('status')
          .set(newStatus.value);

      await _database
          .child('orders')
          .child(orderId)
          .child('updatedAt')
          .set(DateTime.now().toIso8601String());

      print('OrderService - Updated order $orderId status to ${newStatus.value}');
    } catch (e) {
      print('OrderService - Error updating order status: $e');

      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Không có quyền cập nhật trạng thái đơn hàng');
      }

      throw Exception('Không thể cập nhật trạng thái đơn hàng: $e');
    }
  }

  // Hủy đơn hàng
  Future<void> cancelOrder(String orderId) async {
    try {
      print('OrderService - Cancelling order: $orderId');

      // Kiểm tra đơn hàng có thể hủy không
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Không tìm thấy đơn hàng');
      }

      if (!order.canCancel) {
        throw Exception('Đơn hàng không thể hủy ở trạng thái hiện tại');
      }

      await updateOrderStatus(orderId, OrderStatus.cancelled);
      print('OrderService - Cancelled order $orderId');
    } catch (e) {
      print('OrderService - Error cancelling order: $e');
      throw Exception('Không thể hủy đơn hàng: $e');
    }
  }

  // Lấy đơn hàng theo trạng thái
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      print('OrderService - Getting orders by status: ${status.value}');

      try {
        final snapshot = await _database
            .child('orders')
            .orderByChild('status')
            .equalTo(status.value)
            .get();

        if (snapshot.exists && snapshot.value != null) {
          final ordersData = snapshot.value;
          final orders = _processFirebaseOrders(ordersData);

          // Sắp xếp theo thời gian tạo
          orders.sort((a, b) {
            final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.now();
            final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          return orders;
        }

        return [];
      } catch (queryError) {
        if (queryError.toString().contains('Index not defined')) {
          // Fallback: lấy tất cả và filter
          print('OrderService - Index not defined for status query, using fallback');
          final allOrders = await getAllOrders();
          return allOrders.where((order) => order.status == status).toList();
        }
        throw queryError;
      }
    } catch (e) {
      print('OrderService - Error getting orders by status: $e');
      throw Exception('Không thể tải đơn hàng theo trạng thái: $e');
    }
  }

  // Lắng nghe thay đổi đơn hàng realtime
  Stream<List<Order>> watchUserOrders(String userId) async* {
    try {
      await for (final snapshot in _database
          .child('orders')
          .orderByChild('userId')
          .equalTo(userId)
          .onValue) {
        try {
          if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
            final ordersData = snapshot.snapshot.value;
            final orders = _processFirebaseOrders(ordersData);

            // Sắp xếp theo thời gian tạo (mới nhất trước)
            orders.sort((a, b) {
              final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.now();
              final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.now();
              return bTime.compareTo(aTime);
            });

            yield orders;
          } else {
            yield [];
          }
        } catch (e) {
          print('OrderService - Error in watchUserOrders stream: $e');
          yield [];
        }
      }
    } catch (e) {
      print('OrderService - Error setting up watchUserOrders stream: $e');
      yield [];
    }
  }

  // Lắng nghe một đơn hàng cụ thể
  Stream<Order?> watchOrder(String orderId) async* {
    try {
      await for (final snapshot in _database.child('orders').child(orderId).onValue) {
        try {
          if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
            final data = _safeConvertToMap(snapshot.snapshot.value);
            yield Order.fromJson(orderId, data);
          } else {
            yield null;
          }
        } catch (e) {
          print('OrderService - Error in watchOrder stream: $e');
          yield null;
        }
      }
    } catch (e) {
      print('OrderService - Error setting up watchOrder stream: $e');
      yield null;
    }
  }

  // Thống kê đơn hàng theo trạng thái
  Future<Map<OrderStatus, int>> getOrderStatistics() async {
    try {
      final allOrders = await getAllOrders();

      Map<OrderStatus, int> statistics = {};
      for (OrderStatus status in OrderStatus.values) {
        statistics[status] = 0;
      }

      for (var order in allOrders) {
        statistics[order.status] = (statistics[order.status] ?? 0) + 1;
      }

      return statistics;
    } catch (e) {
      print('OrderService - Error getting order statistics: $e');
      return {};
    }
  }

  // Test connection to Firebase
  Future<bool> testFirebaseConnection() async {
    try {
      print('OrderService - Testing Firebase connection...');

      final testRef = _database.child('test');
      await testRef.set({'timestamp': DateTime.now().toIso8601String()});
      await testRef.remove();

      print('OrderService - Firebase connection test successful');
      return true;
    } catch (e) {
      print('OrderService - Firebase connection test failed: $e');
      return false;
    }
  }
}
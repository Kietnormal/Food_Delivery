import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/food_service.dart';
import '../models/order_model.dart';
import '../models/category_model.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final FoodService _foodService = FoodService();

  int selectedTab = 0; // 0: Đang giao, 1: Đã hoàn tất
  List<Order> currentOrders = [];
  List<Order> completedOrders = [];
  Map<String, FoodItem> foodItems = {}; // Cache food items để hiển thị thông tin
  bool isLoading = true;
  String? errorMessage;

  // Lấy user ID từ AuthService
  String? get currentUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Khởi tạo AuthService nếu chưa
      if (!_authService.isInitialized) {
        await _authService.initialize();
      }

      // Kiểm tra user đã đăng nhập chưa
      if (!_authService.isLoggedIn || currentUserId == null) {
        setState(() {
          errorMessage = 'Vui lòng đăng nhập để xem đơn hàng';
          isLoading = false;
        });
        return;
      }

      await _loadOrders();
    } catch (e) {
      print('OrderScreen - Initialize error: $e');
      setState(() {
        errorMessage = 'Lỗi khởi tạo: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    try {
      print('OrderScreen - Loading orders for user: $currentUserId');

      // Load đơn hàng và thông tin món ăn
      final results = await Future.wait([
        _orderService.getUserOrders(currentUserId!),
        _foodService.getFoodItems(),
      ]);

      final allOrders = results[0] as List<Order>;
      final allFoodItems = results[1] as List<FoodItem>;

      // Tạo map để dễ truy cập food item theo ID
      foodItems = {};
      for (var food in allFoodItems) {
        foodItems[food.id] = food;
      }

      // Phân loại đơn hàng theo trạng thái
      setState(() {
        currentOrders = allOrders.where((order) =>
        order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.delivering
        ).toList();

        completedOrders = allOrders.where((order) =>
        order.status == OrderStatus.completed ||
            order.status == OrderStatus.cancelled
        ).toList();

        isLoading = false;
      });

      print('OrderScreen - Loaded ${currentOrders.length} current orders and ${completedOrders.length} completed orders');
    } catch (e) {
      print('OrderScreen - Error loading orders: $e');
      setState(() {
        errorMessage = 'Không thể tải đơn hàng: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  Future<void> _cancelOrder(Order order) async {
    // Hiển thị dialog xác nhận
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy đơn hàng'),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    try {
      // Hiển thị loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Đang hủy đơn hàng...'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );

      await _orderService.cancelOrder(order.id);

      // Refresh danh sách
      await _refreshOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Đã hủy đơn hàng thành công'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi hủy đơn hàng: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Toggle buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTab == 0 ? Color(0xFF5DADE2) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Đang giao (${currentOrders.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTab == 0 ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTab == 1 ? Color(0xFF5DADE2) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Đã hoàn tất (${completedOrders.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTab == 1 ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF5DADE2)),
            SizedBox(height: 16),
            Text('Đang tải đơn hàng...'),
          ],
        ),
      );
    }

    // Error state
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeAndLoadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
                foregroundColor: Colors.white,
              ),
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Orders list
    final orders = selectedTab == 0 ? currentOrders : completedOrders;

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selectedTab == 0 ? Icons.delivery_dining : Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            selectedTab == 0 ? 'Không có đơn hàng đang giao' : 'Không có đơn hàng đã hoàn tất',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            selectedTab == 0
                ? 'Các đơn hàng mới sẽ hiển thị ở đây'
                : 'Lịch sử đơn hàng sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header với thông tin đơn hàng
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng #${order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDateTime(DateTime.parse(order.createdAt)),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thông tin chi tiết
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Danh sách món ăn
                ...order.items.take(2).map((orderItem) {
                  // Lấy thông tin món ăn từ foodItems cache
                  final foodItem = foodItems[orderItem.foodId];
                  final displayName = foodItem?.name ?? (orderItem.foodName.isNotEmpty
                      ? orderItem.foodName
                      : 'Món ăn #${orderItem.foodId}');

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: foodItem != null && foodItem.imageUrl.startsWith('http')
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                foodItem.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    _getFoodEmoji(foodItem.categoryId),
                                    style: TextStyle(fontSize: 16),
                                  );
                                },
                              ),
                            )
                                : Text(
                              foodItem != null
                                  ? _getFoodEmoji(foodItem.categoryId)
                                  : '🍽️',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'x${orderItem.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_formatPrice(orderItem.total)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5DADE2),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Hiển thị số món còn lại nếu có
                if (order.items.length > 2)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'và ${order.items.length - 2} món khác...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                Divider(color: Colors.grey[200]),

                // Tổng tiền và địa chỉ
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng tiền: ${_formatPrice(order.total)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5DADE2),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Giao đến: ${order.deliveryAddress}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order.phone.isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text(
                              'SĐT: ${order.phone}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Nút hành động
                    if (order.canCancel && selectedTab == 0)
                      TextButton(
                        onPressed: () => _cancelOrder(order),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Hủy đơn',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.delivering:
        return Colors.indigo;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getFoodEmoji(String categoryId) {
    // Map category IDs to emojis based on your Firebase data
    switch (categoryId) {
      case 'c1': // Pizza
        return '🍕';
      case 'c2': // Burger
        return '🍔';
      case 'c3': // Gà rán
        return '🍗';
      case 'c4': // Đồ uống
        return '🥤';
      default:
        return '🍽️';
    }
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hôm nay ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
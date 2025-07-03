import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/caculator_ship_model.dart';
import '../models/shipping_item_model.dart';
import '../services/cart_service.dart';
import '../services/food_service.dart';
import '../services/order_service.dart';
import '../services/ghn_service.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final FoodService _foodService = FoodService();
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();

  Cart? cart;
  Map<String, FoodItem> foodItems = {};
  bool isLoading = true;
  bool isLoadingShipping = false; // Thêm loading state cho shipping
  String? errorMessage;

  // Shipping variables
  int deliveryFee = 20000; // Default fee
  ShippingFeeResult? shippingResult;
  bool hasShippingError = false;

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
          errorMessage = 'Vui lòng đăng nhập để xem giỏ hàng';
          isLoading = false;
        });
        return;
      }

      await _loadCartData();
    } catch (e) {
      print('CartScreen - Initialize error: $e');
      setState(() {
        errorMessage = 'Lỗi khởi tạo: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadCartData() async {
    try {
      // Load giỏ hàng và thông tin món ăn
      final results = await Future.wait([
        _cartService.getCart(currentUserId!),
        _foodService.getFoodItems(),
      ]);

      cart = results[0] as Cart?;
      final allFoodItems = results[1] as List<FoodItem>;

      // Tạo map để dễ truy cập food item theo ID
      foodItems = {};
      for (var food in allFoodItems) {
        foodItems[food.id] = food;
      }

      print('CartScreen - Loaded cart with ${cart?.totalItems ?? 0} items');

      // Tính phí ship nếu có giỏ hàng và user có địa chỉ
      if (cart != null && !cart!.isEmpty) {
        await _calculateShippingFee();
      }
    } catch (e) {
      print('CartScreen - Error loading cart: $e');
      setState(() {
        errorMessage = 'Không thể tải giỏ hàng: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _calculateShippingFee() async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.districtId == null ||
        _authService.currentUser!.wardCode == null) {
      print('CartScreen - Missing address details for shipping calculation');
      setState(() {
        hasShippingError = true;
        deliveryFee = 20000; // fallback fee
      });
      return;
    }

    setState(() {
      isLoadingShipping = true;
      hasShippingError = false;
    });

    try {
      // Tạo danh sách items để tính shipping
      List<ShippingItem> shippingItems = [];
      int totalWeight = 0;

      cart!.items.forEach((foodId, cartItem) {
        final foodItem = foodItems[foodId];
        if (foodItem != null) {
          // Ước tính weight dựa trên category
          int itemWeight = _estimateWeight(foodItem.categoryId);
          totalWeight += itemWeight * cartItem.quantity;

          shippingItems.add(ShippingItem(
            name: foodItem.name,
            quantity: cartItem.quantity,
            weight: itemWeight,
            height: 10, // cm
            length: 15, // cm
            width: 15, // cm
          ));
        }
      });

      // Gọi API GHN để tính phí
      shippingResult = await GHNService.calculateShippingFee(
        toDistrictId: _authService.currentUser!.districtId!,
        toWardCode: _authService.currentUser!.wardCode!,
        weight: totalWeight,
        insuranceValue: cart!.totalPrice,
        items: shippingItems,
      );

      setState(() {
        deliveryFee = shippingResult!.total;
        isLoadingShipping = false;
      });

      print('CartScreen - Calculated shipping fee: ${deliveryFee}đ');
    } catch (e) {
      print('CartScreen - Error calculating shipping: $e');
      setState(() {
        hasShippingError = true;
        deliveryFee = 20000; // fallback fee
        isLoadingShipping = false;
      });
    }
  }

  // Ước tính weight dựa vào category (gram)
  int _estimateWeight(String categoryId) {
    switch (categoryId) {
      case 'c1': return 400; // Pizza
      case 'c2': return 300; // Burger
      case 'c3': return 250; // Chicken
      case 'c4': return 500; // Drinks
      default: return 200;
    }
  }

  Future<void> _updateQuantity(String foodId, int newQuantity) async {
    try {
      await _cartService.updateQuantity(currentUserId!, foodId, newQuantity);
      await _loadCartData(); // Reload để cập nhật UI và recalculate shipping
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật số lượng: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeItem(String foodId) async {
    try {
      await _cartService.removeFromCart(currentUserId!, foodId);
      await _loadCartData(); // Reload để cập nhật UI và recalculate shipping
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa món khỏi giỏ hàng'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa món: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: Container(),
        title: Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cart != null && !cart!.isEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey[600]),
              onPressed: _loadCartData,
              tooltip: 'Làm mới',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF5DADE2)),
            SizedBox(height: 16),
            Text('Đang tải giỏ hàng...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeAndLoadData,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5DADE2)),
              child: Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (cart == null || cart!.isEmpty) {
      return _buildEmptyCart();
    }

    return _buildCartContent();
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy thêm món ăn yêu thích vào giỏ hàng',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5DADE2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 20),
                SizedBox(width: 8),
                Text('Mua sắm ngay'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: cart!.items.length,
            itemBuilder: (context, index) {
              final cartItemEntry = cart!.items.entries.elementAt(index);
              final foodId = cartItemEntry.key;
              final cartItem = cartItemEntry.value;
              final foodItem = foodItems[foodId];

              if (foodItem == null) {
                return Container();
              }

              return _buildCartItem(foodItem, cartItem);
            },
          ),
        ),
        _buildCartSummary(),
      ],
    );
  }

  Widget _buildCartItem(FoodItem foodItem, CartItem cartItem) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Food image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: foodItem.imageUrl.startsWith('http')
                  ? Image.network(
                foodItem.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      _getFoodEmoji(foodItem.categoryId),
                      style: TextStyle(fontSize: 24),
                    ),
                  );
                },
              )
                  : Center(
                child: Text(
                  _getFoodEmoji(foodItem.categoryId),
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodItem.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (foodItem.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    foodItem.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  foodItem.formattedPrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5DADE2),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          // Quantity controls
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _updateQuantity(foodItem.id, cartItem.quantity - 1),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.remove, size: 16),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '${cartItem.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _updateQuantity(foodItem.id, cartItem.quantity + 1),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF5DADE2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => _removeItem(foodItem.id),
                child: Text(
                  'Xóa',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    if (cart == null || cart!.isEmpty) return Container();

    int totalAmount = cart!.totalPrice;
    int finalTotal = totalAmount + deliveryFee;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tạm tính:', style: TextStyle(fontSize: 16)),
              Text(_formatPrice(totalAmount), style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Phí giao hàng:', style: TextStyle(fontSize: 16)),
                  if (isLoadingShipping) ...[
                    SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  if (hasShippingError) ...[
                    SizedBox(width: 4),
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  ],
                ],
              ),
              Text(_formatPrice(deliveryFee), style: TextStyle(fontSize: 16)),
            ],
          ),
          if (hasShippingError) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sử dụng phí giao hàng ước tính',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatPrice(finalTotal),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5DADE2),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số món: ${cart!.totalItems}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '${cart!.items.length} loại',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoadingShipping ? null : () {
                _showCheckoutDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Đặt hàng • ${_formatPrice(finalTotal)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFoodEmoji(String categoryId) {
    switch (categoryId) {
      case 'c1': return '🍕';
      case 'c2': return '🍔';
      case 'c3': return '🍗';
      case 'c4': return '🥤';
      default: return '🍽️';
    }
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  void _showCheckoutDialog() {
    if (cart == null || cart!.isEmpty) return;

    final _addressController = TextEditingController();
    final _phoneController = TextEditingController();
    final _notesController = TextEditingController();

    // Pre-fill user info if available
    if (_authService.currentUser != null) {
      _addressController.text = _authService.currentUser!.address;
      _phoneController.text = _authService.currentUser!.phone;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thông tin giao hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ giao hàng *',
                    hintText: 'Nhập địa chỉ nhận hàng',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại *',
                    hintText: 'Nhập số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'Ghi chú thêm cho đơn hàng',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Số món:'),
                          Text('${cart!.totalItems}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tạm tính:'),
                          Text(_formatPrice(cart!.totalPrice)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Phí giao hàng:'),
                              if (hasShippingError) ...[
                                SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 12, color: Colors.orange),
                              ],
                            ],
                          ),
                          Text(_formatPrice(deliveryFee)),
                        ],
                      ),
                      if (shippingResult != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Phí ship được tính theo API GHN',
                          style: TextStyle(fontSize: 11, color: Colors.green),
                        ),
                      ],
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _formatPrice(cart!.totalPrice + deliveryFee),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5DADE2)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_addressController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vui lòng nhập đầy đủ địa chỉ và số điện thoại'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _processOrder(
                  deliveryAddress: _addressController.text.trim(),
                  phone: _phoneController.text.trim(),
                  notes: _notesController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
              ),
              child: Text('Đặt hàng', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processOrder({
    required String deliveryAddress,
    required String phone,
    String? notes,
  }) async {
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
              Text('Đang tạo đơn hàng...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      // Tạo đơn hàng thông qua OrderService với phí ship thực tế
      final orderId = await _orderService.createOrder(
        userId: currentUserId!,
        cart: cart!,
        deliveryAddress: deliveryAddress,
        phone: phone,
        deliveryFee: deliveryFee, // Truyền phí ship đã tính
        notes: notes,

      );

      // Xóa giỏ hàng sau khi đặt hàng thành công
      await _cartService.clearCart(currentUserId!);
      await _loadCartData(); // Reload để cập nhật UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Đặt hàng thành công! Mã đơn hàng: ${orderId.substring(0, 8)}'),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Xem đơn hàng',
            textColor: Colors.white,
            onPressed: () {
              // Chuyển sang tab đơn hàng
              // Bạn có thể implement navigation logic ở đây
            },
          ),
        ),
      );

      print('CartScreen - Order created successfully: $orderId');
    } catch (e) {
      print('CartScreen - Error creating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt hàng: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
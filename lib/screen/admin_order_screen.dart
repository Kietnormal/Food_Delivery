// screens/admin_order_management_screen.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedStatus != null) {
        _orders = await _orderService.getOrdersByStatus(_selectedStatus!);
      } else {
        _orders = await _orderService.getAllOrders();
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi tải đơn hàng: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      _showSuccessMessage('Cập nhật trạng thái thành công');
      _loadOrders();
    } catch (e) {
      _showErrorSnackBar('Lỗi cập nhật: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đơn hàng'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text('Lọc theo trạng thái: '),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<OrderStatus?>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<OrderStatus?>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...OrderStatus.values.map((status) =>
                          DropdownMenuItem<OrderStatus?>(
                            value: status,
                            child: Text(status.displayName),
                          ),
                      ),
                    ],
                    onChanged: (status) {
                      setState(() => _selectedStatus = status);
                      _loadOrders();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không có đơn hàng nào'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: 8),

            // Order Info
            Text('Địa chỉ: ${order.deliveryAddress}'),
            Text('Số điện thoại: ${order.phone}'),
            Text('Tổng tiền: ${_formatPrice(order.total)}'),
            Text('Thời gian: ${_formatDateTime(order.createdAt)}'),

            // Order Items
            SizedBox(height: 8),
            Text(
              'Món ăn (${order.itemCount} món):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            ...order.items.map((item) => Padding(
              padding: EdgeInsets.only(left: 16, top: 4),
              child: Text('• ${item.foodName} x${item.quantity}'),
            )),

            // Action Buttons
            if (order.status != OrderStatus.completed &&
                order.status != OrderStatus.cancelled)
              SizedBox(height: 12),
            if (order.status != OrderStatus.completed &&
                order.status != OrderStatus.cancelled)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == OrderStatus.pending)
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(order.id, OrderStatus.confirmed),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Xác nhận', style: TextStyle(color: Colors.white)),
                    ),
                  if (order.status == OrderStatus.confirmed)
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(order.id, OrderStatus.preparing),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: Text('Chuẩn bị', style: TextStyle(color: Colors.white)),
                    ),
                  if (order.status == OrderStatus.preparing)
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(order.id, OrderStatus.delivering),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: Text('Giao hàng', style: TextStyle(color: Colors.white)),
                    ),
                  if (order.status == OrderStatus.delivering)
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(order.id, OrderStatus.completed),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: Text('Hoàn thành', style: TextStyle(color: Colors.white)),
                    ),
                  SizedBox(width: 8),
                  if (order.canCancel)
                    TextButton(
                      onPressed: () => _showCancelDialog(order),
                      child: Text('Hủy', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.delivering:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy đơn hàng'),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order.id, OrderStatus.cancelled);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hủy đơn hàng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
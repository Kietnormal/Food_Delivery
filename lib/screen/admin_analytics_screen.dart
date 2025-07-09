// screens/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  @override
  _AdminAnalyticsScreenState createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  Map<OrderStatus, int> _orderStatistics = {};
  List<Order> _recentOrders = [];
  int _totalRevenue = 0;
  int _todayOrders = 0;
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Load order statistics
      final statistics = await _orderService.getOrderStatistics();
      final allOrders = await _orderService.getAllOrders();

      // Calculate metrics
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayOrders = allOrders.where((order) {
        final orderDate = DateTime.tryParse(order.createdAt);
        if (orderDate == null) return false;
        final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
        return orderDay.isAtSameMomentAs(today);
      }).length;

      final completedOrders = allOrders.where((order) =>
      order.status == OrderStatus.completed).length;

      final totalRevenue = allOrders
          .where((order) => order.status == OrderStatus.completed)
          .fold(0, (sum, order) => sum + order.total);

      setState(() {
        _orderStatistics = statistics;
        _recentOrders = allOrders.take(10).toList();
        _totalRevenue = totalRevenue;
        _todayOrders = todayOrders;
        _completedOrders = completedOrders;
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi tải thống kê: $e');
    } finally {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê doanh thu'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewCards(),
            SizedBox(height: 24),

            // Order Status Chart
            _buildOrderStatusSection(),
            SizedBox(height: 24),

            // Recent Orders
            _buildRecentOrdersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng doanh thu',
                value: _formatPrice(_totalRevenue),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Đơn hôm nay',
                value: _todayOrders.toString(),
                icon: Icons.today,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Đơn hoàn thành',
                value: _completedOrders.toString(),
                icon: Icons.check_circle,
                color: Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng đơn hàng',
                value: _orderStatistics.values.fold(0, (a, b) => a + b).toString(),
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái đơn hàng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Simple Bar Chart
              Container(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: OrderStatus.values.map((status) {
                    final count = _orderStatistics[status] ?? 0;
                    final maxCount = _orderStatistics.values.isEmpty
                        ? 1
                        : _orderStatistics.values.reduce((a, b) => a > b ? a : b);
                    final height = maxCount == 0 ? 0.0 : (count / maxCount) * 100;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: height,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 50,
                          child: Text(
                            _getStatusShortName(status),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16),
              // Status List
              ...OrderStatus.values.map((status) {
                final count = _orderStatistics[status] ?? 0;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text(status.displayName)),
                      Text(
                        count.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đơn hàng gần đây',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: _recentOrders.isEmpty
              ? Container(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Chưa có đơn hàng nào'),
                ],
              ),
            ),
          )
              : Column(
            children: _recentOrders.map((order) {
              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt,
                    color: _getStatusColor(order.status),
                    size: 20,
                  ),
                ),
                title: Text('#${order.id.substring(0, 8)}'),
                subtitle: Text(_formatDateTime(order.createdAt)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(order.total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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

  String _getStatusShortName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ';
      case OrderStatus.confirmed:
        return 'Xác nhận';
      case OrderStatus.preparing:
        return 'Chuẩn bị';
      case OrderStatus.delivering:
        return 'Giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Hủy';
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
}
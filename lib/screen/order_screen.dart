import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int selectedTab = 0; // 0: Đang giao, 1: Đã hoàn tất

  List<Map<String, dynamic>> mockOrders = [
    {
      'id': '12345678',
      'status': 'delivering',
      'createdAt': DateTime.now().subtract(Duration(hours: 2)),
      'items': [
        {'name': 'Pizza Phô Mai', 'quantity': 1, 'total': 120000},
        {'name': 'Nước Cam', 'quantity': 2, 'total': 40000}
      ],
      'total': 160000,
      'address': '123 Lý Thường Kiệt, Q.10',
      'phone': '0909123456',
    },
    {
      'id': '87654321',
      'status': 'completed',
      'createdAt': DateTime.now().subtract(Duration(days: 1)),
      'items': [
        {'name': 'Burger Bò', 'quantity': 2, 'total': 180000},
      ],
      'total': 180000,
      'address': '456 Nguyễn Trãi, Q.5',
      'phone': '0987654321',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentOrders = mockOrders.where((o) => o['status'] == 'delivering').toList();
    final completedOrders = mockOrders.where((o) => o['status'] == 'completed').toList();
    final displayOrders = selectedTab == 0 ? currentOrders : completedOrders;

    return Scaffold(
      appBar: AppBar(title: Text('Đơn hàng của tôi')),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(16),
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

          // List of orders
          Expanded(
            child: displayOrders.isEmpty
                ? Center(
              child: Text(
                selectedTab == 0
                    ? 'Không có đơn hàng đang giao'
                    : 'Không có đơn hàng đã hoàn tất',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: displayOrders.length,
              itemBuilder: (context, index) {
                final order = displayOrders[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng #${order['id']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(_formatDate(order['createdAt'])),
                        Divider(height: 20),
                        ...List.generate(order['items'].length, (i) {
                          final item = order['items'][i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text('${item['name']} x${item['quantity']}')),
                                Text(_formatPrice(item['total'])),
                              ],
                            ),
                          );
                        }),
                        Divider(height: 20),
                        Text('Tổng tiền: ${_formatPrice(order['total'])}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5DADE2))),
                        SizedBox(height: 4),
                        Text('Giao đến: ${order['address']}'),
                        Text('SĐT: ${order['phone']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Hôm nay ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

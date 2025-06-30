import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems = [
    {
      'id': 'f1',
      'name': 'Pizza Hải Sản',
      'description': 'Pizza phủ hải sản tươi ngon',
      'imageUrl': '',
      'categoryId': 'c1',
      'price': 120000,
      'quantity': 2,
    },
    {
      'id': 'f2',
      'name': 'Gà Rán Giòn',
      'description': 'Gà rán giòn tan, thấm vị',
      'imageUrl': '',
      'categoryId': 'c3',
      'price': 80000,
      'quantity': 1,
    },
  ];

  final int deliveryFee = 20000;

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
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

  @override
  Widget build(BuildContext context) {
    int subtotal = cartItems.fold(0, (sum, item) =>
    sum + ((item['price'] as num).toInt() * (item['quantity'] as num).toInt()));
    int total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Giỏ hàng',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var item = cartItems[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _getFoodEmoji(item['categoryId']),
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text(item['description'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            SizedBox(height: 8),
                            Text(_formatPrice(item['price']), style: TextStyle(color: Color(0xFF5DADE2))),
                          ],
                        ),
                      ),
                      // Quantity
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.remove, size: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${item['quantity']}'),
                              ),
                              Icon(Icons.add, size: 16, color: Color(0xFF5DADE2)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          // Cart Summary
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Tạm tính:'), Text(_formatPrice(subtotal))],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Phí giao hàng:'), Text(_formatPrice(deliveryFee))],
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _formatPrice(total),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5DADE2)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // show checkout
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Thông tin giao hàng'),
                          content: Text('Hiển thị form nhập địa chỉ và số điện thoại...'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Đặt hàng', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5DADE2)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5DADE2),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Đặt hàng • ${_formatPrice(total)}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  String selectedCategoryId = 'c1';
  String searchQuery = '';
  bool isSearching = false;

  final List<Map<String, String>> categories = [
    {'id': 'c1', 'name': 'Pizza'},
    {'id': 'c2', 'name': 'Burger'},
    {'id': 'c3', 'name': 'Gà rán'},
    {'id': 'c4', 'name': 'Đồ uống'},
  ];

  final List<Map<String, dynamic>> foodItems = List.generate(
    6,
        (i) => {
      'id': 'f$i',
      'name': 'Món ăn $i',
      'description': 'Mô tả món ăn $i',
      'price': '₫${(i + 1) * 10000}',
      'image': '',
      'isAvailable': true,
      'isPopular': i % 2 == 0,
      'categoryId': i % 2 == 0 ? 'c1' : 'c2',
    },
  );

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> get displayedItems {
    var items = foodItems.where((e) => e['categoryId'] == selectedCategoryId).toList();
    if (isSearching && searchQuery.isNotEmpty) {
      items = items.where((e) => e['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              'Food Delivery',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            CircleAvatar(child: Icon(Icons.person, size: 18)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: 16),
            Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = cat['id'] == selectedCategoryId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(cat['name']!),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategoryId = cat['id']!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Kết quả: ${displayedItems.length} món',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: displayedItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final item = displayedItems[index];
                  return _buildFoodCard(item);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Giỏ hàng'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm món ăn...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  isSearching = false;
                  searchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(child: Icon(Icons.fastfood, size: 50)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(item['description'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['price'], style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, size: 16, color: Colors.white),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

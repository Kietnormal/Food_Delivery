// HomeScreen.dart - Updated with Firebase Integration
import 'profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/food_service.dart';
import '../models/category_model.dart';
import 'order_screen.dart';
import 'cart_screen.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  // Firebase data
  final FoodService _foodService = FoodService();
  List<Category> categories = [];
  List<FoodItem> allFoodItems = [];
  List<FoodItem> displayedFoodItems = [];

  String selectedCategoryId = '';
  bool isLoading = true;
  String? errorMessage;
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  // Search functionality
  String searchQuery = '';
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? get currentUserId => _authService.currentUser?.id;
  @override
  void initState() {
    super.initState();
    print('HomeScreen - initState called');
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('HomeScreen - Loading data from Firebase...');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load categories and food items from Firebase
      final results = await Future.wait([
        _foodService.getCategories(),
        _foodService.getFoodItems(),
      ]);

      categories = results[0] as List<Category>;
      allFoodItems = results[1] as List<FoodItem>;

      print('HomeScreen - Loaded ${categories.length} categories and ${allFoodItems.length} food items');

      // Set initial category selection
      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first.id;
        _filterByCategory(selectedCategoryId);
      } else {
        displayedFoodItems = List.from(allFoodItems);
      }

    } catch (e) {
      print('HomeScreen - Error loading data: $e');
      setState(() {
        errorMessage = 'Không thể tải dữ liệu: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterByCategory(String categoryId) {
    print('HomeScreen - Filtering by category: $categoryId');
    setState(() {
      selectedCategoryId = categoryId;
      isSearching = false;
      searchQuery = '';
    });

    // Clear search without triggering listener
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);

    setState(() {
      displayedFoodItems = allFoodItems
          .where((item) => item.categoryId == categoryId && item.isAvailable)
          .toList();
    });
  }

  // Search functionality
  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != searchQuery) {
      setState(() {
        searchQuery = query;
        isSearching = query.isNotEmpty;
      });
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    print('HomeScreen - Performing search: "$query"');

    if (query.trim().isEmpty) {
      // If search is empty, show category filter or all items
      if (selectedCategoryId.isNotEmpty) {
        _filterByCategory(selectedCategoryId);
      } else {
        setState(() {
          displayedFoodItems = List.from(allFoodItems);
        });
      }
      return;
    }

    try {
      final searchResults = await _foodService.searchFoodItems(query);
      print('HomeScreen - Search results: ${searchResults.length} items');

      setState(() {
        displayedFoodItems = searchResults;
      });
    } catch (e) {
      print('HomeScreen - Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(),
        title: Row(
          children: [
            Text(
              'Food Delivery',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, color: Colors.grey[600], size: 20),
              ),
            ),
          ],
        ),
      ),
      body: _buildCurrentContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF5DADE2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              currentIndex == 0 ? Icons.home : Icons.home_outlined,
              size: 24,
            ),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  currentIndex == 1 ? Icons.receipt_long : Icons.receipt_long_outlined,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  currentIndex == 2 ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Giỏ hàng',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _searchFocusNode.hasFocus ? Color(0xFF5DADE2) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Tìm món ăn...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (value) {
                _performSearch(value);
              },
              onChanged: (value) {
                setState(() {}); // Update UI
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
                setState(() {});
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 30, minHeight: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    String headerText;
    if (isSearching) {
      headerText = searchQuery.isEmpty
          ? 'Tất cả món ăn'
          : 'Kết quả cho "${searchQuery}"';
    } else if (selectedCategoryId.isEmpty) {
      headerText = 'Tất cả món ăn';
    } else {
      final category = categories.where((cat) => cat.id == selectedCategoryId).firstOrNull;
      headerText = category?.name ?? 'Món ăn';
    }

    return Row(
      children: [
        Text(
          headerText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Spacer(),
        Text(
          '${displayedFoodItems.length} món',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.restaurant_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            isSearching
                ? 'Không tìm thấy món ăn nào'
                : 'Không có món ăn nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            isSearching
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Vui lòng chọn danh mục khác',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (isSearching) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Xóa tìm kiếm'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return OrderScreen();
      case 2:
        return CartScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    // Loading state
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF5DADE2)),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
            SizedBox(height: 8),
            Text(
              'Vui lòng đợi trong giây lát',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Thử lại'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (categories.isEmpty && allFoodItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng kiểm tra kết nối Firebase',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Main content
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message with icon
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hãy đặt món ăn ưa thích của bạn!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // THAY THẾ search bar giả bằng search bar thực
            _buildSearchBar(), // Sử dụng method có sẵn thay vì tạo container giả
            SizedBox(height: 20),

            // Category section
            if (categories.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Colors.grey[700],
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Category buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: _buildCategoryButton(
                        category.id,
                        category.name,
                        _getCategoryEmoji(category.name),
                        selectedCategoryId == category.id,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Results header - sử dụng method có sẵn
            _buildResultsHeader(),
            SizedBox(height: 16),

            // Food items grid
            Expanded(
              child: displayedFoodItems.isEmpty
                  ? _buildEmptyState() // Sử dụng method có sẵn
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: displayedFoodItems.length,
                itemBuilder: (context, index) {
                  final item = displayedFoodItems[index];
                  return _buildFoodItemCard(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String id, String title, String emoji, bool isSelected) {
    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF5DADE2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF5DADE2) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(FoodItem item) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  // Food image
                  Center(
                    child: item.imageUrl.startsWith('http')
                        ? ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        item.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5DADE2),
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _getFoodEmoji(item.categoryId),
                              style: TextStyle(fontSize: 40),
                            ),
                          );
                        },
                      ),
                    )
                        : Center(
                      child: Text(
                        _getFoodEmoji(item.categoryId),
                        style: TextStyle(fontSize: 50),
                      ),
                    ),
                  ),

                  // Popular badge
                  if (item.isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Phổ biến',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Availability overlay
                  if (!item.isAvailable)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Food details
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.formattedPrice,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5DADE2),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: item.isAvailable ? () => _addToCart(item) : null,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.isAvailable
                              ? Color(0xFF5DADE2)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: item.isAvailable ? [
                            BoxShadow(
                              color: Color(0xFF5DADE2).withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
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

  String _getCategoryEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'pizza':
        return '🍕';
      case 'burger':
        return '🍔';
      case 'gà rán':
        return '🍗';
      case 'đồ uống':
        return '🥤';
      default:
        return '🍽️';
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

  String _getSelectedCategoryName() {
    if (selectedCategoryId.isEmpty) return 'Tất cả món ăn';

    final category = categories.where((cat) => cat.id == selectedCategoryId).firstOrNull;
    return category?.name ?? 'Món ăn';
  }

  Future<void> _addToCart(FoodItem item) async {
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
              Text('Đang thêm ${item.name}...'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );

      // Thêm vào giỏ hàng qua Firebase
      await _cartService.addToCart(currentUserId!, item);

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Đã thêm ${item.name} vào giỏ hàng'),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      print('HomeScreen - Successfully added ${item.name} to cart');
    } catch (e) {
      print('HomeScreen - Error adding to cart: $e');

      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Lỗi thêm vào giỏ hàng: ${e.toString()}'),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
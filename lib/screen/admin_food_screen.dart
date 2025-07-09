// screens/admin_food_management_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/food_service.dart';
import '../models/category_model.dart';

class AdminFoodManagementScreen extends StatefulWidget {
  @override
  _AdminFoodManagementScreenState createState() => _AdminFoodManagementScreenState();
}

class _AdminFoodManagementScreenState extends State<AdminFoodManagementScreen>
    with SingleTickerProviderStateMixin {
  final FoodService _foodService = FoodService();
  late TabController _tabController;

  List<Category> _categories = [];
  List<FoodItem> _foodItems = [];
  bool _isLoading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _foodService.getCategories(forceRefresh: true);
      final foodItems = await _foodService.getFoodItems(forceRefresh: true);

      setState(() {
        _categories = categories;
        _foodItems = foodItems;
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi tải dữ liệu: $e');
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
        title: Text('Quản lý món ăn'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Danh mục', icon: Icon(Icons.category)),
            Tab(text: 'Món ăn', icon: Icon(Icons.restaurant_menu)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildFoodItemsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có danh mục nào'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.isActive ? Colors.green : Colors.grey,
          child: Icon(Icons.category, color: Colors.white),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: category.isActive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.description),
            Text('Thứ tự: ${category.sortOrder}', style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditCategoryDialog(category);
            } else if (value == 'delete') {
              _showDeleteCategoryDialog(category);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Sửa'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemsTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text('Lọc theo danh mục: '),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    ..._categories.map((category) =>
                        DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ),
                  ],
                  onChanged: (categoryId) {
                    setState(() => _selectedCategoryId = categoryId);
                  },
                ),
              ),
            ],
          ),
        ),

        // Food Items List
        Expanded(
          child: _buildFilteredFoodItems(),
        ),
      ],
    );
  }

  Widget _buildFilteredFoodItems() {
    List<FoodItem> filteredItems = _foodItems;
    if (_selectedCategoryId != null) {
      filteredItems = _foodItems.where((item) => item.categoryId == _selectedCategoryId).toList();
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không có món ăn nào'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final foodItem = filteredItems[index];
        return _buildFoodItemCard(foodItem);
      },
    );
  }

  Widget _buildFoodItemCard(FoodItem foodItem) {
    final category = _categories.firstWhere(
          (cat) => cat.id == foodItem.categoryId,
      orElse: () => Category(
        id: '',
        name: 'Không xác định',
        imageUrl: '',
        description: '',
        isActive: true,
        sortOrder: 0,
      ),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: foodItem.imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  foodItem.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.restaurant, color: Colors.grey);
                  },
                ),
              )
                  : Icon(Icons.restaurant, color: Colors.grey),
            ),
            SizedBox(width: 12),

            // Food Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodItem.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: foodItem.isAvailable ? Colors.black : Colors.grey,
                    ),
                  ),
                  Text(
                    foodItem.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Danh mục: ${category.name}',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                  Text(
                    foodItem.formattedPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      if (foodItem.isPopular)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Phổ biến',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: foodItem.isAvailable ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          foodItem.isAvailable ? 'Có sẵn' : 'Hết hàng',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditFoodItemDialog(foodItem);
                } else if (value == 'delete') {
                  _showDeleteFoodItemDialog(foodItem);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== DIALOG METHODS ==========

  void _showAddDialog() {
    if (_tabController.index == 0) {
      _showAddCategoryDialog();
    } else {
      _showAddFoodItemDialog();
    }
  }

  // ========== CATEGORY DIALOGS ==========

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final sortOrderController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm danh mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên danh mục *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: sortOrderController,
                  decoration: InputDecoration(
                    labelText: 'Thứ tự sắp xếp',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Vui lòng nhập tên danh mục');
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  await _foodService.addCategory(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                  );

                  Navigator.pop(context);
                  _showSuccessMessage('Thêm danh mục thành công');
                  _loadData();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final sortOrderController = TextEditingController(text: category.sortOrder.toString());
    bool isActive = category.isActive;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sửa danh mục'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên danh mục *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: sortOrderController,
                  decoration: InputDecoration(
                    labelText: 'Thứ tự sắp xếp',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Kích hoạt: '),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Vui lòng nhập tên danh mục');
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  await _foodService.updateCategory(
                    categoryId: category.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                    isActive: isActive,
                  );

                  Navigator.pop(context);
                  _showSuccessMessage('Cập nhật danh mục thành công');
                  _loadData();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa danh mục'),
        content: Text('Bạn có chắc chắn muốn xóa danh mục "${category.name}"?\n\nLưu ý: Không thể xóa danh mục có chứa món ăn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _foodService.deleteCategory(category.id);
                _showSuccessMessage('Xóa danh mục thành công');
                _loadData();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== FOOD ITEM DIALOGS ==========

  void _showAddFoodItemDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    String? selectedCategoryId;
    bool isAvailable = true;
    bool isPopular = false;
    bool isLoading = false;
    XFile? selectedImage;
    String? imageUrl;

    if (_categories.isEmpty) {
      _showErrorSnackBar('Vui lòng tạo danh mục trước khi thêm món ăn');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm món ăn mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên món ăn *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Danh mục *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) =>
                      DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategoryId = value);
                  },
                ),
                SizedBox(height: 16),

                // Image picker
                GestureDetector(
                  onTap: () async {
                    try {
                      final image = await _foodService.pickImage();
                      if (image != null) {
                        setDialogState(() => selectedImage = image);
                      }
                    } catch (e) {
                      _showErrorSnackBar('Lỗi chọn ảnh: $e');
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        selectedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: Colors.grey),
                              Text('Ảnh đã chọn'),
                            ],
                          );
                        },
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.grey),
                        Text('Chọn ảnh món ăn'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Text('Có sẵn: '),
                    Switch(
                      value: isAvailable,
                      onChanged: (value) {
                        setDialogState(() => isAvailable = value);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Phổ biến: '),
                    Switch(
                      value: isPopular,
                      onChanged: (value) {
                        setDialogState(() => isPopular = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Vui lòng nhập tên món ăn');
                  return;
                }
                if (priceController.text.trim().isEmpty) {
                  _showErrorSnackBar('Vui lòng nhập giá');
                  return;
                }
                if (selectedCategoryId == null) {
                  _showErrorSnackBar('Vui lòng chọn danh mục');
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  // Upload image if selected
                  if (selectedImage != null) {
                    imageUrl = await _foodService.uploadImageToSupabase(
                      selectedImage!,
                      'food_items',
                    );
                  }

                  await _foodService.addFoodItem(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    price: int.parse(priceController.text.trim()),
                    categoryId: selectedCategoryId!,
                    imageUrl: imageUrl,
                    isAvailable: isAvailable,
                    isPopular: isPopular,
                  );

                  Navigator.pop(context);
                  _showSuccessMessage('Thêm món ăn thành công');
                  _loadData();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFoodItemDialog(FoodItem foodItem) {
    final nameController = TextEditingController(text: foodItem.name);
    final descriptionController = TextEditingController(text: foodItem.description);
    final priceController = TextEditingController(text: foodItem.price.toString());
    String selectedCategoryId = foodItem.categoryId;
    bool isAvailable = foodItem.isAvailable;
    bool isPopular = foodItem.isPopular;
    bool isLoading = false;
    XFile? selectedImage;
    String? imageUrl = foodItem.imageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sửa món ăn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên món ăn *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Danh mục *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) =>
                      DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategoryId = value!);
                  },
                ),
                SizedBox(height: 16),

                // Image picker
                GestureDetector(
                  onTap: () async {
                    try {
                      final image = await _foodService.pickImage();
                      if (image != null) {
                        setDialogState(() => selectedImage = image);
                      }
                    } catch (e) {
                      _showErrorSnackBar('Lỗi chọn ảnh: $e');
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.grey),
                          Text('Ảnh mới đã chọn'),
                        ],
                      ),
                    )
                        : imageUrl != null && imageUrl!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.grey),
                              Text('Chọn ảnh mới'),
                            ],
                          );
                        },
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.grey),
                        Text('Chọn ảnh món ăn'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Text('Có sẵn: '),
                    Switch(
                      value: isAvailable,
                      onChanged: (value) {
                        setDialogState(() => isAvailable = value);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Phổ biến: '),
                    Switch(
                      value: isPopular,
                      onChanged: (value) {
                        setDialogState(() => isPopular = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Vui lòng nhập tên món ăn');
                  return;
                }
                if (priceController.text.trim().isEmpty) {
                  _showErrorSnackBar('Vui lòng nhập giá');
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  // Upload new image if selected
                  if (selectedImage != null) {
                    imageUrl = await _foodService.uploadImageToSupabase(
                      selectedImage!,
                      'food_items',
                    );
                  }

                  await _foodService.updateFoodItem(
                    foodId: foodItem.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    price: int.parse(priceController.text.trim()),
                    categoryId: selectedCategoryId,
                    imageUrl: imageUrl,
                    isAvailable: isAvailable,
                    isPopular: isPopular,
                  );

                  Navigator.pop(context);
                  _showSuccessMessage('Cập nhật món ăn thành công');
                  _loadData();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteFoodItemDialog(FoodItem foodItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa món ăn'),
        content: Text('Bạn có chắc chắn muốn xóa món ăn "${foodItem.name}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _foodService.deleteFoodItem(foodItem.id);
                _showSuccessMessage('Xóa món ăn thành công');
                _loadData();
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
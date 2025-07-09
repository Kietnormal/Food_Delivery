// services/food_service.dart - CORRECTED VERSION
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as log;
<<<<<<< HEAD
// import '../models/category_model.dart';
=======
import '../models/category_model.dart';
>>>>>>> Tan_Binh

class FoodService {
  // Singleton pattern
  static final FoodService _instance = FoodService._internal(); // Fixed: underscore
  factory FoodService() => _instance;
  FoodService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'FoodService';

  // Cache for better performance
  List<Category> _categoriesCache = [];
  List<FoodItem> _foodItemsCache = [];
  DateTime? _lastCacheUpdate;

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Get all categories
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    try {
      print('=== FoodService.getCategories() START ===');

      // Check cache first
      if (!forceRefresh &&
          _categoriesCache.isNotEmpty &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        print('FoodService - Returning cached categories: ${_categoriesCache.length}');
        return _categoriesCache..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }

      print('FoodService - Fetching categories from Firebase...');
      final snapshot = await _database.child('categories').once();
      print('FoodService - Categories snapshot exists: ${snapshot.snapshot.exists}');

      if (snapshot.snapshot.exists) {
        final categoriesData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        print('FoodService - Categories data keys: ${categoriesData.keys.toList()}');

        _categoriesCache = categoriesData.entries.map((entry) {
          Map<String, dynamic> categoryMap = Map<String, dynamic>.from(entry.value as Map);
          categoryMap['id'] = entry.key; // Set the Firebase key as id
          return Category.fromJson(categoryMap);
        }).toList();

        _lastCacheUpdate = DateTime.now();
        print('FoodService - Loaded ${_categoriesCache.length} categories');
        print('=== FoodService.getCategories() SUCCESS ===');

        // Return all categories (sorted)
        return _categoriesCache..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }

      print('FoodService - No categories found');
      return [];
    } catch (e, stackTrace) {
      print('FoodService - ERROR in getCategories: $e');
      print('FoodService - Stack trace: $stackTrace');
      return [];
    }
  }

  // Get all food items - FIXED VERSION
  Future<List<FoodItem>> getFoodItems({bool forceRefresh = false}) async {
    print('=== FoodService.getFoodItems() START ===');
    print('FoodService - forceRefresh: $forceRefresh');

    try {
      // Check cache first
      if (!forceRefresh &&
          _foodItemsCache.isNotEmpty &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        print('FoodService - Returning cached food items: ${_foodItemsCache.length}');
        return _foodItemsCache;
      }

      print('FoodService - Fetching food items from Firebase...');

      final snapshot = await _database.child('food_items').once(); // Fixed: underscore
      print('FoodService - Got snapshot, exists: ${snapshot.snapshot.exists}');
      print('FoodService - Snapshot value type: ${snapshot.snapshot.value.runtimeType}');

      if (snapshot.snapshot.exists) {
        final foodItemsData = snapshot.snapshot.value;
        print('FoodService - Raw data: $foodItemsData');

        if (foodItemsData == null) {
          print('FoodService - Food items data is null!');
          return [];
        }

        List<FoodItem> tempFoodItems = [];

        // FIXED: Handle both Map and List formats properly
        if (foodItemsData is Map<dynamic, dynamic>) {
          print('FoodService - Processing as Map with ${foodItemsData.length} items');

          for (var entry in foodItemsData.entries) {
            try {
              if (entry.value == null) {
                print('FoodService - Skipping null entry: ${entry.key}');
                continue;
              }

              print('FoodService - Processing entry: ${entry.key}');
              print('FoodService - Entry value: ${entry.value}');

              Map<String, dynamic> itemMap = Map<String, dynamic>.from(entry.value as Map);
              itemMap['id'] = entry.key.toString();

              print('FoodService - Created itemMap: $itemMap');

              FoodItem foodItem = FoodItem.fromJson(itemMap);
              tempFoodItems.add(foodItem);

              print('FoodService - Added from Map: ${foodItem.name}');
            } catch (e, stackTrace) {
              print('FoodService - Error processing Map item ${entry.key}: $e');
              print('FoodService - Error stack trace: $stackTrace');
            }
          }
        }
        else if (foodItemsData is List) {
          print('FoodService - Processing as List with ${foodItemsData.length} items');

          for (int i = 0; i < foodItemsData.length; i++) {
            try {
              final item = foodItemsData[i];
              if (item == null) {
                print('FoodService - Skipping null item at index $i');
                continue;
              }

              if (item is! Map) {
                print('FoodService - Item at index $i is not a Map: ${item.runtimeType}');
                continue;
              }

              Map<String, dynamic> itemMap = Map<String, dynamic>.from(item as Map);

              // Use index as id if no id exists
              if (!itemMap.containsKey('id') || itemMap['id'] == null) {
                itemMap['id'] = i.toString();
              } else {
                itemMap['id'] = itemMap['id'].toString();
              }

              print('FoodService - Processing List item $i: ${itemMap['name']}');

              FoodItem foodItem = FoodItem.fromJson(itemMap);
              tempFoodItems.add(foodItem);

              print('FoodService - Added from List: ${foodItem.name} (id: ${foodItem.id})');
            } catch (e, stackTrace) {
              print('FoodService - Error processing List item $i: $e');
              print('FoodService - Stack trace: $stackTrace');
            }
          }
        }
        else {
          print('FoodService - Unknown data type: ${foodItemsData.runtimeType}');
          print('FoodService - Data content: $foodItemsData');
          return [];
        }

        _foodItemsCache = tempFoodItems;
        _lastCacheUpdate = DateTime.now();

        print('FoodService - Total items processed: ${_foodItemsCache.length}');
        print('=== FoodService.getFoodItems() SUCCESS ===');
        return _foodItemsCache;
      } else {
        print('FoodService - food_items snapshot does not exist!');
        return [];
      }
    } catch (e, stackTrace) {
      print('FoodService - CRITICAL ERROR in getFoodItems: $e');
      print('FoodService - Critical error stack trace: $stackTrace');
      return [];
    }
  }

  // Add new category
  Future<String> addCategory({
    required String name,
    required String description,
    String? imageUrl,
    int? sortOrder,
  }) async {
    try {
      print('FoodService - Adding new category: $name');

      final categoryRef = _database.child('categories').push();
      final categoryId = categoryRef.key!;

      final categoryData = {
        'name': name,
        'description': description,
        'imageUrl': imageUrl ?? '',
        'isActive': true,
        'sortOrder': sortOrder ?? 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await categoryRef.set(categoryData);
      clearCache();

      print('FoodService - Added category successfully: $categoryId');
      return categoryId;
    } catch (e) {
      print('FoodService - Error adding category: $e');
      throw Exception('Không thể thêm danh mục: $e');
    }
  }

  // Update category
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
  }) async {
    try {
      print('FoodService - Updating category: $categoryId');

      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isActive != null) updateData['isActive'] = isActive;
      if (sortOrder != null) updateData['sortOrder'] = sortOrder;

      await _database.child('categories').child(categoryId).update(updateData);
      clearCache();

      print('FoodService - Updated category successfully: $categoryId');
    } catch (e) {
      print('FoodService - Error updating category: $e');
      throw Exception('Không thể cập nhật danh mục: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      print('FoodService - Deleting category: $categoryId');

      // Check if category has food items
      final foodItems = await getFoodItems(forceRefresh: true);
      final hasItems = foodItems.any((item) => item.categoryId == categoryId);

      if (hasItems) {
        throw Exception('Không thể xóa danh mục có chứa món ăn');
      }

      await _database.child('categories').child(categoryId).remove();
      clearCache();

      print('FoodService - Deleted category successfully: $categoryId');
    } catch (e) {
      print('FoodService - Error deleting category: $e');
      throw Exception('Không thể xóa danh mục: $e');
    }
  }

  // Add new food item
  Future<String> addFoodItem({
    required String name,
    required String description,
    required int price,
    required String categoryId,
    String? imageUrl,
    bool isAvailable = true,
    bool isPopular = false,
  }) async {
    try {
      print('FoodService - Adding new food item: $name');

      final foodRef = _database.child('food_items').push(); // Fixed: underscore
      final foodId = foodRef.key!;

      final foodData = {
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'imageUrl': imageUrl ?? '',
        'isAvailable': isAvailable,
        'isPopular': isPopular,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await foodRef.set(foodData);
      clearCache();

      print('FoodService - Added food item successfully: $foodId');
      return foodId;
    } catch (e) {
      print('FoodService - Error adding food item: $e');
      throw Exception('Không thể thêm món ăn: $e');
    }
  }

  // Update food item
  Future<void> updateFoodItem({
    required String foodId,
    required String name,
    required String description,
    required int price,
    required String categoryId,
    String? imageUrl,
    bool? isAvailable,
    bool? isPopular,
  }) async {
    try {
      print('FoodService - Updating food item: $foodId');

      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (isPopular != null) updateData['isPopular'] = isPopular;

      await _database.child('food_items').child(foodId).update(updateData); // Fixed: underscore
      clearCache();

      print('FoodService - Updated food item successfully: $foodId');
    } catch (e) {
      print('FoodService - Error updating food item: $e');
      throw Exception('Không thể cập nhật món ăn: $e');
    }
  }

  // Delete food item
  Future<void> deleteFoodItem(String foodId) async {
    try {
      print('FoodService - Deleting food item: $foodId');

      // Get food item to delete image from Supabase if exists
      final snapshot = await _database.child('food_items').child(foodId).get(); // Fixed: underscore
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final imageUrl = data['imageUrl'] as String?;

        // Delete image from Supabase if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await deleteImageFromSupabase(imageUrl);
        }
      }

      await _database.child('food_items').child(foodId).remove(); // Fixed: underscore
      clearCache();

      print('FoodService - Deleted food item successfully: $foodId');
    } catch (e) {
      print('FoodService - Error deleting food item: $e');
      throw Exception('Không thể xóa món ăn: $e');
    }
  }

  // Upload image to Supabase - Upload directly to bucket root (no subfolders)
  Future<String> uploadImageToSupabase(XFile imageFile, String folder) async {
    try {
      print('FoodService - Uploading image to Supabase...');

      // Check if Supabase client is available
      try {
        final client = Supabase.instance.client;
        if (client == null) {
          throw Exception('Supabase client không khả dụng');
        }
      } catch (e) {
        throw Exception('Supabase chưa được khởi tạo: $e');
      }

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload directly to bucket root (no folder structure)
      final filePath = fileName; // No folder, just filename

      print('FoodService - Uploading to path: $filePath');

      // Upload file to Supabase Storage bucket 'food'
      await _supabase.storage
          .from('food')
          .uploadBinary(filePath, bytes);

      // Get public URL
      final imageUrl = _supabase.storage
          .from('food')
          .getPublicUrl(filePath);

      print('FoodService - Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('FoodService - Error uploading image: $e');

      // Handle specific errors
      if (e.toString().contains('duplicate') || e.toString().contains('already exists')) {
        throw Exception('Tên file đã tồn tại, vui lòng thử lại');
      } else if (e.toString().contains('unauthorized') || e.toString().contains('permission')) {
        throw Exception('Không có quyền upload ảnh. Kiểm tra Supabase policies.');
      } else if (e.toString().contains('not found') || e.toString().contains('bucket')) {
        throw Exception('Bucket "food" không tồn tại. Vui lòng tạo bucket trước.');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw Exception('Lỗi kết nối mạng, vui lòng thử lại');
      }

      throw Exception('Không thể tải lên hình ảnh: $e');
    }
  }

  // Delete image from Supabase - Updated for bucket root structure
  Future<void> deleteImageFromSupabase(String imageUrl) async {
    try {
      // Check if client is available
      try {
        final client = Supabase.instance.client;
        if (client == null) {
          print('FoodService - Supabase client not available, skipping image deletion');
          return;
        }
      } catch (e) {
        print('FoodService - Supabase not initialized, skipping image deletion: $e');
        return;
      }

      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      print('FoodService - URL segments: $segments');

      if (segments.length >= 4 && segments.contains('food')) {
        final bucketIndex = segments.indexOf('food');
        if (bucketIndex < segments.length - 1) {
          final filePath = segments.sublist(bucketIndex + 1).join('/');

          print('FoodService - Deleting file path: $filePath');

          await _supabase.storage
              .from('food')
              .remove([filePath]);

          print('FoodService - Image deleted from Supabase: $filePath');
        }
      } else {
        print('FoodService - Invalid image URL format: $imageUrl');
      }
    } catch (e) {
      print('FoodService - Error deleting image from Supabase: $e');
      // Don't throw error as this is not critical for app functionality
    }
  }

  // Test Supabase connection
  Future<bool> testSupabaseConnection() async {
    try {
      final client = Supabase.instance.client;

      // Test by listing buckets
      final buckets = await client.storage.listBuckets();
      print('FoodService - Supabase connection test successful: ${buckets.length} buckets found');

      // Check if food bucket exists
      final foodBucket = buckets.where((bucket) => bucket.name == 'food').firstOrNull;
      if (foodBucket == null) {
        print('FoodService - Warning: food bucket not found');
        return false;
      }

      print('FoodService - food bucket found and ready');
      return true;
    } catch (e) {
      print('FoodService - Supabase connection test failed: $e');
      return false;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('FoodService - Error picking image: $e');
      throw Exception('Không thể chọn hình ảnh: $e');
    }
  }

  // Helper methods
  Future<List<FoodItem>> getFoodItemsByCategory(String categoryId, {bool forceRefresh = false}) async {
    try {
      final allFoodItems = await getFoodItems(forceRefresh: forceRefresh);
      return allFoodItems.where((item) => item.categoryId == categoryId).toList();
    } catch (e) {
      print('FoodService - Error in getFoodItemsByCategory: $e');
      return [];
    }
  }

  Future<List<FoodItem>> searchFoodItems(String query, {bool forceRefresh = false}) async {
    try {
      if (query.trim().isEmpty) {
        return await getFoodItems(forceRefresh: forceRefresh);
      }

      final allFoodItems = await getFoodItems(forceRefresh: forceRefresh);
      final searchQuery = query.toLowerCase().trim();

      return allFoodItems.where((item) {
        return item.name.toLowerCase().contains(searchQuery) ||
            item.description.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('FoodService - Error searching food items: $e');
      return [];
    }
  }

  Future<List<FoodItem>> getPopularFoodItems({bool forceRefresh = false}) async {
    try {
      final allFoodItems = await getFoodItems(forceRefresh: forceRefresh);
      return allFoodItems.where((item) => item.isPopular && item.isAvailable).toList();
    } catch (e) {
      print('FoodService - Error fetching popular food items: $e');
      return [];
    }
  }

  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final categories = await getCategories();
      return categories.where((cat) => cat.id == categoryId).firstOrNull;
    } catch (e) {
      print('FoodService - Error fetching category by id: $e');
      return null;
    }
  }

  void clearCache() {
    _categoriesCache.clear();
    _foodItemsCache.clear();
    _lastCacheUpdate = null;
    print('FoodService - Cache cleared');
  }

  Future<void> refreshData() async {
    print('FoodService - Refreshing all data...');
    clearCache();
    await Future.wait([
      getCategories(forceRefresh: true),
      getFoodItems(forceRefresh: true),
    ]);
    print('FoodService - Data refresh completed');
  }
}
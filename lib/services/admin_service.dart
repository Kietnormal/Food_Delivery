// services/admin_service.dart
import 'package:firebase_database/firebase_database.dart';
// import '../models/admin_model.dart';

class AdminService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _adminsPath = 'admins';

  Admin? _currentAdmin;
  Admin? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null;

  // Đăng nhập admin
  Future<Admin?> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      print('AdminService - Attempting admin login for: $email');

      // Tìm admin theo email trong Realtime Database
      final DatabaseEvent event = await _database
          .child(_adminsPath)
          .orderByChild('email')
          .equalTo(email.trim().toLowerCase())
          .once();

      final DataSnapshot snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        print('AdminService - No admin found with email: $email');
        return null;
      }

      // Lấy dữ liệu admin
      final Map<dynamic, dynamic> adminsData = snapshot.value as Map<dynamic, dynamic>;

      // Tìm admin đầu tiên có email khớp và đang hoạt động
      String? adminId;
      Map<String, dynamic>? adminData;

      for (var entry in adminsData.entries) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        if (data['email'] == email.trim().toLowerCase() && (data['isActive'] ?? true)) {
          adminId = entry.key.toString();
          adminData = data;
          break;
        }
      }

      if (adminData == null || adminId == null) {
        print('AdminService - No active admin found with email: $email');
        return null;
      }

      // Kiểm tra mật khẩu (trong thực tế nên hash password)
      if (adminData['password'] != password) {
        print('AdminService - Invalid password for admin: $email');
        throw Exception('Email hoặc mật khẩu admin không đúng');
      }

      // Tạo đối tượng Admin
      _currentAdmin = Admin.fromJson({
        ...adminData,
        'id': adminId,
      });

      print('AdminService - Admin login successful: ${_currentAdmin!.username}');
      return _currentAdmin;

    } catch (e) {
      print('AdminService - Login error: $e');
      if (e.toString().contains('Email hoặc mật khẩu admin không đúng')) {
        rethrow;
      }
      throw Exception('Lỗi đăng nhập admin: ${e.toString()}');
    }
  }

  // Đăng xuất admin
  Future<void> signOutAdmin() async {
    try {
      _currentAdmin = null;
      print('AdminService - Admin signed out');
    } catch (e) {
      print('AdminService - Sign out error: $e');
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  // Lấy thông tin admin theo ID
  Future<Admin?> getAdminById(String adminId) async {
    try {
      final DatabaseEvent event = await _database
          .child(_adminsPath)
          .child(adminId)
          .once();

      final DataSnapshot snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final adminData = Map<String, dynamic>.from(snapshot.value as Map);
      return Admin.fromJson({
        ...adminData,
        'id': adminId,
      });
    } catch (e) {
      print('AdminService - Get admin error: $e');
      throw Exception('Lỗi lấy thông tin admin: ${e.toString()}');
    }
  }

  // Tạo admin mới (chỉ dành cho super admin)
  Future<Admin> createAdmin({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String role = 'admin',
    String avatar = '',
  }) async {
    try {
      // Kiểm tra email đã tồn tại chưa
      final DatabaseEvent event = await _database
          .child(_adminsPath)
          .orderByChild('email')
          .equalTo(email.trim().toLowerCase())
          .once();

      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists && snapshot.value != null) {
        throw Exception('Email admin đã được sử dụng');
      }

      // Tạo admin mới
      final String timestamp = DateTime.now().toIso8601String();
      final Map<String, dynamic> adminData = {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password, // Trong thực tế nên hash password
        'fullName': fullName.trim(),
        'role': role,
        'avatar': avatar,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isActive': true,
      };

      // Tạo key mới và lưu data
      final DatabaseReference newAdminRef = _database.child(_adminsPath).push();
      await newAdminRef.set(adminData);

      final String adminId = newAdminRef.key!;

      return Admin.fromJson({
        ...adminData,
        'id': adminId,
      });
    } catch (e) {
      print('AdminService - Create admin error: $e');
      throw Exception('Lỗi tạo admin: ${e.toString()}');
    }
  }

  // Cập nhật thông tin admin
  Future<Admin> updateAdmin({
    required String adminId,
    String? username,
    String? email,
    String? fullName,
    String? role,
    String? avatar,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (username != null) updateData['username'] = username.trim();
      if (email != null) updateData['email'] = email.trim().toLowerCase();
      if (fullName != null) updateData['fullName'] = fullName.trim();
      if (role != null) updateData['role'] = role;
      if (avatar != null) updateData['avatar'] = avatar;
      if (isActive != null) updateData['isActive'] = isActive;

      await _database
          .child(_adminsPath)
          .child(adminId)
          .update(updateData);

      // Lấy dữ liệu mới
      final updatedAdmin = await getAdminById(adminId);
      if (updatedAdmin == null) {
        throw Exception('Không thể lấy thông tin admin sau khi cập nhật');
      }

      // Cập nhật current admin nếu đang đăng nhập
      if (_currentAdmin?.id == adminId) {
        _currentAdmin = updatedAdmin;
      }

      return updatedAdmin;
    } catch (e) {
      print('AdminService - Update admin error: $e');
      throw Exception('Lỗi cập nhật admin: ${e.toString()}');
    }
  }

  // Đổi mật khẩu admin
  Future<void> changePassword({
    required String adminId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Lấy thông tin admin hiện tại
      final admin = await getAdminById(adminId);
      if (admin == null) {
        throw Exception('Admin không tồn tại');
      }

      // Kiểm tra mật khẩu hiện tại
      if (admin.password != currentPassword) {
        throw Exception('Mật khẩu hiện tại không đúng');
      }

      // Cập nhật mật khẩu mới
      await _database
          .child(_adminsPath)
          .child(adminId)
          .update({
        'password': newPassword, // Trong thực tế nên hash password
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('AdminService - Password changed successfully for admin: $adminId');
    } catch (e) {
      print('AdminService - Change password error: $e');
      throw Exception('Lỗi đổi mật khẩu: ${e.toString()}');
    }
  }

  // Lấy danh sách tất cả admin (chỉ dành cho super admin)
  Future<List<Admin>> getAllAdmins() async {
    try {
      final DatabaseEvent event = await _database
          .child(_adminsPath)
          .orderByChild('createdAt')
          .once();

      final DataSnapshot snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final Map<dynamic, dynamic> adminsData = snapshot.value as Map<dynamic, dynamic>;

      List<Admin> adminsList = [];
      for (var entry in adminsData.entries) {
        final adminData = Map<String, dynamic>.from(entry.value as Map);
        adminsList.add(Admin.fromJson({
          ...adminData,
          'id': entry.key.toString(),
        }));
      }

      // Sắp xếp theo thời gian tạo (mới nhất trước)
      adminsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return adminsList;
    } catch (e) {
      print('AdminService - Get all admins error: $e');
      throw Exception('Lỗi lấy danh sách admin: ${e.toString()}');
    }
  }

  // Kiểm tra quyền admin
  bool hasPermission(String permission) {
    if (_currentAdmin == null) return false;

    // Logic kiểm tra quyền dựa trên role
    switch (_currentAdmin!.role) {
      case 'super_admin':
        return true; // Super admin có tất cả quyền
      case 'admin':
        return permission != 'manage_admins'; // Admin thường không được quản lý admin khác
      default:
        return false;
    }
  }

  // Debug thông tin admin hiện tại
  void debugCurrentState() {
    print('=== AdminService Debug ===');
    print('Current admin: ${_currentAdmin?.username ?? 'None'}');
    print('Is logged in: $isLoggedIn');
    print('Admin role: ${_currentAdmin?.role ?? 'None'}');
    print('========================');
  }
}
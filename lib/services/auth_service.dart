import 'package:firebase_database/firebase_database.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as log;
import 'dart:math';
import '../models/user_model.dart' as AppUser;

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  static const String _tag = 'AuthService';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Current user state
  AppUser.User? _currentUser;
  bool _isInitialized = false;

  // Get current user
  AppUser.User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Hash password
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique user ID
  String _generateUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return 'user_${timestamp}_$randomNum';
  }

  // Initialize - Load saved user from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) {
      log.log('AuthService already initialized', name: _tag);
      return;
    }

    try {
      log.log('Initializing AuthService...', name: _tag);
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      log.log('SharedPreferences isLoggedIn: $isLoggedIn', name: _tag);

      if (isLoggedIn) {
        final userJson = prefs.getString(_currentUserKey);
        log.log('Stored user JSON exists: ${userJson != null}', name: _tag);

        if (userJson != null) {
          final userData = json.decode(userJson);
          _currentUser = AppUser.User.fromJson(userData);
          log.log('User session restored: ${_currentUser?.email}', name: _tag);
        }
      }

      _isInitialized = true;
      log.log('AuthService initialized successfully. Current user: ${_currentUser?.email}', name: _tag);
    } catch (e) {
      log.log('Initialize error: $e', name: _tag, error: e, level: 1000);
      _isInitialized = true; // Set to true even on error to avoid infinite loops
    }
  }

  // Save user session to SharedPreferences
  Future<void> _saveUserSession(AppUser.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(user.toJson()));
      await prefs.setBool(_isLoggedInKey, true);
      log.log('User session saved successfully', name: _tag);
    } catch (e) {
      log.log('Save user session error: $e', name: _tag, error: e, level: 1000);
    }
  }

  // Clear user session
  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.setBool(_isLoggedInKey, false);
      log.log('User session cleared', name: _tag);
    } catch (e) {
      log.log('Clear user session error: $e', name: _tag, error: e, level: 1000);
    }
  }

  // Check if email already exists
  Future<bool> _isEmailExists(String email) async {
    try {
      final snapshot = await _database
          .child('users')
          .orderByChild('email')
          .equalTo(email)
          .once();

      return snapshot.snapshot.exists;
    } catch (e) {
      log.log('Check email exists error: $e', name: _tag, error: e, level: 1000);
      return false;
    }
  }

  Future<AppUser.User?> signUp({
    required String name,
    required String email,
    required String password,
    required int birthYear,
    required String address,
    required String phone,
    int? provinceId,
    int? districtId,
    String? wardCode,
  }) async {
    try {
      log.log('Starting user registration for email: $email', name: _tag);

      // Check if email already exists
      if (await _isEmailExists(email)) {
        log.log('Email already exists: $email', name: _tag, level: 900);
        throw Exception('Email đã được sử dụng');
      }

      // Generate unique user ID
      final userId = _generateUserId();

      // Create user data theo model User với địa chỉ mở rộng
      AppUser.User newUser = AppUser.User(
        id: userId,
        name: name,
        email: email,
        password: _hashPassword(password),
        birthYear: birthYear,
        address: address,
        phone: phone,
        avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        isActive: true,
        provinceId: provinceId,
        districtId: districtId,
        wardCode: wardCode,
      );

      // Save to Realtime Database (toJson() sẽ tự động include các field địa chỉ)
      await _database.child('users').child(userId).set(newUser.toJson());

      log.log('User data saved to database successfully: $userId', name: _tag);
      log.log('Full address: $address', name: _tag);
      log.log('Address details - Province: $provinceId, District: $districtId, Ward: $wardCode', name: _tag);

      // Set current user
      _currentUser = newUser;
      await _saveUserSession(newUser);

      log.log('Sign up completed successfully for: ${newUser.email}', name: _tag);
      return newUser;

    } catch (e) {
      log.log('Sign up error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

// Method để lấy thông tin địa chỉ mở rộng từ Firebase
  Future<Map<String, dynamic>?> getCurrentUserAddressDetails() async {
    if (_currentUser == null) return null;

    try {
      final snapshot = await _database.child('users').child(_currentUser!.id).once();
      if (snapshot.snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        return {
          'address': userData['address'],
          'provinceId': userData['provinceId'],
          'districtId': userData['districtId'],
          'wardCode': userData['wardCode'],
        };
      }
    } catch (e) {
      log.log('Get address details error: $e', name: _tag, error: e, level: 1000);
    }
    return null;
  }

// Method để cập nhật địa chỉ với thông tin mở rộng
  Future<bool> updateUserAddress({
    required String address,
    int? provinceId,
    int? districtId,
    String? wardCode,
  }) async {
    if (_currentUser == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    try {
      log.log('Updating address for user: ${_currentUser!.id}', name: _tag);

      // Tạo data cập nhật với thông tin địa chỉ mở rộng
      Map<String, dynamic> updateData = {
        'address': address,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Thêm các field địa chỉ mở rộng
      if (provinceId != null) updateData['provinceId'] = provinceId;
      if (districtId != null) updateData['districtId'] = districtId;
      if (wardCode != null) updateData['wardCode'] = wardCode;

      // Cập nhật Firebase
      await _database.child('users').child(_currentUser!.id).update(updateData);

      // Cập nhật current user với đầy đủ thông tin địa chỉ
      _currentUser = _currentUser!.copyWith(
        address: address,
        updatedAt: DateTime.now().toIso8601String(),
        provinceId: provinceId,
        districtId: districtId,
        wardCode: wardCode,
      );

      await _saveUserSession(_currentUser!);

      log.log('Address updated successfully', name: _tag);
      log.log('New address: $address', name: _tag);
      log.log('Address details - Province: $provinceId, District: $districtId, Ward: $wardCode', name: _tag);

      return true;
    } catch (e) {
      log.log('Update address error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

// Method để load user từ Firebase với đầy đủ thông tin
  Future<AppUser.User?> _loadUserFromFirebase(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).once();
      if (snapshot.snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        return AppUser.User.fromJson(userData);
      }
    } catch (e) {
      log.log('Load user from Firebase error: $e', name: _tag, error: e, level: 1000);
    }
    return null;
  }

  Future<bool> updateUserAvatar({
    required String avatarUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    try {
      log.log('Updating avatar for user: ${_currentUser!.id}', name: _tag);

      // Tạo data cập nhật
      Map<String, dynamic> updateData = {
        'avatar': avatarUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Cập nhật Firebase
      await _database.child('users').child(_currentUser!.id).update(updateData);

      // Cập nhật current user
      _currentUser = _currentUser!.copyWith(
        avatar: avatarUrl,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _saveUserSession(_currentUser!);

      log.log('Avatar updated successfully', name: _tag);
      log.log('New avatar URL: $avatarUrl', name: _tag);

      return true;
    } catch (e) {
      log.log('Update avatar error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

// Method để cập nhật thông tin user (đã được cập nhật để hỗ trợ avatar)
  Future<bool> updateUserData(AppUser.User updatedUser) async {
    if (_currentUser == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    try {
      log.log('Updating user data for: ${updatedUser.id}', name: _tag);

      // Giữ lại các thông tin địa chỉ mở rộng từ current user nếu không được cập nhật
      AppUser.User userToUpdate = updatedUser.copyWith(
        provinceId: updatedUser.provinceId ?? _currentUser!.provinceId,
        districtId: updatedUser.districtId ?? _currentUser!.districtId,
        wardCode: updatedUser.wardCode ?? _currentUser!.wardCode,
        // Giữ lại password cũ nếu không thay đổi
        password: updatedUser.password.isEmpty ? _currentUser!.password : updatedUser.password,
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Cập nhật Firebase với đầy đủ thông tin
      await _database.child('users').child(userToUpdate.id).update(userToUpdate.toJson());

      // Cập nhật current user
      _currentUser = userToUpdate;
      await _saveUserSession(_currentUser!);

      log.log('User data updated successfully', name: _tag);
      log.log('Updated avatar: ${userToUpdate.avatar}', name: _tag);

      return true;
    } catch (e) {
      log.log('Update user data error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }
  // Sign in with email and password
  Future<AppUser.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      log.log('Starting user sign in for email: $email', name: _tag);

      final hashedPassword = _hashPassword(password);

      // Query user by email
      final snapshot = await _database
          .child('users')
          .orderByChild('email')
          .equalTo(email)
          .once();

      if (snapshot.snapshot.exists) {
        // Get the first (and should be only) user with this email
        final usersData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final userData = usersData.values.first as Map<dynamic, dynamic>;

        // Convert to proper map
        Map<String, dynamic> userMap = Map<String, dynamic>.from(userData);

        // Check password
        if (userMap['password'] == hashedPassword) {
          // Check if user is active
          if (userMap['isActive'] == true) {
            final user = AppUser.User.fromJson(userMap);
            log.log('User sign in successful: ${user.id}', name: _tag);

            // Update last login time
            await _database.child('users').child(user.id).update({
              'updatedAt': DateTime.now().toIso8601String(),
            });

            // Set current user and save session
            _currentUser = user;
            await _saveUserSession(user);

            log.log('Sign in completed successfully for: ${user.email}', name: _tag);
            return user;
          } else {
            log.log('User account is deactivated', name: _tag, level: 900);
            throw Exception('Tài khoản đã bị vô hiệu hóa');
          }
        } else {
          log.log('Invalid password for email: $email', name: _tag, level: 900);
          throw Exception('Email hoặc mật khẩu không đúng');
        }
      } else {
        log.log('User not found for email: $email', name: _tag, level: 900);
        throw Exception('Email hoặc mật khẩu không đúng');
      }
    } catch (e) {
      log.log('Sign in error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      log.log('Signing out user: ${_currentUser?.email}', name: _tag);
      _currentUser = null;
      await _clearUserSession();
      log.log('User signed out successfully', name: _tag);
    } catch (e) {
      log.log('Sign out error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

  // Get user data from database
  Future<AppUser.User?> getUserData(String uid) async {
    try {
      log.log('Getting user data for UID: $uid', name: _tag);

      DatabaseEvent event = await _database.child('users').child(uid).once();
      if (event.snapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        log.log('User data retrieved successfully', name: _tag);
        return AppUser.User.fromJson(userData);
      } else {
        log.log('User data not found for UID: $uid', name: _tag, level: 900);
      }
    } catch (e) {
      log.log('Get user data error: $e', name: _tag, error: e, level: 1000);
    }
    return null;
  }


  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      log.log('Changing password for user: ${_currentUser!.id}', name: _tag);

      // Verify current password
      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (_currentUser!.password != hashedCurrentPassword) {
        throw Exception('Mật khẩu hiện tại không đúng');
      }

      // Update password
      final hashedNewPassword = _hashPassword(newPassword);
      await _database.child('users').child(_currentUser!.id).update({
        'password': hashedNewPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update current user
      _currentUser = _currentUser!.copyWith(
        password: hashedNewPassword,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _saveUserSession(_currentUser!);

      log.log('Password changed successfully', name: _tag);
      return true;
    } catch (e) {
      log.log('Change password error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

  // Reset password (would need to implement email sending separately)
  Future<void> resetPassword(String email) async {
    try {
      log.log('Password reset requested for email: $email', name: _tag);

      // Check if email exists
      if (!await _isEmailExists(email)) {
        throw Exception('Email không tồn tại trong hệ thống');
      }

      // In a real implementation, you would:
      // 1. Generate a reset token
      // 2. Save it to database with expiration
      // 3. Send email with reset link
      // For now, just log the request

      log.log('Password reset email would be sent to: $email', name: _tag);
      throw Exception('Tính năng reset password chưa được triển khai đầy đủ');

    } catch (e) {
      log.log('Reset password error: $e', name: _tag, error: e, level: 1000);
      throw e;
    }
  }

  // Debug method to check current state
  void debugCurrentState() {
    log.log('=== AuthService Debug State ===', name: _tag);
    log.log('Initialized: $_isInitialized', name: _tag);
    log.log('Current User: ${_currentUser?.email ?? 'null'}', name: _tag);
    log.log('Is Logged In: $isLoggedIn', name: _tag);
    log.log('User ID: ${_currentUser?.id ?? 'null'}', name: _tag);
    log.log('===============================', name: _tag);
  }
}
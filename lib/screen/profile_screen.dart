import 'package:appfoodstore/screen/setting_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as AppUser;
import 'info_screen.dart';
import 'mail_screen.dart';
import 'login_screen.dart'; // Import login screen for logout

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  AppUser.User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      setState(() => _isLoading = true);

      print('ProfileScreen - Starting load current user...');

      // AuthService is singleton, so it should maintain state
      if (!_authService.isInitialized) {
        print('ProfileScreen - AuthService not initialized, initializing...');
        await _authService.initialize();
      } else {
        print('ProfileScreen - AuthService already initialized');
      }

      // Debug current state
      _authService.debugCurrentState();

      // Get current user
      _currentUser = _authService.currentUser;

      print('ProfileScreen - Current user after init: ${_currentUser?.email}');
      print('ProfileScreen - Is logged in: ${_authService.isLoggedIn}');

      if (_currentUser == null) {
        print('ProfileScreen - User is null, waiting a bit more...');
        // Try to check if there's any stored session data
        await Future.delayed(Duration(milliseconds: 1000)); // Give more time
        _currentUser = _authService.currentUser;

        if (_currentUser == null) {
          print('ProfileScreen - Still no user found after delay');
          // Instead of redirecting immediately, show the error state
          // Let user choose to retry or login
          return;
        }
      }

      print('ProfileScreen - User found: ${_currentUser!.name} (${_currentUser!.email})');

      // Optionally refresh user data from database
      try {
        print('ProfileScreen - Refreshing user data from database...');
        final refreshedUser = await _authService.getUserData(_currentUser!.id);
        if (refreshedUser != null) {
          _currentUser = refreshedUser;
          print('ProfileScreen - User data refreshed successfully');
        } else {
          print('ProfileScreen - No refreshed data found, using cached user');
        }
      } catch (e) {
        print('ProfileScreen - Error refreshing user data: $e');
        // Continue with cached user data
      }

    } catch (e) {
      print('ProfileScreen - Error loading user: $e');
      _showErrorSnackBar('Không thể tải thông tin người dùng: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      _redirectToLogin();
    } catch (e) {
      _showErrorSnackBar('Có lỗi khi đăng xuất');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Profile', style: TextStyle(color: Colors.black)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF5DADE2)),
              SizedBox(height: 16),
              Text('Đang tải thông tin...'),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Profile', style: TextStyle(color: Colors.black)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Không thể tải thông tin người dùng',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadCurrentUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5DADE2),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Thử lại'),
                  ),
                  SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _redirectToLogin,
                    child: Text('Đăng nhập lại'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _showLogoutDialog,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrentUser,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20),

              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _currentUser!.avatar.isNotEmpty
                      ? NetworkImage(_currentUser!.avatar)
                      : null,
                  child: _currentUser!.avatar.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[600], size: 50)
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle image load error
                    setState(() {});
                  },
                ),
              ),

              SizedBox(height: 16),

              // User name
              Text(
                _currentUser!.name.isNotEmpty ? _currentUser!.name : 'Chưa có tên',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // User email
              Text(
                _currentUser!.email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40),

              // Menu items
              _buildMenuItem(
                icon: Icons.person_outline,
                title: 'Thông tin cá nhân',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInfoScreen(user: _currentUser!),
                    ),
                  );

                  // Refresh user data if updated
                  if (result == true) {
                    await _loadCurrentUser();
                  }
                },
              ),

              _buildMenuItem(
                icon: Icons.mail_outline,
                title: 'Hộp thư',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MailboxScreen()),
                  );
                },
              ),

              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Cài đặt',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),

              // Account info section
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Số điện thoại', _currentUser!.phone.isNotEmpty ? _currentUser!.phone : 'Chưa cập nhật'),
                    _buildInfoRow('Năm sinh', _currentUser!.birthYear > 0 ? _currentUser!.birthYear.toString() : 'Chưa cập nhật'),
                    _buildInfoRow('Địa chỉ', _currentUser!.address.isNotEmpty ? _currentUser!.address : 'Chưa cập nhật'),
                    _buildInfoRow('Ngày tham gia', _formatDate(_currentUser!.createdAt)),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Bottom indicator


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF5DADE2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Color(0xFF5DADE2)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Không xác định';
    }
  }
}
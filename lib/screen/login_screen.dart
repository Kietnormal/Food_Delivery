import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/ghn_service.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart' as AppUser;
import '../models/ghn_models.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool _obscureText = true;
  bool isLoading = false;
  bool isLoadingProvinces = false;
  bool isLoadingDistricts = false;
  bool isLoadingWards = false;

  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController specificAddressController = TextEditingController();
  final TextEditingController birthYearController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // GHN data
  List<Province> provinces = [];
  List<District> districts = [];
  List<Ward> wards = [];

  Province? selectedProvince;
  District? selectedDistrict;
  Ward? selectedWard;
  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadProvinces();
  }

  Future<void> _initializeAuth() async {
    try {
      print('LoginScreen - Initializing AuthService...');
      await _authService.initialize();
      print('LoginScreen - Auth initialized');
      print('LoginScreen - Current user: ${_authService.currentUser?.email}');

      if (_authService.isLoggedIn && _authService.currentUser != null) {
        print('LoginScreen - User already logged in, redirecting to home');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        });
      }
    } catch (e) {
      print('LoginScreen - Auth initialization error: $e');
    }
  }
  Future<void> _loadProvinces() async {
    if (isLoadingProvinces) return;

    setState(() => isLoadingProvinces = true);
    try {
      final loadedProvinces = await GHNService.getProvinces();
      if (mounted) {
        setState(() {
          provinces = loadedProvinces;
          isLoadingProvinces = false;
        });
      }
    } catch (e) {
      print('Error loading provinces: $e');
      if (mounted) {
        setState(() => isLoadingProvinces = false);
        _showErrorSnackBar('Không thể tải danh sách tỉnh thành');
      }
    }
  }
  Future<void> _loadDistricts(int provinceId) async {
    if (isLoadingDistricts) return;

    setState(() {
      isLoadingDistricts = true;
      selectedDistrict = null;
      selectedWard = null;
      districts.clear();
      wards.clear();
    });

    try {
      final loadedDistricts = await GHNService.getDistricts(provinceId);
      if (mounted) {
        setState(() {
          districts = loadedDistricts;
          isLoadingDistricts = false;
        });
      }
    } catch (e) {
      print('Error loading districts: $e');
      if (mounted) {
        setState(() => isLoadingDistricts = false);
        _showErrorSnackBar('Không thể tải danh sách quận huyện');
      }
    }
  }
  Future<void> _loadWards(int districtId) async {
    if (isLoadingWards) return;

    setState(() {
      isLoadingWards = true;
      selectedWard = null;
      wards.clear();
    });

    try {
      final loadedWards = await GHNService.getWards(districtId);
      if (mounted) {
        setState(() {
          wards = loadedWards;
          isLoadingWards = false;
        });
      }
    } catch (e) {
      print('Error loading wards: $e');
      if (mounted) {
        setState(() => isLoadingWards = false);
        _showErrorSnackBar('Không thể tải danh sách phường xã');
      }
    }
  }
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    specificAddressController.dispose();
    birthYearController.dispose();
    super.dispose();
  }
  Future<void> _handleAuth() async {
    if (_validateInputs()) {
      setState(() => isLoading = true);

      try {
        // Kiểm tra admin trước
        print('LoginScreen - Checking for admin login...');
        Admin? admin = await _checkAdminLogin();

        if (admin != null) {
          print('LoginScreen - Admin login successful: ${admin.username}');
          _showSuccessMessage('Đăng nhập admin thành công!');

          await Future.delayed(Duration(milliseconds: 1500));

          if (mounted) {
            print('LoginScreen - Navigating to Admin Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
            );
          }
          return;
        }

        // Nếu không phải admin, thực hiện đăng nhập/đăng ký thông thường
        print('LoginScreen - Not admin, proceeding with normal auth...');
        AppUser.User? user;

        if (isLogin) {
          print('LoginScreen - Attempting user login for: ${emailController.text.trim()}');
          user = await _authService.signIn(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
        } else {
          print('LoginScreen - Attempting user signup for: ${emailController.text.trim()}');

          // Tạo địa chỉ đầy đủ từ các thành phần đã chọn
          String fullAddress = _buildFullAddress();

          user = await _authService.signUp(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
            birthYear: int.parse(birthYearController.text.trim()),
            address: fullAddress,
            phone: phoneController.text.trim(),
            // Có thể thêm các field mới để lưu ID
            provinceId: selectedProvince?.provinceId,
            districtId: selectedDistrict?.districtId,
            wardCode: selectedWard?.wardCode,
          );
        }

        if (user != null) {
          print('LoginScreen - User auth successful for: ${user.email}');
          print('LoginScreen - User ID: ${user.id}');

          _authService.debugCurrentState();
          _showSuccessMessage(isLogin ? 'Đăng nhập thành công!' : 'Đăng ký thành công!');

          await Future.delayed(Duration(milliseconds: 1500));

          if (mounted) {
            print('LoginScreen - Navigating to HomeScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        } else {
          print('LoginScreen - Auth returned null user');
          _showErrorSnackBar('Đăng nhập thất bại, vui lòng thử lại');
        }
      } catch (e) {
        print('LoginScreen - Auth error: $e');
        print('LoginScreen - Auth error type: ${e.runtimeType}');

        String errorMessage = _getErrorMessage(e.toString());
        _showErrorSnackBar(errorMessage);
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }
  Future<Admin?> _checkAdminLogin() async {
    try {
      if (!isLogin) {
        // Không kiểm tra admin cho đăng ký
        return null;
      }

      // Kiểm tra xem có phải admin không
      Admin? admin = await _adminService.signInAdmin(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      return admin;
    } catch (e) {
      print('LoginScreen - Admin check error: $e');
      // Không phải lỗi nghiêm trọng, chỉ là không phải admin
      return null;
    }
  }
  String _buildFullAddress() {
    List<String> addressParts = [];

    if (specificAddressController.text.trim().isNotEmpty) {
      addressParts.add(specificAddressController.text.trim());
    }

    if (selectedWard != null) {
      addressParts.add(selectedWard!.wardName);
    }

    if (selectedDistrict != null) {
      addressParts.add(selectedDistrict!.districtName);
    }

    if (selectedProvince != null) {
      addressParts.add(selectedProvince!.provinceName);
    }

    return addressParts.join(', ');
  }
  bool _validateInputs() {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showErrorSnackBar('Vui lòng điền email và mật khẩu');
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      _showErrorSnackBar('Email không đúng định dạng');
      return false;
    }

    if (passwordController.text.length < 6) {
      _showErrorSnackBar('Mật khẩu phải có ít nhất 6 ký tự');
      return false;
    }

    if (!isLogin) {
      if (nameController.text.trim().isEmpty) {
        _showErrorSnackBar('Vui lòng nhập tên của bạn');
        return false;
      }
      if (phoneController.text.trim().isEmpty) {
        _showErrorSnackBar('Vui lòng nhập số điện thoại');
        return false;
      }
      if (selectedProvince == null) {
        _showErrorSnackBar('Vui lòng chọn tỉnh thành');
        return false;
      }
      if (selectedDistrict == null) {
        _showErrorSnackBar('Vui lòng chọn quận huyện');
        return false;
      }
      if (selectedWard == null) {
        _showErrorSnackBar('Vui lòng chọn phường xã');
        return false;
      }
      if (specificAddressController.text.trim().isEmpty) {
        _showErrorSnackBar('Vui lòng nhập địa chỉ cụ thể');
        return false;
      }
      if (birthYearController.text.trim().isEmpty) {
        _showErrorSnackBar('Vui lòng nhập năm sinh');
        return false;
      }

      try {
        int birthYear = int.parse(birthYearController.text.trim());
        int currentYear = DateTime.now().year;
        if (birthYear < 1900 || birthYear > currentYear - 5) {
          _showErrorSnackBar('Năm sinh không hợp lệ');
          return false;
        }
      } catch (e) {
        _showErrorSnackBar('Năm sinh phải là số');
        return false;
      }
    }
    return true;
  }
  String _getErrorMessage(String error) {
    print('Raw error: $error');

    String cleanError = error;
    if (error.startsWith('Exception: ')) {
      cleanError = error.substring('Exception: '.length);
    }

    if (cleanError.contains('Email đã được sử dụng')) {
      return 'Email này đã được sử dụng';
    } else if (cleanError.contains('Email hoặc mật khẩu không đúng')) {
      return 'Email hoặc mật khẩu không đúng';
    } else if (cleanError.contains('Tài khoản đã bị vô hiệu hóa')) {
      return 'Tài khoản đã bị vô hiệu hóa';
    } else if (cleanError.contains('Người dùng chưa đăng nhập')) {
      return 'Vui lòng đăng nhập lại';
    } else if (cleanError.contains('Mật khẩu hiện tại không đúng')) {
      return 'Mật khẩu hiện tại không đúng';
    } else if (cleanError.contains('Email không tồn tại trong hệ thống')) {
      return 'Email không tồn tại trong hệ thống';
    } else if (cleanError.contains('Tính năng reset password chưa được triển khai đầy đủ')) {
      return 'Tính năng reset password chưa được triển khai';
    } else if (error.contains('network') || error.contains('NetworkException')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
    } else if (error.contains('permission') || error.contains('PermissionException')) {
      return 'Lỗi quyền truy cập cơ sở dữ liệu';
    } else if (error.contains('firebase') || error.contains('FirebaseException')) {
      return 'Lỗi kết nối Firebase. Vui lòng thử lại';
    } else if (cleanError.isNotEmpty && cleanError != error) {
      return cleanError;
    } else {
      return 'Đã có lỗi xảy ra. Vui lòng thử lại sau';
    }
  }
  //thong bao loi
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
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  //thong bao thanh cong
  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
      ),
      body: SingleChildScrollView(
        padding:  EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'XIN CHÀO!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
             Text(
              'Đăng ký hoặc Đăng nhập vào tài khoản của bạn',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
             SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isLogin = true),
                      child: Container(
                        padding:  EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isLogin ?  Color(0xFFE8C5E8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Đăng nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLogin ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isLogin = false),
                      child: Container(
                        padding:  EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isLogin ?  Color(0xFFE8C5E8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Đăng ký',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !isLogin ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
             SizedBox(height: 30),

            if (!isLogin) ...[
              _buildTextField('Tên',
                  nameController
              ),
               SizedBox(height: 16),

              _buildTextField('Số điện thoại',
                  phoneController,
                  TextInputType.phone
              ),
               SizedBox(height: 16),

              //Dropdown chọn tỉnh thành
              _buildDropdownField('Tỉnh thành',
                selectedProvince?.toString() ?? 'Chọn tỉnh thành',
                isLoadingProvinces, () => _showProvinceSelector(),
              ),
               SizedBox(height: 16),

              //Dropdown chọn quận huyện
              _buildDropdownField('Quận huyện',
                  selectedDistrict?.toString() ?? 'Chọn quận huyện',
                  isLoadingDistricts,
                selectedProvince != null ? () => _showDistrictSelector() : null,
              ),
               SizedBox(height: 16),

              //Dropdown chọn phường xã
              _buildDropdownField('Phường xã',
                  selectedWard?.toString() ?? 'Chọn phường xã',
                  isLoadingWards,
                selectedDistrict != null ? () => _showWardSelector() : null,
              ),
               SizedBox(height: 16),

              _buildTextField('Địa chỉ cụ thể',
                  specificAddressController
              ),
               SizedBox(height: 16),

              _buildTextField('Năm sinh',
                  birthYearController,
                  TextInputType.number
              ),
               SizedBox(height: 16),

            ],
            _buildTextField('Email',
                emailController,
                TextInputType.emailAddress
            ),
             SizedBox(height: 16),

            _buildPasswordField(isLogin ? 'Mật khẩu' : 'Tạo mật khẩu',
                passwordController
            ),
             SizedBox(height: 30),
            //Quên mật khẩu
            if (isLogin) ...[
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _resetPassword,
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),

            //Auth button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleAuth,

                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xFF5DADE2),
                  foregroundColor: Colors.white,
                  padding:  EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isLoading ? 0 : 2,
                ),

                  child: isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? 'Đăng nhập' : 'Đăng ký',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      TextEditingController controller,
      [TextInputType keyboardType = TextInputType.text]
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style:  TextStyle(fontWeight: FontWeight.w500)),
         SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:  Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
               EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Nhập $label',
              hintStyle:  TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style:  TextStyle(fontWeight: FontWeight.w500)),
         SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:  Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: _obscureText,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
               EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Nhập $label',
              hintStyle:  TextStyle(color: Colors.grey),
                suffixIcon: IconButton(onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                }, icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility)
                )
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, bool isLoading, VoidCallback? onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style:  TextStyle(fontWeight: FontWeight.w500)),
         SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: onTap != null ? Color(0xFFE8E8E8) : Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: onTap != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  else if (onTap != null)
                    Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  //hàm chọn Tỉnh thành
  void _showProvinceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Chọn tỉnh thành',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: provinces.length,
                itemBuilder: (context, index) {
                  final province = provinces[index];
                  return ListTile(
                    title: Text(province.provinceName),
                    onTap: () {
                      setState(() {
                        selectedProvince = province;
                        selectedDistrict = null;
                        selectedWard = null;
                        districts.clear();
                        wards.clear();
                      });
                      Navigator.pop(context);
                      _loadDistricts(province.provinceId);
                    },
                    trailing: selectedProvince?.provinceId == province.provinceId
                        ? Icon(Icons.check, color: Colors.blue)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
//hàm chọn Quận Huyện
  void _showDistrictSelector() {
    if (districts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Chọn quận huyện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  final district = districts[index];
                  return ListTile(
                    title: Text(district.districtName),
                    onTap: () {
                      setState(() {
                        selectedDistrict = district;
                        selectedWard = null;
                        wards.clear();
                      });
                      Navigator.pop(context);
                      _loadWards(district.districtId);
                    },
                    trailing: selectedDistrict?.districtId == district.districtId
                        ? Icon(Icons.check, color: Colors.blue)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  //hàm chọn phường xã
  void _showWardSelector() {
    if (wards.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Chọn phường xã',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: wards.length,
                itemBuilder: (context, index) {
                  final ward = wards[index];
                  return ListTile(
                    title: Text(ward.wardName),
                    onTap: () {
                      setState(() {
                        selectedWard = ward;
                      });
                      Navigator.pop(context);
                    },
                    trailing: selectedWard?.wardCode == ward.wardCode
                        ? Icon(Icons.check, color: Colors.blue)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _resetPassword() {
    if (emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập email để reset mật khẩu');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset mật khẩu'),
        content: Text('Gửi email reset mật khẩu đến ${emailController.text.trim()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.resetPassword(emailController.text.trim());
                _showSuccessMessage('Đã gửi email reset mật khẩu');
              } catch (e) {
                _showErrorSnackBar(_getErrorMessage(e.toString()));
              }
            },
            child: Text('Gửi'),
          ),
        ],
      ),
    );
  }
}


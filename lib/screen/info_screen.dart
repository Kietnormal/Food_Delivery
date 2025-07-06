import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/ghn_service.dart';
import '../services/food_service.dart'; // Thêm import cho FoodService
import '../models/user_model.dart' as AppUser;
import '../models/ghn_models.dart';

class PersonalInfoScreen extends StatefulWidget {
  final AppUser.User user;

  const PersonalInfoScreen({Key? key, required this.user}) : super(key: key);

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final AuthService _authService = AuthService();
  final FoodService _foodService = FoodService(); // Thêm FoodService instance
  bool _isLoading = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  bool _isUploadingAvatar = false; // Loading state cho upload avatar

  // Controllers for text fields
  late final TextEditingController nameController;
  late final TextEditingController birthYearController;
  late final TextEditingController specificAddressController;
  late final TextEditingController phoneController;

  // GHN data
  List<Province> provinces = [];
  List<District> districts = [];
  List<Ward> wards = [];

  Province? selectedProvince;
  District? selectedDistrict;
  Ward? selectedWard;

  // Avatar
  XFile? _selectedAvatarFile;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    nameController = TextEditingController(text: widget.user.name);
    birthYearController = TextEditingController(
        text: widget.user.birthYear > 0
            ? widget.user.birthYear.toString()
            : '');
    phoneController = TextEditingController(text: widget.user.phone);

    // Initialize với địa chỉ cụ thể từ địa chỉ hiện tại
    _parseExistingAddress();

    // Load provinces và address details
    _loadProvinces();
    _loadCurrentAddressDetails();
  }

  void _parseExistingAddress() {
    // Tách địa chỉ hiện tại để lấy phần địa chỉ cụ thể
    String fullAddress = widget.user.address;
    List<String> parts = fullAddress.split(', ');

    if (parts.isNotEmpty) {
      specificAddressController = TextEditingController(text: parts[0]);
    } else {
      specificAddressController = TextEditingController(text: fullAddress);
    }
  }

  // Load thông tin địa chỉ chi tiết từ Firebase hoặc từ User model
  Future<void> _loadCurrentAddressDetails() async {
    try {
      // Nếu user model đã có thông tin địa chỉ mở rộng, sử dụng nó
      if (widget.user.provinceId != null) {
        print('PersonalInfoScreen - Loading from user model: Province ${widget
            .user.provinceId}');
        await _loadFromUserModel();
        return;
      }

      // Nếu không, thử load từ Firebase
      final addressDetails = await _authService.getCurrentUserAddressDetails();
      if (addressDetails != null && mounted) {
        print(
            'PersonalInfoScreen - Loaded address details from Firebase: $addressDetails');
        await _loadFromFirebaseData(addressDetails);
      } else {
        print('PersonalInfoScreen - No address details found');
      }
    } catch (e) {
      print('PersonalInfoScreen - Error loading current address details: $e');
    }
  }

  // Load địa chỉ từ user model
  Future<void> _loadFromUserModel() async {
    try {
      // Đợi provinces load xong
      while (_isLoadingProvinces && provinces.isEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      if (widget.user.provinceId != null) {
        final province = provinces.firstWhere(
              (p) => p.provinceId == widget.user.provinceId,
          orElse: () => throw Exception('Province not found'),
        );

        selectedProvince = province;
        print('PersonalInfoScreen - Found province from model: ${province
            .provinceName}');

        // Load districts
        await _loadDistricts(province.provinceId);

        if (widget.user.districtId != null) {
          final district = districts.firstWhere(
                (d) => d.districtId == widget.user.districtId,
            orElse: () => throw Exception('District not found'),
          );

          selectedDistrict = district;
          print('PersonalInfoScreen - Found district from model: ${district
              .districtName}');

          // Load wards
          await _loadWards(district.districtId);

          if (widget.user.wardCode != null) {
            final ward = wards.firstWhere(
                  (w) => w.wardCode == widget.user.wardCode,
              orElse: () => throw Exception('Ward not found'),
            );

            selectedWard = ward;
            print(
                'PersonalInfoScreen - Found ward from model: ${ward.wardName}');
          }
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('PersonalInfoScreen - Error loading from user model: $e');
    }
  }

  // Load địa chỉ từ Firebase data
  Future<void> _loadFromFirebaseData(
      Map<String, dynamic> addressDetails) async {
    try {
      // Đợi provinces load xong
      while (_isLoadingProvinces && provinces.isEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      if (addressDetails['provinceId'] != null) {
        final province = provinces.firstWhere(
              (p) => p.provinceId == addressDetails['provinceId'],
          orElse: () => throw Exception('Province not found'),
        );

        selectedProvince = province;
        print('PersonalInfoScreen - Found province from Firebase: ${province
            .provinceName}');

        // Load districts
        await _loadDistricts(province.provinceId);

        if (addressDetails['districtId'] != null) {
          final district = districts.firstWhere(
                (d) => d.districtId == addressDetails['districtId'],
            orElse: () => throw Exception('District not found'),
          );

          selectedDistrict = district;
          print('PersonalInfoScreen - Found district from Firebase: ${district
              .districtName}');

          // Load wards
          await _loadWards(district.districtId);

          if (addressDetails['wardCode'] != null) {
            final ward = wards.firstWhere(
                  (w) => w.wardCode == addressDetails['wardCode'].toString(),
              orElse: () => throw Exception('Ward not found'),
            );

            selectedWard = ward;
            print('PersonalInfoScreen - Found ward from Firebase: ${ward
                .wardName}');
          }
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('PersonalInfoScreen - Error loading from Firebase data: $e');
    }
  }

  Future<void> _loadProvinces() async {
    if (_isLoadingProvinces) return;

    setState(() => _isLoadingProvinces = true);
    try {
      final loadedProvinces = await GHNService.getProvinces();
      if (mounted) {
        setState(() {
          provinces = loadedProvinces;
          _isLoadingProvinces = false;
        });
        print('PersonalInfoScreen - Loaded ${provinces.length} provinces');
      }
    } catch (e) {
      print('Error loading provinces: $e');
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
        _showSnackBar('Không thể tải danh sách tỉnh thành', isError: true);
      }
    }
  }

  Future<void> _loadDistricts(int provinceId) async {
    if (_isLoadingDistricts) return;

    setState(() {
      _isLoadingDistricts = true;
      districts.clear();
      wards.clear();
    });

    try {
      final loadedDistricts = await GHNService.getDistricts(provinceId);
      if (mounted) {
        setState(() {
          districts = loadedDistricts;
          _isLoadingDistricts = false;
        });
        print('PersonalInfoScreen - Loaded ${districts
            .length} districts for province $provinceId');
      }
    } catch (e) {
      print('Error loading districts: $e');
      if (mounted) {
        setState(() => _isLoadingDistricts = false);
        _showSnackBar('Không thể tải danh sách quận huyện', isError: true);
      }
    }
  }

  Future<void> _loadWards(int districtId) async {
    if (_isLoadingWards) return;

    setState(() {
      _isLoadingWards = true;
      wards.clear();
    });

    try {
      final loadedWards = await GHNService.getWards(districtId);
      if (mounted) {
        setState(() {
          wards = loadedWards;
          _isLoadingWards = false;
        });
        print('PersonalInfoScreen - Loaded ${wards
            .length} wards for district $districtId');
      }
    } catch (e) {
      print('Error loading wards: $e');
      if (mounted) {
        setState(() => _isLoadingWards = false);
        _showSnackBar('Không thể tải danh sách phường xã', isError: true);
      }
    }
  }

  String _buildFullAddress() {
    List<String> addressParts = [];

    if (specificAddressController.text
        .trim()
        .isNotEmpty) {
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

  // Thêm method để chọn avatar
  Future<void> _pickAvatar() async {
    try {
      final XFile? pickedFile = await _foodService.pickImage();
      if (pickedFile != null) {
        setState(() {
          _selectedAvatarFile = pickedFile;
        });
        print('PersonalInfoScreen - Avatar selected: ${pickedFile.path}');
      }
    } catch (e) {
      print('PersonalInfoScreen - Error picking avatar: $e');
      _showSnackBar('Không thể chọn ảnh: ${e.toString()}', isError: true);
    }
  }

  // Thêm method để upload avatar
  Future<String?> _uploadAvatar() async {
    if (_selectedAvatarFile == null) return null;

    try {
      setState(() => _isUploadingAvatar = true);

      print('PersonalInfoScreen - Uploading avatar...');
      final avatarUrl = await _foodService.uploadImageToSupabase(
          _selectedAvatarFile!, 'avatars');

      print('PersonalInfoScreen - Avatar uploaded successfully: $avatarUrl');
      return avatarUrl;
    } catch (e) {
      print('PersonalInfoScreen - Error uploading avatar: $e');
      _showSnackBar(
          'Không thể tải lên ảnh đại diện: ${e.toString()}', isError: true);
      return null;
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  // Method để xóa avatar cũ từ Supabase (nếu cần)
  Future<void> _deleteOldAvatar(String oldAvatarUrl) async {
    try {
      if (oldAvatarUrl.isNotEmpty && oldAvatarUrl.contains('supabase')) {
        await _foodService.deleteImageFromSupabase(oldAvatarUrl);
        print('PersonalInfoScreen - Old avatar deleted successfully');
      }
    } catch (e) {
      print('PersonalInfoScreen - Error deleting old avatar: $e');
      // Không throw error vì việc xóa ảnh cũ không quan trọng lắm
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    birthYearController.dispose();
    specificAddressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông tin cá nhân',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info card với avatar có thể thay đổi
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar với nút thay đổi
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _getAvatarImageProvider(),
                          child: _getAvatarImageProvider() == null
                              ? Icon(Icons.person, color: Colors.grey[600],
                              size: 50)
                              : null,
                        ),
                        // Loading overlay khi đang upload
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        // Nút chỉnh sửa avatar
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar ? null : _pickAvatar,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF5DADE2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: ${widget.user.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    // Hiển thị trạng thái avatar đã chọn
                    if (_selectedAvatarFile != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600],
                                  size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Đã chọn ảnh mới',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Editable fields
              _buildEditableField('Tên đầy đủ', nameController,
                  TextInputType.text, Icons.person_outline),
              SizedBox(height: 16),
              _buildEditableField('Số điện thoại', phoneController,
                  TextInputType.phone, Icons.phone_outlined),
              SizedBox(height: 16),
              _buildEditableField('Năm sinh', birthYearController,
                  TextInputType.number, Icons.cake_outlined),
              SizedBox(height: 16),

              // Address section
              Text(
                'Địa chỉ',
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.black),
              ),
              SizedBox(height: 8),

              // Dropdown chọn tỉnh thành
              _buildDropdownField(
                'Tỉnh thành',
                selectedProvince?.provinceName ?? 'Chọn tỉnh thành',
                _isLoadingProvinces,
                    () => _showProvinceSelector(),
              ),
              SizedBox(height: 12),

              // Dropdown chọn quận huyện
              _buildDropdownField(
                'Quận huyện',
                selectedDistrict?.districtName ?? 'Chọn quận huyện',
                _isLoadingDistricts,
                selectedProvince != null ? () => _showDistrictSelector() : null,
              ),
              SizedBox(height: 12),

              // Dropdown chọn phường xã
              _buildDropdownField(
                'Phường xã',
                selectedWard?.wardName ?? 'Chọn phường xã',
                _isLoadingWards,
                selectedDistrict != null ? () => _showWardSelector() : null,
              ),
              SizedBox(height: 12),

              _buildEditableField('Địa chỉ cụ thể', specificAddressController,
                  TextInputType.text, Icons.location_on_outlined),

              SizedBox(height: 20),

              // Current full address preview
              if (selectedProvince != null ||
                  selectedDistrict != null ||
                  selectedWard != null ||
                  specificAddressController.text.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Địa chỉ đầy đủ:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _buildFullAddress().isNotEmpty
                            ? _buildFullAddress()
                            : 'Chưa có thông tin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),

              // Account info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    _buildReadOnlyInfo(
                        'Ngày tạo', _formatDate(widget.user.createdAt)),
                    _buildReadOnlyInfo(
                        'Cập nhật', _formatDate(widget.user.updatedAt)),
                    _buildReadOnlyInfo('Trạng thái',
                        widget.user.isActive ? 'Hoạt động' : 'Vô hiệu'),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _isUploadingAvatar
                      ? null
                      : _updateUserInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5DADE2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: _isLoading || _isUploadingAvatar ? 0 : 2,
                  ),
                  child: _isLoading || _isUploadingAvatar
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
                      Icon(Icons.save_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Cập nhật thông tin',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }

  // Helper method để lấy ImageProvider cho avatar
  ImageProvider? _getAvatarImageProvider() {
    if (_selectedAvatarFile != null) {
      return FileImage(File(_selectedAvatarFile!.path));
    } else if (widget.user.avatar.isNotEmpty) {
      return NetworkImage(widget.user.avatar);
    }
    return null;
  }

  // Editable input field with icon
  Widget _buildEditableField(String label, TextEditingController controller,
      TextInputType keyboardType, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              hintText: 'Nhập $label',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, bool isLoading,
      VoidCallback? onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: onTap != null ? Colors.white : Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[600],
                  size: 20),
              SizedBox(width: 12),
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
              else
                if (onTap != null)
                  Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showProvinceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.7,
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
                        trailing: selectedProvince?.provinceId ==
                            province.provinceId
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

  void _showDistrictSelector() {
    if (districts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.7,
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
                        trailing: selectedDistrict?.districtId ==
                            district.districtId
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

  void _showWardSelector() {
    if (wards.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.7,
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

  Widget _buildReadOnlyInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
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
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
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

// Handle update button press với upload avatar - FIXED VERSION
  Future<void> _updateUserInfo() async {
    // Validate inputs
    if (nameController.text
        .trim()
        .isEmpty) {
      _showSnackBar('Vui lòng nhập tên', isError: true);
      return;
    }

    if (phoneController.text
        .trim()
        .isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại', isError: true);
      return;
    }

    if (birthYearController.text
        .trim()
        .isEmpty) {
      _showSnackBar('Vui lòng nhập năm sinh', isError: true);
      return;
    }

    if (specificAddressController.text
        .trim()
        .isEmpty) {
      _showSnackBar('Vui lòng nhập địa chỉ cụ thể', isError: true);
      return;
    }

    // Validate birth year
    int birthYear;
    try {
      birthYear = int.parse(birthYearController.text.trim());
      int currentYear = DateTime
          .now()
          .year;
      if (birthYear < 1900 || birthYear > currentYear - 5) {
        _showSnackBar(
            'Năm sinh không hợp lệ (1900 - ${currentYear - 5})', isError: true);
        return;
      }
    } catch (e) {
      _showSnackBar('Năm sinh phải là số', isError: true);
      return;
    }

    // Validate phone number - FIX: Thêm $ và sửa lỗi ngoặc
    String phone = phoneController.text.trim();
    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(phone) || phone.length < 9) {
      _showSnackBar('Số điện thoại không hợp lệ', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('PersonalInfoScreen - Updating user info...');

      String avatarUrl = widget.user.avatar; // Giữ avatar cũ mặc định

      // Upload avatar mới nếu có
      if (_selectedAvatarFile != null) {
        print('PersonalInfoScreen - Uploading new avatar...');
        final uploadedAvatarUrl = await _uploadAvatar();

        if (uploadedAvatarUrl != null) {
          // Xóa avatar cũ nếu cần (chỉ xóa nếu là ảnh từ Supabase)
          if (widget.user.avatar.isNotEmpty &&
              widget.user.avatar.contains('supabase')) {
            await _deleteOldAvatar(widget.user.avatar);
          }

          avatarUrl = uploadedAvatarUrl;
          _newAvatarUrl = uploadedAvatarUrl;
          print('PersonalInfoScreen - New avatar URL: $avatarUrl');
        } else {
          _showSnackBar(
              'Không thể tải lên ảnh đại diện, tiếp tục cập nhật thông tin khác',
              isError: false);
        }
      }

      // Build full address từ các thành phần đã chọn
      String fullAddress = _buildFullAddress();
      if (fullAddress.isEmpty) {
        fullAddress = specificAddressController.text.trim();
      }

      // Cập nhật thông tin cơ bản của user với địa chỉ mở rộng và avatar mới
      AppUser.User updatedUser = widget.user.copyWith(
        name: nameController.text.trim(),
        phone: phone,
        birthYear: birthYear,
        address: fullAddress,
        avatar: avatarUrl,
        // Cập nhật avatar
        provinceId: selectedProvince?.provinceId,
        districtId: selectedDistrict?.districtId,
        wardCode: selectedWard?.wardCode,
      );

      print('PersonalInfoScreen - Updated user: ${updatedUser.name}');
      print('PersonalInfoScreen - Full address: $fullAddress');
      print('PersonalInfoScreen - Avatar URL: $avatarUrl');

      // Cập nhật user data với đầy đủ thông tin địa chỉ và avatar
      bool success = await _authService.updateUserData(updatedUser);

      if (success) {
        _showSuccessMessage('Cập nhật thông tin thành công!');

        // Reset selected avatar file
        setState(() {
          _selectedAvatarFile = null;
        });

        // Wait a bit then return to previous screen with success flag
        await Future.delayed(Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pop(
              context, true); // Return true to indicate successful update
        }
      } else {
        _showSnackBar(
            'Không thể cập nhật thông tin. Vui lòng thử lại', isError: true);
      }
    } catch (e) {
      print('PersonalInfoScreen - Update user info error: $e');
      _showSnackBar('Có lỗi xảy ra: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.red[600] : Colors.blue[600],
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

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
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}
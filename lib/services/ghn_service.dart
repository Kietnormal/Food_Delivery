// services/ghn_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
//thêm khi merga branch
// import '../models/caculator_ship_model.dart';
// import '../models/ghn_models.dart';
// import '../models/shipping_item_model.dart';

class GHNService {
  static const String _baseUrl = 'https://online-gateway.ghn.vn/shiip/public-api';
  static const String _token = 'c758d242-3d03-11f0-9137-b60a6f96c145';
  static const int _shopId = 5807628;
  static const Map<String, String> _headers = {
    'Token': _token,
    'Content-Type': 'application/json',
  };
  static const int _fromDistrictId = 1462; // District ID của shop
  static const String _fromWardCode = "21617"; // Ward code của shop
  static const int _defaultServiceId = 100039; // Service ID mặc định (đã sửa từ 53319)

  // Tính phí ship dựa vào địa chỉ giao hàng
  static Future<ShippingFeeResult> calculateShippingFee({
    required int toDistrictId,
    required String toWardCode,
    int? serviceId,
    int? weight, // gram
    int? height, // cm
    int? length, // cm
    int? width, // cm
    int? insuranceValue, // VND
    int? codFailedAmount, // VND - thêm parameter này
    List<ShippingItem>? items,
  }) async {
    try {
      // Sửa URL để sử dụng API v2
      final url = Uri.parse('$_baseUrl/v2/shipping-order/fee');

      // Tính tổng weight từ items nếu không có weight cụ thể
      int totalWeight = weight ?? 200; // default 200g
      if (items != null && items.isNotEmpty) {
        totalWeight = items.fold(0, (sum, item) => sum + (item.weight * item.quantity));
      }

      final requestBody = {
        "from_district_id": _fromDistrictId,
        "from_ward_code": _fromWardCode,
        "service_id": serviceId ?? _defaultServiceId,
        "service_type_id": null,
        "to_district_id": toDistrictId,
        "to_ward_code": toWardCode,
        "height": height ?? 50,
        "length": length ?? 20,
        "weight": totalWeight,
        "width": width ?? 20,
        "insurance_value": insuranceValue ?? 0,
        "cod_failed_amount": codFailedAmount ?? 0, // Sử dụng parameter
        "coupon": null,
      };

      // Thêm items nếu có
      if (items != null && items.isNotEmpty) {
        requestBody["items"] = items.map((item) => item.toJson()).toList();
      }

      print('GHNShippingService - Request URL: $url');
      print('GHNShippingService - Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Token': _token,
          'ShopId': _shopId.toString(),
        },
        body: jsonEncode(requestBody),
      );

      print('GHNShippingService - Response status: ${response.statusCode}');
      print('GHNShippingService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['code'] == 200) {
          return ShippingFeeResult.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'API error');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('GHNShippingService - Error: $e');
      throw Exception('Không thể tính phí ship: $e');
    }
  }

  // Lấy danh sách tỉnh thành
  static Future<List<Province>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/master-data/province'),
        headers: _headers,
      );

      print('GHN Province Response: ${response.statusCode}');
      print('GHN Province Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> provinceList = data['data'];
          return provinceList.map((json) => Province.fromJson(json)).toList();
        } else {
          throw Exception('GHN API Error: ${data['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting provinces: $e');
      throw Exception('Không thể tải danh sách tỉnh thành: $e');
    }
  }

  // Lấy danh sách quận huyện theo tỉnh
  static Future<List<District>> getDistricts(int provinceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/master-data/district'),
        headers: _headers,
        body: json.encode({'province_id': provinceId}),
      );

      print('GHN District Response: ${response.statusCode}');
      print('GHN District Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> districtList = data['data'];
          return districtList.map((json) => District.fromJson(json)).toList();
        } else {
          throw Exception('GHN API Error: ${data['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting districts: $e');
      throw Exception('Không thể tải danh sách quận huyện: $e');
    }
  }

  // Lấy danh sách phường xã theo quận huyện
  static Future<List<Ward>> getWards(int districtId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/master-data/ward'),
        headers: _headers,
        body: json.encode({'district_id': districtId}),
      );

      print('GHN Ward Response: ${response.statusCode}');
      print('GHN Ward Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> wardList = data['data'];
          return wardList.map((json) => Ward.fromJson(json)).toList();
        } else {
          throw Exception('GHN API Error: ${data['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting wards: $e');
      throw Exception('Không thể tải danh sách phường xã: $e');
    }
  }

  // Hàm helper để test với data giống Postman
  static Future<ShippingFeeResult> testCalculateShippingFee() async {
    final testItems = [
      ShippingItem(
        name: "TEST1",
        quantity: 1,
        height: 200,
        weight: 200,
        length: 200,
        width: 200,
      )
    ];

    return await calculateShippingFee(
      toDistrictId: 1452,
      toWardCode: "21012",
      serviceId: 53320,
      weight: 200,
      height: 50,
      length: 20,
      width: 20,
      insuranceValue: 10000,
      codFailedAmount: 2000,
      items: testItems,
    );
  }
}
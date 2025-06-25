// models/ghn_models.dart
class Province {
  final int provinceId;
  final String provinceName;
  final String code;

  Province({
    required this.provinceId,
    required this.provinceName,
    required this.code,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      provinceId: json['ProvinceID'],
      provinceName: json['ProvinceName'],
      code: json['Code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProvinceID': provinceId,
      'ProvinceName': provinceName,
      'Code': code,
    };
  }

  @override
  String toString() => provinceName;
}

class District {
  final int districtId;
  final int provinceId;
  final String districtName;
  final String code;
  final int type;
  final int supportType;

  District({
    required this.districtId,
    required this.provinceId,
    required this.districtName,
    required this.code,
    required this.type,
    required this.supportType,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      districtId: json['DistrictID'],
      provinceId: json['ProvinceID'],
      districtName: json['DistrictName'],
      code: json['Code'],
      type: json['Type'],
      supportType: json['SupportType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DistrictID': districtId,
      'ProvinceID': provinceId,
      'DistrictName': districtName,
      'Code': code,
      'Type': type,
      'SupportType': supportType,
    };
  }

  @override
  String toString() => districtName;
}

class Ward {
  final String wardCode;
  final int districtId;
  final String wardName;

  Ward({
    required this.wardCode,
    required this.districtId,
    required this.wardName,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      wardCode: json['WardCode'].toString(),
      districtId: json['DistrictID'],
      wardName: json['WardName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'WardCode': wardCode,
      'DistrictID': districtId,
      'WardName': wardName,
    };
  }

  @override
  String toString() => wardName;
}
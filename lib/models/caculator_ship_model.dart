class ShippingFeeResult {
  final int total;
  final int serviceFee;
  final int insuranceFee;
  final int pickStationFee;
  final int couponValue;
  final int r2sFee;
  final int documentReturn;
  final int doubleCheck;
  final int codFee;
  final int pickRemoteAreasFee;
  final int deliverRemoteAreasFee;
  final int codFailedFee;

  ShippingFeeResult({
    required this.total,
    required this.serviceFee,
    required this.insuranceFee,
    required this.pickStationFee,
    required this.couponValue,
    required this.r2sFee,
    required this.documentReturn,
    required this.doubleCheck,
    required this.codFee,
    required this.pickRemoteAreasFee,
    required this.deliverRemoteAreasFee,
    required this.codFailedFee,
  });

  factory ShippingFeeResult.fromJson(Map<String, dynamic> json) {
    return ShippingFeeResult(
      total: json['total'] ?? 0,
      serviceFee: json['service_fee'] ?? 0,
      insuranceFee: json['insurance_fee'] ?? 0,
      pickStationFee: json['pick_station_fee'] ?? 0,
      couponValue: json['coupon_value'] ?? 0,
      r2sFee: json['r2s_fee'] ?? 0,
      documentReturn: json['document_return'] ?? 0,
      doubleCheck: json['double_check'] ?? 0,
      codFee: json['cod_fee'] ?? 0,
      pickRemoteAreasFee: json['pick_remote_areas_fee'] ?? 0,
      deliverRemoteAreasFee: json['deliver_remote_areas_fee'] ?? 0,
      codFailedFee: json['cod_failed_fee'] ?? 0,
    );
  }
}
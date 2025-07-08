class RedeemRewardResponse {
  final bool success;
  final String message;
  final String couponCode;
  final double discountPercentage;
  final DateTime expirationDate;

  RedeemRewardResponse({
    required this.success,
    required this.message,
    required this.couponCode,
    required this.discountPercentage,
    required this.expirationDate,
  });

  factory RedeemRewardResponse.fromJson(Map<String, dynamic> json) {
    return RedeemRewardResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      couponCode: json['couponCode'] as String,
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      expirationDate: DateTime.parse(json['expirationDate'] as String),
    );
  }
}
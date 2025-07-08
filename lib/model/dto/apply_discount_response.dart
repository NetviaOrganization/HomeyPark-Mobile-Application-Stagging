class ApplyDiscountResponse {
  final bool success;
  final String message;
  final double originalPrice;
  final double discountAmount;
  final double finalPrice;
  final String appliedCoupon;

  ApplyDiscountResponse({
    required this.success,
    required this.message,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.appliedCoupon,
  });

  factory ApplyDiscountResponse.fromJson(Map<String, dynamic> json) {
    return ApplyDiscountResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      appliedCoupon: json['appliedCoupon'] as String,
    );
  }
}
class RedeemRewardRequest {
  final String rewardId;
  final String rewardType;

  RedeemRewardRequest({
    required this.rewardId,
    required this.rewardType,
  });

  Map<String, dynamic> toJson() {
    return {
      'rewardId': rewardId,
      'rewardType': rewardType,
    };
  }
}

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

class ApplyDiscountRequest {
  final String couponCode;
  final String discountType;

  ApplyDiscountRequest({
    required this.couponCode,
    required this.discountType,
  });

  Map<String, dynamic> toJson() {
    return {
      'couponCode': couponCode,
      'discountType': discountType,
    };
  }
}

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
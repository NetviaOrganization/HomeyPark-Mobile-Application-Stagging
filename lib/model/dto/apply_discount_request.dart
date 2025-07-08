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
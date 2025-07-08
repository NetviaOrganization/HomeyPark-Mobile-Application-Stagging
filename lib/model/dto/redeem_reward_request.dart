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
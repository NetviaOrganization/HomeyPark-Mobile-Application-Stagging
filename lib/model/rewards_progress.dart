class RewardsProgress {
  final int userId;
  final int completedReservations;
  final int reservationsRequired;
  final int reservationsRemaining;
  final double progressPercentage;
  final bool isEligibleForReward;
  final String nextRewardType;
  final double nextRewardValue;

  RewardsProgress({
    required this.userId,
    required this.completedReservations,
    required this.reservationsRequired,
    required this.reservationsRemaining,
    required this.progressPercentage,
    required this.isEligibleForReward,
    required this.nextRewardType,
    required this.nextRewardValue,
  });

  factory RewardsProgress.fromJson(Map<String, dynamic> json) {
    return RewardsProgress(
      userId: json['userId'] as int,
      completedReservations: json['completedReservations'] as int,
      reservationsRequired: json['reservationsRequired'] as int,
      reservationsRemaining: json['reservationsRemaining'] as int,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      isEligibleForReward: json['isEligibleForReward'] as bool,
      nextRewardType: json['nextRewardType'] as String,
      nextRewardValue: (json['nextRewardValue'] as num).toDouble(),
    );
  }
}
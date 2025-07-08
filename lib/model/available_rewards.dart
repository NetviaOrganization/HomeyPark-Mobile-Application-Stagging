import 'reward.dart';

class AvailableRewards {
  final List<Reward> availableRewards;
  final bool hasActiveRewards;

  AvailableRewards({
    required this.availableRewards,
    required this.hasActiveRewards,
  });

  factory AvailableRewards.fromJson(Map<String, dynamic> json) {
    var rewardsList = json['availableRewards'] as List;
    List<Reward> rewards = rewardsList.map((i) => Reward.fromJson(i)).toList();

    return AvailableRewards(
      availableRewards: rewards,
      hasActiveRewards: json['hasActiveRewards'] as bool,
    );
  }
}
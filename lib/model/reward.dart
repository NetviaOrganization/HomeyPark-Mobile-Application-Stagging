class Reward {
  final String id;
  final String type;
  final double value;
  final String description;
  final DateTime expirationDate;
  final bool isActive;

  Reward({
    required this.id,
    required this.type,
    required this.value,
    required this.description,
    required this.expirationDate,
    required this.isActive,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      description: json['description'] as String,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'description': description,
      'expirationDate': expirationDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
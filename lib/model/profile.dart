class Profile {
  final int? id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final int userId;
  final bool verifiedEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.userId,
    required this.verifiedEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: DateTime.parse(json['birthDate']),
      userId: json['userId'],
      verifiedEmail: json['verifiedEmail'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String().split('T')[0], // formato yyyy-MM-dd
      'userId': userId,
      'verifiedEmail': verifiedEmail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    int? userId,
    bool? verifiedEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      userId: userId ?? this.userId,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

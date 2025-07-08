class UserInfo {
  final int userId;
  final String email;
  final bool verifiedEmail;

  UserInfo({
    required this.userId,
    required this.email,
    required this.verifiedEmail,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'],
      email: json['email'],
      verifiedEmail: json['verifiedEmail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'verifiedEmail': verifiedEmail,
    };
  }

  @override
  String toString() {
    return 'UserInfo{userId: $userId, email: $email, verifiedEmail: $verifiedEmail}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserInfo && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
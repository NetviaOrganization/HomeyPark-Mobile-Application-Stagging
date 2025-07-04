class Vehicle {
  final int id;
  final String licensePlate;
  final String model;
  final String brand;
  final int profileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int year;
  final String color;
  
  Vehicle({
    required this.id,
    required this.licensePlate,
    required this.model,
    required this.brand,
    required this.profileId,
    required this.createdAt,
    required this.updatedAt,
    required this.year,
    required this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      licensePlate: json['licensePlate'],
      model: json['model'],
      brand: json['brand'],
      profileId: (json['profileId'] is String) ? int.parse(json['profileId']) : json['profileId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      year: json['year'] ?? 0, 
      color: json['color'] ?? 'No especificado', 
    );
  }
}
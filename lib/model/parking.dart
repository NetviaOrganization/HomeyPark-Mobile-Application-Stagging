import 'package:homeypark_mobile_application/model/parking_location.dart';
import 'package:homeypark_mobile_application/model/parking_schedule.dart';

class Parking {
  final int id;
  final int profileId;
  final double width;
  final double length;
  final double height;
  final double price;
  final String phone;
  final int space;
  final String description;
  final ParkingLocation location;
  final List<ParkingSchedule> schedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  Parking({
    required this.id,
    required this.profileId,
    required this.width,
    required this.length,
    required this.height,
    required this.price,
    required this.phone,
    required this.space,
    required this.description,
    required this.location,
    required this.schedules,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'],
      profileId: json['profileId'],
      width: json['width'],
      length: json['length'],
      height: json['height'],
      price: json['price'],
      phone: json['phone'],
      space: json['space'],
      description: json['description'],
      location: ParkingLocation.fromJson(json['location']),
      schedules: (json['schedules'] as List)
          .map((schedule) => ParkingSchedule.fromJson(schedule))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'width': width,
      'length': length,
      'height': height,
      'price': price,
      'phone': phone,
      'space': space,
      'description': description,
      'location': location.toJson(),
      'schedules': schedules.map((schedule) => schedule.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
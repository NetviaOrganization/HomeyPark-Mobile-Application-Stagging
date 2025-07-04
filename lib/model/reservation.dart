import 'package:homeypark_mobile_application/model/reservation_status.dart';

class Reservation {
  int id;
  int hoursRegistered;
  double totalFare;
  DateTime reservationDate;
  Time startTime;
  Time endTime;
  ReservationStatus status;
  int guestId;
  int hostId;
  int parkingId;
  int vehicleId;
  String paymentReceiptUrl;
  String paymentReceiptDeleteUrl;
  DateTime createdAt;    // Campo nuevo
  DateTime updatedAt;    // Campo nuevo

  Reservation({
    required this.id,
    required this.hoursRegistered,
    required this.totalFare,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.guestId,
    required this.hostId,
    required this.parkingId,
    required this.vehicleId,
    required this.paymentReceiptUrl,
    required this.paymentReceiptDeleteUrl,
    required this.createdAt,    // Parámetro nuevo
    required this.updatedAt,    // Parámetro nuevo
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      hoursRegistered: json['hoursRegistered'],
      totalFare: (json['totalFare'] ?? 0.0).toDouble(), // Validar nulo
      reservationDate: DateTime.parse(json['reservationDate']),
      startTime: Time.fromJson(json['startTime']),
      endTime: Time.fromJson(json['endTime']),
      status: statusFromJson(json['status']),
      guestId: json['guestId'],
      hostId: json['hostId'],
      parkingId: json['parkingId'],
      vehicleId: json['vehicleId'],
      paymentReceiptUrl: json['paymentReceiptUrl'] ?? '', // Validar nulo
      paymentReceiptDeleteUrl: json['paymentReceiptDeleteUrl'] ?? '', // Validar nulo
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Computed getters
  DateTime get startDateTime => startTime.toDateTime();
  DateTime get endDateTime => endTime.toDateTime();
}

// La clase Time se mantiene igual
class Time {
  int hour;
  int minute;
  int second;
  int nano;

  Time({
    required this.hour,
    required this.minute,
    required this.second,
    required this.nano,
  });

  factory Time.fromJson(dynamic json) {
    if (json is String) {
      // Formato "HH:MM:SS" del backend
      List<String> parts = json.split(':');
      return Time(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        second: parts.length > 2 ? int.parse(parts[2]) : 0, // Agregar validación
        nano: 0,
      );
    } else if (json is Map<String, dynamic>) {
      // Formato objeto del backend
      return Time(
        hour: json['hour'] ?? 0,
        minute: json['minute'] ?? 0,
        second: json['second'] ?? 0,
        nano: json['nano'] ?? 0,
      );
    } else {
      throw ArgumentError('Formato de tiempo inválido: $json');
    }
  }

  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute, second, nano ~/ 1000000);
  }
}
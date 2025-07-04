class ReservationDto {
  final int hoursRegistered;
  final double totalFare;
  final String reservationDate; // "YYYY-MM-DD"
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final int guestId;
  final int hostId;
  final int parkingId;
  final int vehicleId;

  ReservationDto({
    required this.hoursRegistered,
    required this.totalFare,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.guestId,
    required this.hostId,
    required this.parkingId,
    required this.vehicleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'hoursRegistered': hoursRegistered,
      'totalFare': totalFare,
      'reservationDate': reservationDate,
      'startTime': startTime,
      'endTime': endTime,
      'guestId': guestId,
      'hostId': hostId,
      'parkingId': parkingId,
      'vehicleId': vehicleId,
    };
  }
}
class ParkingSchedule {
  final int? id;
  final String day;
  final String startTime;
  final String endTime;

  ParkingSchedule({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory ParkingSchedule.fromJson(Map<String, dynamic> json) {
    return ParkingSchedule(
      id: json['id'],
      day: json['day'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
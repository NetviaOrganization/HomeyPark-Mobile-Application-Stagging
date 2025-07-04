import 'package:flutter/cupertino.dart';

enum ReservationStatus {
  cancelled,
  inProgress,
  approved,
  pending,
  completed,
}

String statusText(ReservationStatus status) {
  const Map<ReservationStatus, String> statusText = {
    ReservationStatus.cancelled: "Cancelada",
    ReservationStatus.inProgress: "En progreso",
    ReservationStatus.approved: "Aprobada",
    ReservationStatus.pending: "Pendiente",
    ReservationStatus.completed: "Completada",
  };

  return statusText[status]!;
}

ReservationStatus statusFromJson(String status) {
  const Map<String, ReservationStatus> statusMap = {
    "Cancelled": ReservationStatus.cancelled,
    "InProgress": ReservationStatus.inProgress,
    "Approved": ReservationStatus.approved,
    "Confirmed": ReservationStatus.approved,
    "Pending": ReservationStatus.pending,
    "Completed": ReservationStatus.completed,
  };

  final result = statusMap[status];
  if (result == null) {
    debugPrint('⚡️ WARNING: Status desconocido recibido del backend: $status');
    return ReservationStatus.pending; // Valor por defecto
  }
  return result;
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:homeypark_mobile_application/model/reservation.dart';
import 'package:homeypark_mobile_application/model/reservation_dto.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:flutter/foundation.dart';

class ReservationService {
  static final String baseUrl = '${BaseService.baseUrl}/reservations';

  static Future<Reservation> getReservationById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      dynamic body = jsonDecode(response.body);
      return Reservation.fromJson(body);
    } else {
      throw Exception('Failed to load reservation');
    }
  }

  static Future<List<Reservation>> getReservationsByHostId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/host/$id'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      print("DEBUG");
      print(body);
      var reservations =
      body.map((dynamic item) => Reservation.fromJson(item)).toList();
      return reservations;
    } else {
      return [];
    }
  }

  static Future<List<Reservation>> getReservationsByGuestId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/guest/$id'));

    if (response.statusCode == 200) {
      debugPrint("⚡️DEBUG - Respuesta original:");
      debugPrint(response.body);

      List<dynamic> body = jsonDecode(response.body);

      debugPrint("⚡️DEBUG - Lista deserializada:");
      debugPrint(body.toString());

      var reservations = <Reservation>[];

      for (var item in body) {
        try {
          reservations.add(Reservation.fromJson(item));
        } catch (e) {
          debugPrint("⚡️ERROR procesando reservación: $e");
        }
      }

      return reservations;
    } else {
      debugPrint("⚡️ERROR: Request falló con estado: ${response.statusCode}");
      debugPrint("⚡️ERROR: Respuesta: ${response.body}");
      return [];
    }
  }

  static Future<Reservation> createReservation({
    required int userId,
    required int parkingId,
    required DateTime startTime,
    required DateTime endTime,
    required String carModel,
    required String licensePlate,
    required double totalPrice,
    File? paymentProof,
  }) async {
    try {
      // 1. Crear el vehículo primero
      final vehicleData = {
        'model': carModel,
        'licensePlate': licensePlate,
        'profileId': userId,
      };

      final vehicleResponse = await http.post(
        Uri.parse('${BaseService.baseUrl}/vehicles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicleData),
      );

      if (vehicleResponse.statusCode != 200 && vehicleResponse.statusCode != 201) {
        throw Exception('Error al crear el vehículo: ${vehicleResponse.body}');
      }

      final vehicleJson = jsonDecode(vehicleResponse.body);
      final vehicleId = vehicleJson['id'];

      // 2. Obtener información del parking para el hostId
      final parkingResponse = await http.get(
        Uri.parse('${BaseService.baseUrl}/parkings/$parkingId'),
      );

      if (parkingResponse.statusCode != 200) {
        throw Exception('Error al obtener información del parking');
      }

      final parkingJson = jsonDecode(parkingResponse.body);
      final hostId = parkingJson['profileId'];

      // 3. Calcular horas y preparar datos de reserva
      final duration = endTime.difference(startTime);
      final hoursRegistered = (duration.inMinutes / 60.0).ceil();

      final reservationData = {
        "hoursRegistered": hoursRegistered,
        "totalFare": totalPrice,
        "reservationDate": "${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}",
        "startTime": "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00", // ← AGREGAR :00
        "endTime": "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00", // ← AGREGAR :00
        "guestId": userId,
        "hostId": hostId,
        "parkingId": parkingId,
        "vehicleId": vehicleId
      };

      // 4. Crear la reserva usando multipart/form-data
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['reservation'] = jsonEncode(reservationData);

      if (paymentProof != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', paymentProof.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('⚡️ Reservation Response Status: ${response.statusCode}');
      debugPrint('⚡️ Reservation Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Reservation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear la reserva: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚡️ Error completo en createReservation: $e');
      throw Exception('Error en createReservation: $e');
    }
  }

  static Future<List<Reservation>> getUpcomingReservations() async {
    final response = await http.get(Uri.parse('$baseUrl/upComing'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load upcoming reservations');
    }
  }

  static Future<List<Reservation>> getPastReservations() async {
    final response = await http.get(Uri.parse('$baseUrl/past'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load past reservations');
    }
  }

  static Future<List<Reservation>> getInProgressReservations() async {
    final response = await http.get(Uri.parse('$baseUrl/inProgress'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load in progress reservations');
    }
  }

  static Future<List<Reservation>> getHostReservations(int hostId) async {
    final response = await http.get(Uri.parse('$baseUrl/host/$hostId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load host reservations');
    }
  }

  static Future<void> updateReservationStatus(int id, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update reservation status');
    }
  }

  static Future<void> cancelReservation(int reservationId) async {
    // CAMBIAR DE DELETE A PUT con status
    final response = await http.put(
      Uri.parse('$baseUrl/$reservationId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": "Cancelled"}), // ← Usar "Cancelled" con mayúscula
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel reservation: ${response.body}');
    }
  }

  static Future<void> approveReservation(int reservationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$reservationId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": "approved"}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve reservation');
    }
  }

  static Future<void> startServiceReservation(int reservationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$reservationId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": "inProgress"}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to start service for reservation');
    }
  }

  static Future<void> completeReservation(int reservationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$reservationId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": "completed"}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to complete reservation');
    }
  }
}
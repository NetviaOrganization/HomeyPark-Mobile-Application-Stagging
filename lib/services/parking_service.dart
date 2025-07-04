import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/model/parking_location.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:http/http.dart' as http;

class ParkingService extends BaseService {
  static final String baseUrl = "${BaseService.baseUrl}/parking";
  static final _storage = const FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'session_token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<Parking>> getParkings() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Parking.fromJson(item)).toList();
    } else {
      debugPrint("Error getParkings: ${response.statusCode}");
      return [];
    }
  }

  static Future<List<Parking>> getNearbyParkings(double lat, double lng) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/nearby?lat=$lat&lng=$lng"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Parking.fromJson(item)).toList();
    } else {
      debugPrint("Error getNearbyParkings: ${response.statusCode}");
      return [];
    }
  }

  static Future<List<ParkingLocation>> getParkingsLocations() async {
    debugPrint('⚡️ ParkingService: Llamando a getParkingsLocations()');
    try {
      final parkings = await getParkings();
      debugPrint('⚡️ Parkings obtenidos: ${parkings.length}');

      if (parkings.isEmpty) return [];

      List<ParkingLocation> locations = [];
      for (var parking in parkings) {
        if (parking.location != null) {
          locations.add(parking.location);
        } else {
          debugPrint('❌ Parking sin ubicación: ${parking.id}');
        }
      }

      debugPrint('✅ Ubicaciones extraídas: ${locations.length}');
      return locations;
    } catch (e) {
      debugPrint('❌ Excepción en getParkingsLocations: $e');
      return [];
    }
  }

  static Future<List<Parking>> getParkingListByUserId(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Parking.fromJson(item)).toList();
    } else {
      debugPrint("Error getParkingListByUserId: ${response.statusCode}");
      return [];
    }
  }

  static Future<Parking> getParkingById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$id/details'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Parking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load parking: ${response.statusCode}');
    }
  }

  static Future<Parking> createParking({
    required int profileId,
    required double width,
    required double length,
    required double height,
    required double price,
    String phone = '',
    required int space,
    required String description,
    required String address,
    required String numDirection,
    required String street,
    required String district,
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'profileId': profileId,
        'width': width,
        'length': length,
        'height': height,
        'price': price,
        'phone': phone,
        'space': space,
        'description': description,
        'address': address,
        'numDirection': numDirection,
        'street': street,
        'district': district,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 201) {
      return Parking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create parking: ${response.body}');
    }
  }

  static Future<Parking> updateParking(int id, dynamic parking) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode(parking),
    );

    if (response.statusCode == 200) {
      return Parking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update parking: ${response.body}');
    }
  }

  static Future<void> deleteParking(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/delete/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete parking: ${response.body}');
    }
  }
}

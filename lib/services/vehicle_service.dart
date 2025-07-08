import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:homeypark_mobile_application/model/vehicle.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';

class VehicleService extends ChangeNotifier {
  final IAMService _iamService;
  final _secureStorage = const FlutterSecureStorage();
  static const String _sessionTokenKey = 'session_token';

  // --> La URL base ahora apunta a /vehicles. Las rutas específicas se construirán en cada método.
  final String _baseUrl = "${BaseService.baseUrl}/vehicles";
 
  VehicleService(this._iamService);

  bool _isLoading = false;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Vehicle> get vehicles => _vehicles;

  // --- MÉTODOS DE AYUDA PARA LA GESTIÓN DEL ESTADO (Más robustos) ---
  
  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading({String? error}) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }

  Future<String?> _getAuthToken() async {
    return await _secureStorage.read(key: _sessionTokenKey);
  }

  // --- MÉTODOS DEL SERVICIO (CORREGIDOS) ---

  Future<void> fetchMyVehicles() async {
    _startLoading();
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado.');

      final profileId = _iamService.currentUser?.profileId;
      if (profileId == null) {
        throw Exception('No se pudo obtener el ID del perfil para buscar vehículos.');
      }

      // --> Tu endpoint para obtener vehículos por usuario parece correcto. Lo mantenemos.
      final response = await http.get(
        Uri.parse('$_baseUrl/user/$profileId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        _vehicles = body.map((item) => Vehicle.fromJson(item)).toList();
        _stopLoading(); // Éxito
      } else {
        throw Exception('Error al obtener los vehículos (${response.statusCode})');
      }
    } catch (e) {
      _stopLoading(error: e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<bool> addVehicle({
    required String brand,
    required String model,
    required String licensePlate,
    required int profileId,
  }) async {
    _startLoading();
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado.');

      // --> CORRECCIÓN 1: La URL apunta al endpoint exacto de tu backend.
      final url = Uri.parse('$_baseUrl/create');
      
      final body = jsonEncode({
        'brand': brand,
        'model': model,
        'licensePlate': licensePlate,
        'profileId': profileId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: body,
      );

      if (response.statusCode == 201) { // 201 (Created) es el código estándar.
        await fetchMyVehicles(); // Refresca la lista para incluir el nuevo vehículo.
        _stopLoading(); // Éxito
        return true;
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Error al añadir el vehículo';
        throw Exception(errorMsg);
      }
    } catch (e) {
      _stopLoading(error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> updateVehicle(
    int vehicleId, {
    required String brand,
    required String model,
    required String licensePlate,
  }) async {
    _startLoading();
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado.');

      // --> CORRECCIÓN 2: La URL apunta al endpoint exacto de tu backend para actualizar.
      final url = Uri.parse('$_baseUrl/update/$vehicleId');

      final body = jsonEncode({
        'brand': brand,
        'model': model,
        'licensePlate': licensePlate,
      });

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: body,
      );

      if (response.statusCode == 200) { // 200 (OK) es el código estándar.
        await fetchMyVehicles(); // Refresca la lista para mostrar los datos actualizados.
        _stopLoading(); // Éxito
        return true;
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Error al actualizar el vehículo';
        throw Exception(errorMsg);
      }
    } catch (e) {
      _stopLoading(error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    _startLoading();
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado.');
      
      // --> Tu endpoint de borrado también podría ser diferente, ajústalo si es necesario.
      // Asumo que '/delete/{id}' es correcto según tu código original.
      final response = await http.delete(
        Uri.parse('$_baseUrl/delete/$vehicleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 (No Content) también es válido.
        // En lugar de llamar a fetchMyVehicles, es más eficiente eliminarlo de la lista local.
        _vehicles.removeWhere((v) => v.id == vehicleId);
        _stopLoading(); // Éxito
        return true;
      } else {
        throw Exception('Error al eliminar el vehículo');
      }
    } catch (e) {
      _stopLoading(error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  // Este método no afecta el estado de la lista principal, por lo que puede ser más simple.
  Future<Vehicle?> getVehicleById(int vehicleId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado.');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/$vehicleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body));
      } else {
        return null; // Devuelve null si no se encuentra.
      }
    } catch (e) {
      debugPrint("Error en getVehicleById: $e");
      return null;
    }
  }
}
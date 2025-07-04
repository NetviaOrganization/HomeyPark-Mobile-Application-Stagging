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

  final String _baseUrl = "${BaseService.baseUrl}/vehicles";
 
  VehicleService(this._iamService);

  bool _isLoading = false;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Vehicle> get vehicles => _vehicles;

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  Future<String> _getAuthToken() async {
    final token = await _secureStorage.read(key: _sessionTokenKey);
    if (token == null) throw Exception('Usuario no autenticado.');
    return token;
  }

  Future<void> fetchMyVehicles() async {
    _setLoading(true);
    try {
      final token = await _getAuthToken();
       final profileId = _iamService.currentUser?.profileId;
      if (profileId == null) {
        throw Exception('No se pudo obtener el ID del perfil para buscar vehículos.');
      }
       final response = await http.get(
        Uri.parse('$_baseUrl/user/$profileId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        _vehicles = body.map((item) => Vehicle.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener los vehículos');
      }
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (_errorMessage == null) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  Future<Vehicle?> getVehicleById(int vehicleId) async {
    // Usaremos un try-catch simple porque este método no necesita
    // manejar el estado de carga de toda la lista, es una operación puntual.
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/$vehicleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('No se encontró el vehículo');
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
  
   Future<bool> addVehicle({
    required String brand,
    required String model,
    required String licensePlate,
    required int profileId, // <-- 1. AÑADIMOS EL PARÁMETRO FALTANTE
  }) async {
    _setLoading(true);
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/create'), // Endpoint de creación
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        // 2. Usamos el profileId recibido para construir el body
        body: jsonEncode({
          'brand': brand,
          'model': model,
          'licensePlate': licensePlate,
          'profileId': profileId, 
        }),
      );
      if (response.statusCode != 201) {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Error al añadir el vehículo');
      }
      await fetchMyVehicles(); // Refresca la lista después de añadir
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> updateVehicle(int vehicleId, {
    required String brand,
    required String model,
    required String licensePlate,
    
  }) async {
    _setLoading(true);
    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/update/$vehicleId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'brand': brand, 'model': model, 'licensePlate': licensePlate}),
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Error al actualizar el vehículo');
      }
      await fetchMyVehicles();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    _setLoading(true);
    try {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/delete/$vehicleId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al eliminar el vehículo');
      }
      _vehicles.removeWhere((v) => v.id == vehicleId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:homeypark_mobile_application/model/profile.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';


class ProfileService extends ChangeNotifier {

  final IAMService _iamService;
  final _secureStorage = const FlutterSecureStorage();
  static const String _sessionTokenKey = 'session_token';

  final String _baseUrl = "${BaseService.baseUrl}/profiles";


  ProfileService(this._iamService);


  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


   void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<T> _performApiCall<T>(Future<T> Function(String token) apiCall) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _secureStorage.read(key: _sessionTokenKey);
      if (token == null) throw 'Usuario no autenticado.';
      
      final result = await apiCall(token);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
       _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Profile>> getAllProfiles() async {
    return _performApiCall((token) async {
      final response = await http.get(
        Uri.parse(_baseUrl),
  
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Profile.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener los perfiles');
      }
    });
  }

  Future<Profile?> getProfileById(int id) async {
    try {
      return await _performApiCall((token) async {
        final response = await http.get(
          Uri.parse('$_baseUrl/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          return Profile.fromJson(jsonDecode(response.body));
        } else if (response.statusCode == 404) {
          return null; // Devuelve null si no se encuentra, no es un error de app.
        } else {
          throw Exception('Error al obtener el perfil: ${response.body}');
        }
      });
    } catch (e) {
      // Si el wrapper lanza una excepción, la atrapamos aquí para devolver null
      // y no crashear el FutureBuilder que lo pueda estar usando.
      return null;
    }
  }

  Future<Profile> createProfile({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required int userId,
  }) async {
    return _performApiCall((token) async {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'birthDate': birthDate.toIso8601String().split('T')[0],
          'userId': userId,
        }),
      );
      if (response.statusCode == 201) {
        return Profile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear el perfil: ${response.body}');
      }
    });
  }

   Future<bool> updateProfile(int profileId, {
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    try {
      final updatedProfile = await _performApiCall<Profile>((token) async {
        final updateData = {
          'firstName': firstName,
          'lastName': lastName,
          if (birthDate != null) 'birthDate': birthDate.toIso8601String().split('T')[0],
        };

        final response = await http.put(
          Uri.parse('$_baseUrl/$profileId'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(updateData),
        );

        if (response.statusCode == 200) {
          return Profile.fromJson(jsonDecode(response.body));
        } else {
          throw Exception(jsonDecode(response.body)['message'] ?? 'Error al actualizar el perfil.');
        }
      });

      // Si la llamada fue exitosa, notificamos al IAMService para que actualice el estado global.
      _iamService.updateLocalUserProfile(updatedProfile);
      return true;

    } catch (e) {
      // El error ya fue manejado y guardado en _errorMessage por el wrapper.
      return false;
    }
  }

   Future<bool> deleteProfile(int id) async {
    try {
      await _performApiCall((token) async {
        final response = await http.delete(
          Uri.parse('$_baseUrl/delete/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode != 204 && response.statusCode != 200) {
          throw Exception('Error al eliminar el perfil');
        }
      });
      return true;
    } catch(e) {
      return false;
    }
  }
}
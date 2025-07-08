import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:homeypark_mobile_application/model/profile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:homeypark_mobile_application/model/user_model.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';

class IAMService extends ChangeNotifier {
  final String _baseUrl = BaseService.baseUrl;
  final _secureStorage = const FlutterSecureStorage();
  static const String _sessionTokenKey = 'session_token';
 static const String _sessionEmailKey = 'session_active_user_email';
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

   Future<void> initialize() async {
    final token = await _secureStorage.read(key: _sessionTokenKey);
    final email = await _secureStorage.read(key: _sessionEmailKey);
    if (token != null && email != null) {
      
    }
  }

  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void updateLocalUserProfile(Profile updatedProfile) {
    // 1. Verificación de seguridad: si no hay usuario, no hacemos nada.
    if (_currentUser == null) {
      debugPrint("Advertencia: Se intentó actualizar un usuario no logueado.");
      return;
    }
    final updatedUser = _currentUser!.copyWith(
      profile: updatedProfile,
    );
     _setCurrentUser(updatedUser);
  }

  

  Future<bool> _verifyRecaptchaToken(String token) async {
    final secretKey = dotenv.env['RECAPTCHA_SECRET_KEY'];
    if (secretKey == null || secretKey.isEmpty) throw 'La configuración de reCAPTCHA es incorrecta.';
    try {
      final uri = Uri.parse('https://www.google.com/recaptcha/api/siteverify');
      final response = await http.post(uri, body: {'secret': secretKey, 'response': token});
      if (response.statusCode == 200) return json.decode(response.body)['success'] == true;
      return false;
    } catch (e) {
      debugPrint('Excepción al verificar reCAPTCHA: $e');
      return false;
    }
  }

  Future<bool> signUp(SignUpData data) => _performAuthOperation(() async {
    final isHuman = await _verifyRecaptchaToken(data.recaptchaToken);
    if (!isHuman) throw 'La verificación reCAPTCHA ha fallado.';

    // 1. Enviamos UNA SOLA petición con todos los datos.
    final response = await http.post(
      Uri.parse('$_baseUrl/authentication/sign-up'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'firstName': data.firstName,
        'lastName': data.lastName,
        'birthDate': data.birthDate.toIso8601String().split('T')[0],
        'email': data.email,
        'password': data.password,
        'roles': ["ROLE_GUEST"], // El rol por defecto para un nuevo usuario.
      }),
    );

    _logResponse("Sign Up", response);

    // 2. Si el registro falla, lanzamos el error.
    if (response.statusCode >= 300) {
      if (response.body.isEmpty) throw 'Error al registrar usuario (respuesta vacía).';
      throw json.decode(response.body)['message'] ?? 'Error al registrar el usuario.';
    }

  });

   Future<bool> signIn(SignInData data) => _performAuthOperation(() async {
  final isHuman = await _verifyRecaptchaToken(data.recaptchaToken);
  if (!isHuman) throw 'La verificación reCAPTCHA ha fallado.';

  final url = Uri.parse('$_baseUrl/authentication/sign-in');
  final headers = {'Content-Type': 'application/json'};
  final bodyData = {'email': data.email, 'password': data.password};
  final body = json.encode(bodyData);

  if (kDebugMode) {
    print('--- SIGN IN REQUEST ---');
    print('URL: $url');
    print('Headers: $headers');
    print('Body: $body');
    print('------------------------');
  }

  final response = await http.post(url, headers: headers, body: body);

  if (kDebugMode) {
    print('--- SIGN IN RESPONSE ---');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('-------------------------');
  }

  await _handleAuthResponse(response, email: data.email);
});
   void updateLocalUserData({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
  }) {
    // 1. Verificación de seguridad: si no hay usuario, no hacemos nada.
    if (_currentUser == null) {
      debugPrint("Advertencia: Se intentó actualizar un usuario no logueado.");
      return;
    }

    // 2. Creamos una copia del PERFIL actual con los nuevos datos.
    //    Usamos el `copyWith` de la clase Profile.
    final updatedProfile = _currentUser!.profile.copyWith(
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
    );

    // 3. Creamos una copia del USUARIO actual, reemplazando solo su perfil.
    //    Usamos el `copyWith` de la clase UserModel.
    final updatedUser = _currentUser!.copyWith(
      profile: updatedProfile,
    );

    // 4. Actualizamos el estado con el nuevo objeto UserModel completo.
    _setCurrentUser(updatedUser);
  }

  Future<void> signOut() async {
    _setLoading(true);
    _currentUser = null;
    await _secureStorage.delete(key: _sessionTokenKey);
    await _secureStorage.delete(key: _sessionEmailKey); 
    _errorMessage = null;
    _setLoading(false);
  }

Future<void> _handleAuthResponse(http.Response response, {required String email}) async {
    // Para depuración, es útil ver siempre la respuesta
    if (kDebugMode) {
      print("--- Respuesta de Auth [${response.statusCode}] ---");
      print(response.body);
      print("---------------------------------------");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final responseData = json.decode(response.body);
        final token = responseData['token'] as String?;
        final userId = responseData['id'] as int?;

        if (token == null || userId == null) {
          throw 'La respuesta del servidor no incluyó un token o un ID de usuario.';
        }

        // 1. Guardamos el token de sesión de forma segura.
        await _secureStorage.write(key: _sessionTokenKey, value: token);
        await _secureStorage.write(key: _sessionEmailKey, value: email);

        final authData = {
        'id': userId,
        'email': email,
        'roles': responseData['roles'] ?? ['ROLE_GUEST'],
        };

      await _fetchUserProfile(token: token, authData: authData, userId: userId);

        // 2. Actualizamos el usuario actual con el token y los datos del perfil.
        //    El método _fetchUserProfile se encargará de crear el UserModel completo.
        //    No necesitamos hacer nada más aquí, ya que notifyListeners() se llama dentro de _fetchUserProfile.

      } else {
        throw 'Respuesta exitosa del servidor, pero con cuerpo vacío.';
      }
    } else {
      // Si la respuesta es un error, intentamos decodificar el mensaje del backend.
      if (response.body.isNotEmpty) {
        final errorData = json.decode(response.body);
        throw errorData['message'] ?? 'Error del servidor (${response.statusCode})';
      } else {
        throw 'Error del servidor (${response.statusCode}) sin mensaje.';
      }
    }
  }

  Future<void> _fetchUserProfile({
    required String token, 
    required Map<String, dynamic> authData,
    required int userId,
  }) async {
    try {
      // 1. Hacemos la llamada al endpoint GET /profiles general.
      //    El backend sabe a qué usuario nos referimos gracias al token.
      final response = await http.get(
        Uri.parse('$_baseUrl/profiles/$userId'), 
        headers: {'Authorization': 'Bearer $token'},
      );

      // Para depuración
      if (kDebugMode) {
        print("--- Obteniendo Perfil [${response.statusCode}] ---");
        print("Body: ${response.body}");
        print("--------------------------------");
      }

      if (response.statusCode == 200) {
        // 2. Ahora el backend devuelve UN SOLO objeto de perfil, no una lista.
        final Map<String, dynamic> profileData = json.decode(response.body);

        // 3. Creamos el UserModel completo.
        final user = UserModel.fromJson(authData: authData, profileData: profileData);
        _setCurrentUser(user);
        
      } else if (response.statusCode == 404) {
          throw 'Error crítico: El usuario existe pero no se encontró un perfil asociado.';
      } else {
        throw 'No se pudo obtener el perfil (código de respuesta: ${response.statusCode}).';
      }
    } catch (e) {
      // Si cualquier parte de este proceso falla, cerramos la sesión.
      await signOut();
      rethrow;
    }
  }
  Future<bool> _performAuthOperation(Future<void> Function() operation) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await operation();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  void _setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _logResponse(String operation, http.Response response) {
    if (kDebugMode) {
      print("--- RESPUESTA DEL BACKEND ($operation) ---");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");
      print("--------------------------------------");
    }
  }
}
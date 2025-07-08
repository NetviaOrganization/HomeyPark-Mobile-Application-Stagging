import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';

class EmailVerificationService extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Genera un código de verificación de 6 dígitos
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Guarda el código de verificación en SharedPreferences con timestamp
  Future<void> _saveVerificationCode(String email, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final expirationTime = DateTime.now().add(const Duration(minutes: 15)); // Expira en 15 minutos
    
    await prefs.setString('verification_code_$email', code);
    await prefs.setString('verification_expiration_$email', expirationTime.toIso8601String());
  }

  // Verifica si el código ingresado es correcto y marca el email como verificado en el backend
  Future<bool> verifyCode(String email, String inputCode) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('verification_code_$email');
      final expirationString = prefs.getString('verification_expiration_$email');
      
      if (savedCode == null || expirationString == null) {
        _errorMessage = 'No se encontró código de verificación. Solicita uno nuevo.';
        _setLoading(false);
        return false;
      }

      final expiration = DateTime.parse(expirationString);
      if (DateTime.now().isAfter(expiration)) {
        _errorMessage = 'El código de verificación ha expirado. Solicita uno nuevo.';
        _setLoading(false);
        return false;
      }

      if (savedCode != inputCode) {
        _errorMessage = 'Código de verificación incorrecto';
        _setLoading(false);
        return false;
      }

      // Si el código es correcto, llamar al endpoint del backend
      final userId = await preferences.getUserId();
      if (userId == 0) {
        _errorMessage = 'Error: Usuario no autenticado';
        _setLoading(false);
        return false;
      }

      print("📧 EmailVerification: Verificando email para userId = $userId");

      final response = await http.put(
        Uri.parse('${BaseService.baseUrl}/users/verify-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      print("🔍 Email Verification Response: ${response.statusCode}");
      print("🔍 Email Verification Body: ${response.body}");

      if (response.statusCode == 200) {
        // Marcar email como verificado localmente también
        await prefs.setBool('email_verified_$email', true);
        // Limpiar código usado
        await prefs.remove('verification_code_$email');
        await prefs.remove('verification_expiration_$email');
        
        _successMessage = 'Email verificado correctamente';
        _errorMessage = null;
        _setLoading(false);
        return true;
      } else {
        // Manejar errores del backend
        String errorMessage = 'Error al verificar el email en el servidor';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            // Si no se puede parsear el error, usar el mensaje por defecto
          }
        }
        _errorMessage = errorMessage;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: ${e.toString()}';
      _setLoading(false);
      if (kDebugMode) {
        print('Error verifying email: $e');
      }
      return false;
    }
  }

  // Verifica si un email ya está verificado
  Future<bool> isEmailVerified(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('email_verified_$email') ?? false;
  }

  // Envía el código de verificación por email
  Future<bool> sendVerificationEmail(String userEmail, String userName) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Generar código de verificación
      final verificationCode = _generateVerificationCode();
      
      // Configurar servidor SMTP
      final smtpServer = SmtpServer(
        dotenv.env['SMTP_HOST']!,
        port: int.parse(dotenv.env['SMTP_PORT']!),
        username: dotenv.env['SMTP_USERNAME']!,
        password: dotenv.env['SMTP_PASSWORD']!,
        ssl: false,
        allowInsecure: true,
      );

      // Crear el mensaje
      final message = Message()
        ..from = Address(dotenv.env['SMTP_FROM_EMAIL']!, dotenv.env['SMTP_FROM_NAME']!)
        ..recipients.add(userEmail)
        ..subject = 'Verificación de correo electrónico - ${dotenv.env['SMTP_FROM_NAME']}'
        ..html = _buildEmailTemplate(userName, verificationCode);

      // Enviar el email
      await send(message, smtpServer);

      // Guardar el código para verificación posterior
      await _saveVerificationCode(userEmail, verificationCode);

      _successMessage = 'Código de verificación enviado a $userEmail';
      _setLoading(false);
      return true;

    } catch (e) {
      _errorMessage = 'Error al enviar el correo: ${e.toString()}';
      _setLoading(false);
      if (kDebugMode) {
        print('Error sending email: $e');
      }
      return false;
    }
  }

  // Template HTML para el email
  String _buildEmailTemplate(String userName, String verificationCode) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verificación de Email</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 20px;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background-color: white;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                overflow: hidden;
            }
            .header {
                background-color: #2E7D32;
                color: white;
                padding: 30px;
                text-align: center;
            }
            .content {
                padding: 40px 30px;
                text-align: center;
            }
            .verification-code {
                background-color: #f8f9fa;
                border: 2px dashed #2E7D32;
                border-radius: 8px;
                padding: 20px;
                margin: 30px 0;
                font-size: 32px;
                font-weight: bold;
                color: #2E7D32;
                letter-spacing: 3px;
            }
            .footer {
                background-color: #f8f9fa;
                padding: 20px;
                text-align: center;
                font-size: 14px;
                color: #666;
            }
            .warning {
                background-color: #fff3cd;
                border: 1px solid #ffeaa7;
                border-radius: 5px;
                padding: 15px;
                margin: 20px 0;
                color: #856404;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚗 ${dotenv.env['SMTP_FROM_NAME']}</h1>
                <p>Verificación de Correo Electrónico</p>
            </div>
            
            <div class="content">
                <h2>¡Hola $userName!</h2>
                <p>Gracias por registrarte en ${dotenv.env['SMTP_FROM_NAME']}. Para completar tu registro, necesitamos verificar tu dirección de correo electrónico.</p>
                
                <p><strong>Tu código de verificación es:</strong></p>
                
                <div class="verification-code">
                    $verificationCode
                </div>
                
                <p>Ingresa este código en la aplicación para verificar tu cuenta.</p>
                
                <div class="warning">
                    <strong>⚠️ Importante:</strong><br>
                    • Este código expira en 15 minutos<br>
                    • Si no solicitaste esta verificación, ignora este correo<br>
                    • No compartas este código con nadie
                </div>
            </div>
            
            <div class="footer">
                <p>Este es un correo automático, por favor no responder.</p>
                <p>© ${DateTime.now().year} ${dotenv.env['SMTP_FROM_NAME']}. Todos los derechos reservados.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }
}
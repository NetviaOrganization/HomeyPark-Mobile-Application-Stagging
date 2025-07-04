import 'package:homeypark_mobile_application/model/profile.dart';
enum UserRole {
  guest('ROLE_GUEST'),
  admin('ROLE_ADMIN'),
  host('ROLE_HOST');

  const UserRole(this.jsonValue);
  final String jsonValue;

  static UserRole fromJson(String? value) {
    return values.firstWhere(
      (role) => role.jsonValue == value,
      orElse: () => UserRole.guest, 
    );
  }
}

class UserModel {
  // Propiedades principales
  final String id; // ID de autenticación (ej: "5")
  final String email;
  final UserRole role;
  // El Profile anidado contiene todos los datos personales.
  final Profile profile;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.profile,
  });

  // Getters de conveniencia para un acceso más fácil desde la UI
  String get firstName => profile.firstName;
  String get lastName => profile.lastName;
  String get fullName => '${profile.firstName} ${profile.lastName}';
  int get profileId => profile.id!;
  DateTime get birthDate => profile.birthDate;

  // --- Constructor Factory Único y Robusto ---
  // Este es el único constructor que necesitamos para crear un UserModel desde datos JSON.
  factory UserModel.fromJson({
    required Map<String, dynamic> authData,
    required Map<String, dynamic> profileData,
  }) {
    return UserModel(
      // Datos que vienen de la respuesta de autenticación
      id: authData['id'].toString(),
      email: authData['email'],
      role: UserRole.fromJson((authData['roles'] as List?)?.first),

      // Creamos el objeto Profile anidado a partir de los datos del perfil
      profile: Profile.fromJson(profileData),
    );
  }
 factory UserModel.fromProfile({
    required Map<String, dynamic> profileData,
    required Map<String, dynamic> authData,
    required String email, // El email lo pasamos desde el flujo de auth
  }) {
    return UserModel(
      id: authData['id'].toString(),
      // Como tu API no devuelve el rol en el perfil, asignamos uno por defecto.
      // En una app real, el endpoint de perfil también debería devolver el rol del usuario.
      role: UserRole.guest, 
       email: authData['email'],
      profile: Profile.fromJson(profileData),
    );
  }
  /// Crea una copia del usuario actual, permitiendo actualizar campos específicos.
  UserModel copyWith({
    String? id,
    String? email,
    UserRole? role,
    Profile? profile,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      profile: profile ?? this.profile,
    );
  }
}

// --- DATA CLASSES PARA FORMULARIOS (SIN CAMBIOS) ---

class SignUpData {
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String email;
  final String password;
  final String confirmPassword;
  final String recaptchaToken;

  SignUpData({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.recaptchaToken,
  });
}

class SignInData {
  final String email;
  final String password;
  final String recaptchaToken;

  SignInData({
    required this.email,
    required this.password,
    required this.recaptchaToken,
  });
}
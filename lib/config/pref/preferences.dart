import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  SharedPreferences? _preferences;
  int userId = 0;
  int profileId = 0;

  Future<SharedPreferences?> get preferences async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    return _preferences;
  }

  Future<Preferences> init() async {
    _preferences = await SharedPreferences.getInstance();
    userId = _preferences?.getInt("userId") ?? 0;
    profileId = _preferences?.getInt("profileId") ?? 0;
    return this;
  }

  Future<void> saveUserId(int id) async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    await _preferences?.setInt("userId", id);
    userId = id; // Actualiza también la variable de instancia
    print("🔐 Preferences: Guardado userId = $id");
  }

  Future<int> getUserId() async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    final savedUserId = _preferences?.getInt("userId") ?? 0;
    userId = savedUserId; // Mantiene sincronizada la variable de instancia
    print("🔐 Preferences: Obtenido userId = $savedUserId");
    return savedUserId;
  }

  Future<void> saveProfileId(int id) async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    await _preferences?.setInt("profileId", id);
    profileId = id; // Actualiza también la variable de instancia
    print("🔐 Preferences: Guardado profileId = $id");
  }

  Future<int> getProfileId() async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    final savedProfileId = _preferences?.getInt("profileId") ?? 0;
    profileId =
        savedProfileId; // Mantiene sincronizada la variable de instancia
    print("🔐 Preferences: Obtenido profileId = $savedProfileId");
    return savedProfileId;
  }

  Future<void> deleteUserId() async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    await _preferences?.remove("userId");
    await _preferences?.remove("profileId");
    userId = 0; // Reset la variable de instancia
    profileId = 0; // Reset la variable de instancia
  }
}

final preferences = Preferences();

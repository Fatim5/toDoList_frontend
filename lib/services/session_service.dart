import 'package:shared_preferences/shared_preferences.dart';

/// Service responsable de la persistance de la session utilisateur :
/// token JWT (pour les appels authentifiés) et identité minimale de
/// la personne connectée, afin de rester connecté entre deux
/// lancements de l'application.
class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _userIdKey = 'auth_user_id';
  static const String _usernameKey = 'auth_username';

  Future<void> saveSession({
    required String token,
    required String email,
    int? userId,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    if (userId != null) await prefs.setInt(_userIdKey, userId);
    if (username != null) await prefs.setString(_usernameKey, username);
  }

  /// Met à jour l'id/username une fois connus (ex: après avoir
  /// retrouvé l'utilisateur dans la liste des tâches).
  Future<void> updateIdentity({required int userId, required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }
}

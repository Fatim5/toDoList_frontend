import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/external_task.dart';
import '../models/task.dart';

/// Service d'accès à l'API REST du backend Spring Boot.
///
/// ⚠️ Remplace [baseUrl] par l'adresse IP locale de la machine qui
/// fait tourner le backend sur ton réseau Wi-Fi (visible avec
/// `ipconfig` sous Windows ou `ifconfig` / `ip a` sous macOS/Linux),
/// PAS `localhost` : le téléphone et l'ordinateur sont deux appareils
/// différents sur le réseau. Vérifie aussi que :
///  - Spring Boot écoute sur toutes les interfaces (par défaut c'est
///    le cas, sauf si tu as configuré `server.address=127.0.0.1`) ;
///  - le pare-feu de ta machine autorise les connexions entrantes
///    sur le port 8080 ;
///  - le téléphone et l'ordinateur sont bien sur le même réseau Wi-Fi.
class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  /// 🔧 À ADAPTER : adresse IP locale de ton serveur Spring Boot.
  static const String baseUrl = 'http://192.168.100.181:8080/api';

  Map<String, String> _headers({String? token, bool withBody = false}) {
    final headers = <String, String>{};
    if (withBody) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Exécute un appel réseau et convertit les erreurs bas niveau
  /// (hôte injoignable, délai dépassé, DNS...) en
  /// [NetworkUnavailableException], avec un message exploitable par
  /// la personne plutôt qu'une stack trace technique.
  Future<T> _wrap<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 10));
    } on SocketException {
      throw NetworkUnavailableException();
    } on TimeoutException {
      throw NetworkUnavailableException();
    } on http.ClientException {
      throw NetworkUnavailableException();
    } on HandshakeException {
      throw NetworkUnavailableException();
    }
  }

  // ---------------------------------------------------------------------
  // Authentification
  // ---------------------------------------------------------------------

  /// `POST /api/auth/register` → crée le compte et renvoie l'utilisateur
  /// créé (avec son `id`), ce qui permet de connaître l'id sans avoir
  /// à se reconnecter.
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _wrap(() => http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: _headers(withBody: true),
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          }),
        ));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(_extractMessage(response, fallback:
          "Impossible de créer le compte (code ${response.statusCode})."));
    }

    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// `POST /api/auth/login` → renvoie le token JWT.
  Future<String> login({required String email, required String password}) async {
    final response = await _wrap(() => http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _headers(withBody: true),
          body: jsonEncode({'email': email, 'password': password}),
        ));

    if (response.statusCode != 200) {
      throw ApiException(_extractMessage(response,
          fallback: 'E-mail ou mot de passe incorrect.'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Réponse de connexion invalide (token manquant).');
    }
    return token;
  }

  // ---------------------------------------------------------------------
  // Tâches
  // ---------------------------------------------------------------------

  /// `GET /api/tasks` → renvoie **toutes** les tâches, de tous les
  /// utilisateurs (le backend ne filtre pas par utilisateur).
  Future<List<Task>> getAllTasks({required String token}) async {
    final response = await _wrap(() => http.get(
          Uri.parse('$baseUrl/tasks'),
          headers: _headers(token: token),
        ));

    _ensureOk(response, "Impossible de récupérer les tâches");

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask({
    required String token,
    required Task task,
    int? ownerId,
  }) async {
    final response = await _wrap(() => http.post(
          Uri.parse('$baseUrl/tasks'),
          headers: _headers(token: token, withBody: true),
          body: jsonEncode(task.toJson(ownerId: ownerId)),
        ));

    _ensureOk(response, "Impossible de créer la tâche");
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Task> updateTask({
    required String token,
    required int id,
    required Task task,
    int? ownerId,
  }) async {
    final response = await _wrap(() => http.put(
          Uri.parse('$baseUrl/tasks/$id'),
          headers: _headers(token: token, withBody: true),
          body: jsonEncode(task.toJson(ownerId: ownerId)),
        ));

    _ensureOk(response, "Impossible de modifier la tâche");
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteTask({required String token, required int id}) async {
    final response = await _wrap(() => http.delete(
          Uri.parse('$baseUrl/tasks/$id'),
          headers: _headers(token: token),
        ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(_extractMessage(response,
          fallback: "Impossible de supprimer la tâche (code ${response.statusCode})."));
    }
  }

  /// `PATCH /api/tasks/{id}/complete` → marque la tâche comme terminée.
  Future<Task> markAsCompleted({required String token, required int id}) async {
    final response = await _wrap(() => http.patch(
          Uri.parse('$baseUrl/tasks/$id/complete'),
          headers: _headers(token: token),
        ));

    _ensureOk(response, "Impossible de terminer la tâche");
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Tâches externes
  // ---------------------------------------------------------------------

  /// `GET /api/external-tasks` → renvoie un tableau brut dont la forme
  /// exacte dépend de `ExternalTaskService` côté backend. Le parsing
  /// dans [ExternalTask.fromJson] est tolérant aux variations.
  Future<List<ExternalTask>> getExternalTasks({String? token}) async {
    final response = await _wrap(() => http.get(
          Uri.parse('$baseUrl/external-tasks'),
          headers: _headers(token: token),
        ));

    _ensureOk(response, "Impossible de récupérer les tâches externes");

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(ExternalTask.fromJson)
        .toList();
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  void _ensureOk(http.Response response, String actionLabel) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // ignore: avoid_print
      print('🔴 [$actionLabel] HTTP ${response.statusCode} — corps de la réponse : ${response.body}');
      throw UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // ignore: avoid_print
      print('🔴 [$actionLabel] HTTP ${response.statusCode} — corps de la réponse : ${response.body}');
      throw ApiException(_extractMessage(response,
          fallback: '$actionLabel (code ${response.statusCode}).'));
    }
  }

  String _extractMessage(http.Response response, {required String fallback}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // corps non-JSON, on garde le message par défaut
    }
    return fallback;
  }
}

/// Exception générique levée en cas d'échec d'appel réseau.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Levée spécifiquement sur un 401/403 : le token est absent, invalide
/// ou expiré. Les Controllers peuvent l'intercepter pour renvoyer
/// l'utilisateur vers l'écran de connexion.
class UnauthorizedException extends ApiException {
  UnauthorizedException()
      : super('Session expirée, veuillez vous reconnecter.');
}

/// Exception réseau bas niveau (pas de connexion, hôte injoignable...).
class NetworkUnavailableException extends ApiException {
  NetworkUnavailableException()
      : super(
            "Connexion au serveur impossible. Vérifie que ton téléphone et "
            "ton ordinateur sont sur le même réseau Wi-Fi et que l'adresse "
            "du serveur est correcte.");
}

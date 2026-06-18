import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

/// Controller (MVC) gérant l'authentification face au backend
/// Spring Boot (JWT).
///
/// Particularité de ce backend : la réponse de connexion ne contient
/// que le token (`AuthResponse { token }`), pas l'utilisateur. On ne
/// connaît donc l'`id` numérique de l'utilisateur que dans deux cas :
///  - juste après une **inscription** (la réponse contient l'objet
///    `User` complet) ;
///  - en le retrouvant dans la liste de tâches (`GET /api/tasks`),
///    dont chaque tâche embarque son `user` ; c'est ce que fait
///    [TaskController] au chargement, qui appelle ensuite
///    [adoptIdentity] pour compléter le profil ici une fois trouvé.
class AuthController extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final SessionService _session = SessionService.instance;

  AuthStatus status = AuthStatus.unknown;
  String? token;
  String? loggedInEmail;
  AppUser? currentUser;
  String? errorMessage;

  /// Tente de restaurer une session précédemment enregistrée.
  Future<void> bootstrap() async {
    status = AuthStatus.loading;
    notifyListeners();

    final savedToken = await _session.getToken();
    final savedEmail = await _session.getEmail();

    if (savedToken != null && savedEmail != null) {
      token = savedToken;
      loggedInEmail = savedEmail;

      final userId = await _session.getUserId();
      final username = await _session.getUsername();
      if (userId != null && username != null) {
        currentUser = AppUser(id: userId, username: username, email: savedEmail);
      }

      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _api.register(
        username: username,
        email: email,
        password: password,
      );
      currentUser = user;
      // L'inscription ne renvoie pas de token : on enchaîne avec une
      // connexion automatique pour obtenir le JWT.
      return await login(email: email, password: password, knownUser: user);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    AppUser? knownUser,
  }) async {
    errorMessage = null;
    notifyListeners();

    try {
      final newToken = await _api.login(email: email, password: password);
      token = newToken;
      loggedInEmail = email;
      currentUser = knownUser ?? currentUser;
      status = AuthStatus.authenticated;

      await _session.saveSession(
        token: newToken,
        email: email,
        userId: currentUser?.id,
        username: currentUser?.username,
      );

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Appelé par [TaskController] dès qu'il retrouve l'utilisateur
  /// connecté parmi les tâches existantes (via son e-mail), afin de
  /// compléter le profil (id, username) sans endpoint `/me` dédié.
  Future<void> adoptIdentity(AppUser user) async {
    if (currentUser?.id == user.id) return;
    currentUser = user;
    await _session.updateIdentity(userId: user.id, username: user.username);
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    loggedInEmail = null;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    await _session.clear();
    notifyListeners();
  }
}

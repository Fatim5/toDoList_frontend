import 'package:flutter/material.dart';

import '../models/external_task.dart';
import '../models/task.dart';
import '../services/api_service.dart';

/// Controller (MVC) gérant l'onglet "Communauté", désormais composé
/// de deux sources, toutes deux issues du backend Spring Boot :
///  - les tâches des **autres utilisateurs** (`GET /api/tasks`,
///    filtrées pour exclure celles de la personne connectée) ;
///  - les tâches **externes** (`GET /api/external-tasks`, proxy géré
///    côté serveur par `ExternalTaskService`).
class CommunityController extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Task> _teamTasks = [];
  List<ExternalTask> _externalTasks = [];

  bool isLoadingTeam = false;
  bool isLoadingExternal = false;
  String? teamError;
  String? externalError;
  bool sessionExpired = false;
  String searchQuery = '';

  List<Task> get teamTasks {
    if (searchQuery.trim().isEmpty) return _teamTasks;
    final q = searchQuery.toLowerCase();
    return _teamTasks.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.owner?.username.toLowerCase().contains(q) ?? false)).toList();
  }

  List<ExternalTask> get externalTasks {
    if (searchQuery.trim().isEmpty) return _externalTasks;
    final q = searchQuery.toLowerCase();
    return _externalTasks.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  Future<void> fetchTeamTasks({required String token, required String myEmail}) async {
    isLoadingTeam = true;
    teamError = null;
    notifyListeners();

    try {
      final all = await _api.getAllTasks(token: token);
      _teamTasks = all
          .where((t) => (t.owner?.email.toLowerCase() ?? '') != myEmail.toLowerCase())
          .toList();
    } catch (e) {
      if (e is UnauthorizedException) {
        sessionExpired = true;
      } else {
        teamError = e.toString();
      }
    }

    isLoadingTeam = false;
    notifyListeners();
  }

  Future<void> fetchExternalTasks({String? token}) async {
    isLoadingExternal = true;
    externalError = null;
    notifyListeners();

    try {
      _externalTasks = await _api.getExternalTasks(token: token);
    } catch (e) {
      externalError = e.toString();
    }

    isLoadingExternal = false;
    notifyListeners();
  }

  Future<void> refreshAll({required String token, required String myEmail}) async {
    await Future.wait([
      fetchTeamTasks(token: token, myEmail: myEmail),
      fetchExternalTasks(token: token),
    ]);
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }
}

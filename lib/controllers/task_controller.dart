import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../services/api_service.dart';

enum TaskFilter { all, active, completed }

/// Controller (MVC) gérant les tâches de l'utilisateur connecté.
///
/// Toutes les données passent désormais par l'API REST du backend
/// Spring Boot (MySQL) — il n'y a plus de stockage local. Comme
/// `GET /api/tasks` renvoie les tâches de **tous** les utilisateurs,
/// ce Controller récupère la liste complète puis filtre côté client
/// celles dont le `user.email` correspond à l'utilisateur connecté.
class TaskController extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Task> _myTasks = [];
  bool isLoading = false;
  String? errorMessage;
  bool sessionExpired = false;
  TaskFilter filter = TaskFilter.all;

  /// Renseigné dès qu'une tâche appartenant à l'utilisateur connecté
  /// est trouvée dans la liste globale — permet à [AuthController]
  /// de compléter son profil (id, username) sans endpoint `/me`.
  AppUser? identifiedOwner;

  /// Id du propriétaire à utiliser pour créer/modifier une tâche.
  int? _ownerId;

  List<Task> get tasks {
    switch (filter) {
      case TaskFilter.active:
        return _myTasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return _myTasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return _myTasks;
    }
  }

  int get totalCount => _myTasks.length;
  int get completedCount => _myTasks.where((t) => t.isCompleted).length;
  int get overdueCount => _myTasks.where((t) => t.isOverdue).length;

  Future<void> loadTasksFor({
    required String token,
    required String email,
    int? knownOwnerId,
  }) async {
    isLoading = true;
    errorMessage = null;
    sessionExpired = false;
    notifyListeners();

    try {
      final all = await _api.getAllTasks(token: token);
      _myTasks = all
          .where((t) => (t.owner?.email.toLowerCase() ?? '') == email.toLowerCase())
          .toList();
      _sortTasks();

      if (_myTasks.isNotEmpty && _myTasks.first.owner != null) {
        final owner = _myTasks.first.owner!;
        identifiedOwner = AppUser(id: owner.id, username: owner.username, email: owner.email);
        _ownerId = owner.id;
      } else {
        _ownerId = knownOwnerId;
      }
    } catch (e) {
      if (e is UnauthorizedException) {
        sessionExpired = true;
      } else {
        errorMessage = e.toString();
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void setFilter(TaskFilter newFilter) {
    filter = newFilter;
    notifyListeners();
  }

  Future<bool> addTask({
    required String token,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final draft = Task(
        title: title.trim(),
        description: description.trim(),
        dueDate: dueDate,
      );
      final created = await _api.createTask(token: token, task: draft, ownerId: _ownerId);
      _myTasks.add(created);
      _sortTasks();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (e is UnauthorizedException) sessionExpired = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(
    Task original, {
    required String token,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    if (original.id == null) return false;
    try {
      final draft = original.copyWith(
        title: title.trim(),
        description: description.trim(),
        dueDate: dueDate,
      );
      final updated = await _api.updateTask(
        token: token,
        id: original.id!,
        task: draft,
        ownerId: _ownerId ?? original.owner?.id,
      );
      final index = _myTasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) _myTasks[index] = updated;
      _sortTasks();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (e is UnauthorizedException) sessionExpired = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(Task task, {required String token}) async {
    if (task.id == null) return false;
    try {
      await _api.deleteTask(token: token, id: task.id!);
      _myTasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (e is UnauthorizedException) sessionExpired = true;
      notifyListeners();
      return false;
    }
  }

  /// Marque la tâche comme terminée (`PATCH .../complete`) ou,
  /// pour revenir en arrière, comme non terminée (`PUT` complet —
  /// le backend n'expose pas d'endpoint dédié pour "dé-terminer").
  Future<void> toggleCompleted(Task task, {required String token}) async {
    if (task.id == null) return;
    try {
      Task updated;
      if (!task.isCompleted) {
        updated = await _api.markAsCompleted(token: token, id: task.id!);
      } else {
        updated = await _api.updateTask(
          token: token,
          id: task.id!,
          task: task.copyWith(isCompleted: false),
          ownerId: _ownerId ?? task.owner?.id,
        );
      }
      final index = _myTasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) _myTasks[index] = updated;
      _sortTasks();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      if (e is UnauthorizedException) sessionExpired = true;
      notifyListeners();
    }
  }

  void _sortTasks() {
    _myTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.dueDate.compareTo(b.dueDate);
    });
  }

  void reset() {
    _myTasks = [];
    identifiedOwner = null;
    _ownerId = null;
    filter = TaskFilter.all;
    sessionExpired = false;
    notifyListeners();
  }
}

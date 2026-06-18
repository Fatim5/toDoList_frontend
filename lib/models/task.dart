/// Modèle représentant une tâche, telle qu'échangée avec le backend
/// Spring Boot (`entity.Task`).
///
/// Couche **Model** : les noms de propriétés Dart restent en anglais
/// pour la cohérence du code (title, description, dueDate...), mais
/// [toJson]/[fromJson] traduisent vers/depuis les noms réels utilisés
/// par l'API (`titre`, `description`, `dateEcheance`, `terminee`,
/// `user`).
class TaskOwner {
  final int id;
  final String username;
  final String email;

  const TaskOwner({
    required this.id,
    required this.username,
    required this.email,
  });

  factory TaskOwner.fromJson(Map<String, dynamic> json) {
    return TaskOwner(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final TaskOwner? owner;

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.owner,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TaskOwner? owner,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      owner: owner ?? this.owner,
    );
  }

  /// Construit une tâche à partir du JSON renvoyé par l'API
  /// (`entity.Task` sérialisée par Jackson).
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: json['dateEcheance'] != null
          ? DateTime.parse(json['dateEcheance'] as String)
          : DateTime.now(),
      isCompleted: json['terminee'] as bool? ?? false,
      owner: json['user'] != null
          ? TaskOwner.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Sérialise la tâche au format attendu par l'API pour
  /// la création / la modification (`POST` / `PUT /api/tasks`).
  ///
  /// [ownerId] permet d'attacher explicitement le propriétaire lors
  /// de la création (le champ `id` n'est volontairement pas inclus :
  /// il est généré par la base de données).
  Map<String, dynamic> toJson({int? ownerId}) {
    final json = <String, dynamic>{
      'titre': title,
      'description': description,
      'dateEcheance': _formatDate(dueDate),
      'terminee': isCompleted,
    };

    final resolvedOwnerId = ownerId ?? owner?.id;
    if (resolvedOwnerId != null) {
      json['user'] = {'id': resolvedOwnerId};
    }

    return json;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  bool get isDueSoon {
    if (isCompleted) return false;
    final diff = dueDate.difference(DateTime.now());
    return diff.inHours >= 0 && diff.inHours <= 48;
  }
}

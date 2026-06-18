/// Modèle représentant un élément renvoyé par `GET /api/external-tasks`.
///
/// Le backend expose ce endpoint via `ExternalTaskService` et renvoie
/// un tableau brut (`Object[]`) — la forme exacte de chaque élément
/// dépend de l'implémentation du service côté backend (probablement
/// un proxy vers une API externe de type JSONPlaceholder). Le parsing
/// ci-dessous est volontairement tolérant : il essaie plusieurs noms
/// de champs possibles (anglais / français) et ne plante jamais sur
/// un format inattendu.
class ExternalTask {
  final String title;
  final bool completed;
  final String? authorLabel;

  const ExternalTask({
    required this.title,
    required this.completed,
    this.authorLabel,
  });

  factory ExternalTask.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ??
        json['titre'] ??
        json['name'] ??
        json['nom'] ??
        'Tâche externe';

    final completed = json['completed'] ??
        json['terminee'] ??
        json['done'] ??
        json['isCompleted'] ??
        false;

    final author = json['userId'] ??
        json['user'] ??
        json['author'] ??
        json['auteur'];

    return ExternalTask(
      title: title.toString(),
      completed: completed == true || completed.toString() == 'true',
      authorLabel: author?.toString(),
    );
  }
}

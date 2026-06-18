/// Modèle représentant un utilisateur, aligné sur `entity.User` du
/// backend (champs `id`, `username`, `email`; le mot de passe n'est
/// jamais conservé côté client même s'il apparaît dans la réponse API).
class AppUser {
  final int id;
  final String username;
  final String email;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  /// Initiales utilisées pour l'avatar (ex: "marie.k" -> "M").
  String get initials {
    if (username.isEmpty) return '?';
    return username.substring(0, 1).toUpperCase();
  }
}

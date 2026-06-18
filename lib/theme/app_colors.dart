import 'package:flutter/material.dart';

/// Palette de couleurs de l'application.
///
/// Direction visuelle : un bleu nuit profond (sérieux, "outil de
/// productivité") associé à un accent ambre chaleureux (énergie,
/// action) plutôt que les choix par défaut violet/indigo de Material.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFEEF1F6);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF1B2A4A); // bleu nuit
  static const Color primaryLight = Color(0xFF31466F);

  static const Color accent = Color(0xFFF2A65A); // ambre chaleureux
  static const Color accentDark = Color(0xFFD9883A);

  static const Color success = Color(0xFF6FA98C); // vert sauge (terminé)
  static const Color danger = Color(0xFFE0654F); // corail (retard)
  static const Color warning = Color(0xFFEFC078); // bientôt dû

  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF647184);
  static const Color textOnPrimary = Color(0xFFF7F8FA);

  static const Color divider = Color(0xFFDDE3EC);

  /// Couleur de l'indicateur d'urgence d'une tâche.
  static Color urgencyColor({
    required bool isCompleted,
    required bool isOverdue,
    required bool isDueSoon,
  }) {
    if (isCompleted) return success;
    if (isOverdue) return danger;
    if (isDueSoon) return warning;
    return primaryLight;
  }
}

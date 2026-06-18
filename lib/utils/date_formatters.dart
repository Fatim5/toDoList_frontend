import 'package:intl/intl.dart';

/// Fonctions utilitaires de formatage de dates, partagées par
/// plusieurs Views.
class DateFormatters {
  DateFormatters._();

  static final DateFormat _dayMonth = DateFormat('d MMM', 'fr_FR');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy', 'fr_FR');
  static final DateFormat _full = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  static final DateFormat _time = DateFormat('HH:mm', 'fr_FR');

  /// Ex: "12 juin" si l'année est l'année en cours, sinon "12 juin 2027".
  static String shortDate(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year ? _dayMonth.format(date) : _dayMonthYear.format(date);
  }

  static String fullDate(DateTime date) => _full.format(date);

  static String time(DateTime date) => _time.format(date);

  /// Texte relatif convivial: "Aujourd'hui", "Demain", "Hier", ou date.
  static String relativeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    switch (diff) {
      case 0:
        return "Aujourd'hui";
      case 1:
        return 'Demain';
      case -1:
        return 'Hier';
      default:
        return shortDate(date);
    }
  }
}

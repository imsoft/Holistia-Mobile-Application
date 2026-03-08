/// Utilidades de formato de fechas usadas en todo el proyecto.
abstract final class AppDateUtils {
  /// Formato absoluto: DD/MM/YYYY  → ej. "27/02/2026"
  static String formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  /// Relativo a la hora actual → ej. "Hace 5 min", "Hace 3h", "Hace 2 días", o fecha absoluta.
  static String formatRelative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return formatDate(d);
  }

  /// Relativo al día actual → "Hoy", "Ayer", "Hace N días", o fecha absoluta.
  static String formatRelativeDay(DateTime d) {
    final today = _today();
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return formatDate(d);
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

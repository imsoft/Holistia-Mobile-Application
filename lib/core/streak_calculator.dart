import '../models/check_in.dart';

/// Calcula la racha actual de check-ins consecutivos.
///
/// Una racha es el número de días consecutivos hasta hoy (o ayer
/// si hoy aún no hay check-in). Si el último check-in fue hace
/// más de un día, la racha es 0.
int computeStreak(List<CheckIn> checkIns) {
  if (checkIns.isEmpty) return 0;

  // Normalizar a fechas sin hora
  final today = _dateOnly(DateTime.now());

  // Obtener fechas únicas ordenadas DESC
  final dates = checkIns
      .map((c) => _dateOnly(c.date))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  // El punto de inicio: hoy o ayer (si hoy no hay check-in)
  final mostRecent = dates.first;
  final daysDiff = today.difference(mostRecent).inDays;

  // Si el más reciente fue hace más de 1 día, racha rota
  if (daysDiff > 1) return 0;

  // Contar días consecutivos
  int streak = 1;
  for (int i = 1; i < dates.length; i++) {
    final diff = dates[i - 1].difference(dates[i]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

import 'package:flutter_test/flutter_test.dart';
import 'package:holistia/core/app_date_utils.dart';

void main() {
  group('AppDateUtils.formatDate', () {
    test('formatea con ceros a la izquierda', () {
      expect(AppDateUtils.formatDate(DateTime(2026, 2, 7)), '07/02/2026');
    });

    test('formatea fin de año', () {
      expect(AppDateUtils.formatDate(DateTime(2025, 12, 31)), '31/12/2025');
    });

    test('formatea primer día del año', () {
      expect(AppDateUtils.formatDate(DateTime(2024)), '01/01/2024');
    });
  });

  group('AppDateUtils.formatRelativeDay', () {
    test('hoy → "Hoy"', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(AppDateUtils.formatRelativeDay(today), 'Hoy');
    });

    test('ayer → "Ayer"', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.formatRelativeDay(yesterday), 'Ayer');
    });

    test('hace 3 días → "Hace 3 días"', () {
      final d = DateTime.now().subtract(const Duration(days: 3));
      expect(AppDateUtils.formatRelativeDay(d), 'Hace 3 días');
    });

    test('hace 6 días → "Hace 6 días"', () {
      final d = DateTime.now().subtract(const Duration(days: 6));
      expect(AppDateUtils.formatRelativeDay(d), 'Hace 6 días');
    });

    test('hace 7 días → fecha absoluta', () {
      final d = DateTime.now().subtract(const Duration(days: 7));
      final expected = AppDateUtils.formatDate(d);
      expect(AppDateUtils.formatRelativeDay(d), expected);
    });
  });
}

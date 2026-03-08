import 'package:flutter_test/flutter_test.dart';
import 'package:holistia/core/streak_calculator.dart';
import 'package:holistia/models/check_in.dart';

CheckIn _ci(DateTime date) => CheckIn(
      id: 'id',
      challengeId: 'c',
      userId: 'u',
      date: date,
      createdAt: date,
    );

DateTime _daysAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - n);
}

void main() {
  group('computeStreak', () {
    test('lista vacía → 0', () {
      expect(computeStreak([]), 0);
    });

    test('solo hoy → 1', () {
      expect(computeStreak([_ci(_daysAgo(0))]), 1);
    });

    test('solo ayer → 1', () {
      expect(computeStreak([_ci(_daysAgo(1))]), 1);
    });

    test('hace 2 días → 0 (racha rota)', () {
      expect(computeStreak([_ci(_daysAgo(2))]), 0);
    });

    test('3 días consecutivos hasta hoy → 3', () {
      final checkIns = [
        _ci(_daysAgo(0)),
        _ci(_daysAgo(1)),
        _ci(_daysAgo(2)),
      ];
      expect(computeStreak(checkIns), 3);
    });

    test('3 días consecutivos hasta ayer → 3', () {
      final checkIns = [
        _ci(_daysAgo(1)),
        _ci(_daysAgo(2)),
        _ci(_daysAgo(3)),
      ];
      expect(computeStreak(checkIns), 3);
    });

    test('gap en el medio → cuenta solo desde el gap', () {
      // hoy, ayer, hace 3 días (gap en hace 2)
      final checkIns = [
        _ci(_daysAgo(0)),
        _ci(_daysAgo(1)),
        _ci(_daysAgo(3)),
      ];
      expect(computeStreak(checkIns), 2);
    });

    test('duplicados en el mismo día no rompen la racha', () {
      final checkIns = [
        _ci(_daysAgo(0)),
        _ci(_daysAgo(0)), // duplicado
        _ci(_daysAgo(1)),
        _ci(_daysAgo(2)),
      ];
      expect(computeStreak(checkIns), 3);
    });
  });
}

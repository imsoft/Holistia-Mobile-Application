import 'package:flutter_test/flutter_test.dart';
import 'package:holistia/core/zenit_level.dart';

void main() {
  group('ZenitLevel.fromBalance', () {
    test('0 → semilla', () => expect(ZenitLevel.fromBalance(0), ZenitLevel.semilla));
    test('99 → semilla', () => expect(ZenitLevel.fromBalance(99), ZenitLevel.semilla));
    test('100 → brote', () => expect(ZenitLevel.fromBalance(100), ZenitLevel.brote));
    test('299 → brote', () => expect(ZenitLevel.fromBalance(299), ZenitLevel.brote));
    test('300 → raiz', () => expect(ZenitLevel.fromBalance(300), ZenitLevel.raiz));
    test('699 → raiz', () => expect(ZenitLevel.fromBalance(699), ZenitLevel.raiz));
    test('700 → arbol', () => expect(ZenitLevel.fromBalance(700), ZenitLevel.arbol));
    test('1499 → arbol', () => expect(ZenitLevel.fromBalance(1499), ZenitLevel.arbol));
    test('1500 → bosque', () => expect(ZenitLevel.fromBalance(1500), ZenitLevel.bosque));
    test('2999 → bosque', () => expect(ZenitLevel.fromBalance(2999), ZenitLevel.bosque));
    test('3000 → cosmos', () => expect(ZenitLevel.fromBalance(3000), ZenitLevel.cosmos));
    test('9999 → cosmos', () => expect(ZenitLevel.fromBalance(9999), ZenitLevel.cosmos));
  });

  group('ZenitLevel.progress', () {
    test('semilla a 50 → 0.5', () {
      expect(ZenitLevel.semilla.progress(50), closeTo(0.5, 0.001));
    });

    test('brote a 150 → 0.25', () {
      // rango: 100–300, current = 150-100 = 50, 50/200 = 0.25
      expect(ZenitLevel.brote.progress(150), closeTo(0.25, 0.001));
    });

    test('cosmos siempre → 1.0', () {
      expect(ZenitLevel.cosmos.progress(5000), 1.0);
    });

    test('clamp: no supera 1.0', () {
      expect(ZenitLevel.semilla.progress(9999), 1.0);
    });

    test('clamp: no baja de 0.0', () {
      expect(ZenitLevel.semilla.progress(-10), 0.0);
    });
  });

  group('ZenitLevel.nextLevelAt', () {
    test('semilla → 100', () => expect(ZenitLevel.semilla.nextLevelAt, 100));
    test('cosmos → null', () => expect(ZenitLevel.cosmos.nextLevelAt, isNull));
  });

  group('ZenitLevel.startsAt', () {
    test('semilla → 0', () => expect(ZenitLevel.semilla.startsAt, 0));
    test('brote → 100', () => expect(ZenitLevel.brote.startsAt, 100));
    test('cosmos → 3000', () => expect(ZenitLevel.cosmos.startsAt, 3000));
  });
}

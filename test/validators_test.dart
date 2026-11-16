import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid emails', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('  rahim@example.com '), isNull);
    });
    test('rejects empty and malformed emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
  });

  group('Validators.newPassword (mirrors the backend rules)', () {
    test('accepts 8+ chars with a letter and a number', () {
      expect(Validators.newPassword('Passw0rd1'), isNull);
    });
    test('rejects short, letter-less and number-less passwords', () {
      expect(Validators.newPassword('Ab1'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('abcdefgh'), isNotNull);
      expect(Validators.newPassword('a1' * 40), isNotNull); // > 72 chars
    });
  });

  group('Validators.confirmPassword', () {
    test('requires the same value', () {
      final validate = Validators.confirmPassword(() => 'Passw0rd1');
      expect(validate('Passw0rd1'), isNull);
      expect(validate('different'), isNotNull);
      expect(validate(''), isNotNull);
    });
  });

  group('Validators.name / phone', () {
    test('name needs at least 2 characters', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Al'), isNull);
    });
    test('phone is optional but must look like a phone number', () {
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('+880 1700-000000'), isNull);
      expect(Validators.phone('abc'), isNotNull);
    });
  });
}

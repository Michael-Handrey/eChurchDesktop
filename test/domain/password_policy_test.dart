import 'package:echurch_desktop/domain/models/auth/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mesmos casos do `PasswordPolicyTest.java`: o app e o backend precisam concordar.
void main() {
  List<String> failing(String password, [String login = 'x']) => [
    for (final check in PasswordPolicy.check(password, login))
      if (!check.passed) check.label,
  ];

  test('aceita senha forte', () {
    expect(PasswordPolicy.accepts('Igreja#2026', 'secretaria'), isTrue);
  });

  test('aceita letras acentuadas', () {
    expect(PasswordPolicy.accepts('Ávore#2026é', 'maria'), isTrue);
  });

  test('exige cada tipo de caractere', () {
    expect(failing('igreja#2026'), ['Uma letra maiúscula']);
    expect(failing('IGREJA#2026'), ['Uma letra minúscula']);
    expect(failing('Igreja#Nova'), ['Um número']);
    expect(failing('Igreja2026'), [r'Um símbolo (ex.: ! @ # $ %)']);
  });

  test('espaço não conta como símbolo', () {
    expect(failing('Igreja 2026'), [r'Um símbolo (ex.: ! @ # $ %)']);
  });

  test('recusa senha curta', () {
    expect(failing('Ig#1'), ['Pelo menos 8 caracteres']);
  });

  test('recusa senha com o login', () {
    expect(failing('Maria#2026', 'maria'), ['Não conter o seu login']);
  });

  test('recusa senha longa demais', () {
    expect(failing('Aa1#${'x' * 61}'), ['No máximo 64 caracteres']);
  });

  test('recusa senha acima do limite do BCrypt (72 bytes)', () {
    expect(failing('Aa1#${'😀' * 20}'), ['No máximo 64 caracteres']);
  });
}

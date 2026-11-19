import 'dart:convert';

/// Uma regra da senha: texto para a tela + teste.
typedef PasswordRule = ({String label, bool Function(String password, String login) passes});

/// Resultado de uma regra para a senha digitada.
typedef PasswordRuleCheck = ({String label, bool passed});

/// Mesma regra de força de senha do backend (`PasswordPolicy.java`).
/// Aqui serve só para mostrar a checagem enquanto o usuário digita;
/// quem decide é o backend.
final class PasswordPolicy._() {
  static const minLength = 8;
  static const maxLength = 64;

  /// O BCrypt do backend não aceita mais que isso.
  static const _maxBytes = 72;
  static const _minLoginLengthToCheck = 3;

  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _lower = RegExp(r'\p{Ll}', unicode: true);
  static final _digit = RegExp(r'\p{Nd}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\p{Nd}\s]', unicode: true);

  static final List<PasswordRule> rules = [
    (label: 'Pelo menos $minLength caracteres', passes: (password, _) => password.runes.length >= minLength),
    (label: 'No máximo $maxLength caracteres', passes: (password, _) => password.runes.length <= maxLength && utf8.encode(password).length <= _maxBytes),
    (label: 'Uma letra maiúscula', passes: (password, _) => _upper.hasMatch(password)),
    (label: 'Uma letra minúscula', passes: (password, _) => _lower.hasMatch(password)),
    (label: 'Um número', passes: (password, _) => _digit.hasMatch(password)),
    (label: 'Um símbolo (ex.: ! @ # \$ %)', passes: (password, _) => _symbol.hasMatch(password)),
    (label: 'Não conter o seu login', passes: _withoutLogin),
  ];

  static List<PasswordRuleCheck> check(String password, String login) => [
    for (final rule in rules) (label: rule.label, passed: rule.passes(password, login)),
  ];

  static bool accepts(String password, String login) => rules.every((rule) => rule.passes(password, login));

  static bool _withoutLogin(String password, String login) {
    final normalized = login.trim().toLowerCase();
    if (normalized.length < _minLoginLengthToCheck) return true;
    return !password.toLowerCase().contains(normalized);
  }
}

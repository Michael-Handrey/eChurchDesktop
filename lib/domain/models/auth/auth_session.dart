import 'package:equatable/equatable.dart';

class const AuthSession({
  required final String accessToken,
  required final DateTime accessTokenExpiresAt,
  required final String refreshToken,
  required final DateTime refreshTokenExpiresAt,
  required final AuthSessionUser user,
}) extends Equatable {
  bool get isAccessTokenValid => DateTime.now().isBefore(accessTokenExpiresAt);
  bool get isRefreshTokenValid => DateTime.now().isBefore(refreshTokenExpiresAt);

  @override
  List<Object?> get props => [accessToken, accessTokenExpiresAt, refreshToken, refreshTokenExpiresAt, user];

  @override
  bool? get stringify => false;
}

class const AuthSessionUser({
  required final String login,
  required final String name,
  required final bool firstAccess,
  final int? churchId,

  /// Papéis do backend (`ROLE_ADMIN`, `ROLE_SECRETARIA`...). Só decidem o que a tela mostra:
  /// quem autoriza de verdade é a API.
  final List<String> roles = const [],
}) extends Equatable {
  static const adminRole = 'ROLE_ADMIN';
  static const secretaryRole = 'ROLE_SECRETARIA';

  bool get isAdmin => roles.contains(adminRole);

  /// Administrador ou Secretaria: gerencia os cadastros (a API confere a mesma regra).
  bool get canManage => isAdmin || roles.contains(secretaryRole);

  @override
  List<Object?> get props => [login, name, firstAccess, churchId, roles];

  @override
  bool? get stringify => false;
}

/// Tokens devolvidos pelo login/refresh, antes de buscar os dados do usuário.
class const AuthTokens({
  required final String accessToken,
  required final DateTime accessTokenExpiresAt,
  required final String refreshToken,
  required final DateTime refreshTokenExpiresAt,
}) extends Equatable {
  @override
  List<Object?> get props => [accessToken, accessTokenExpiresAt, refreshToken, refreshTokenExpiresAt];

  @override
  bool? get stringify => false;
}

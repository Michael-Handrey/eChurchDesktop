import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

abstract interface class AuthRepository {
  /// Autentica e já busca os dados do usuário (`/me`).
  Future<Result<AuthSession>> login({required String login, required String password});

  /// Troca o refresh token por um novo par de tokens (o refresh anterior é revogado no backend).
  Future<Result<AuthSession>> refresh({required String refreshToken});

  /// Revoga o access token atual e o [refreshToken] no backend.
  Future<Result<void>> logout({required String refreshToken});
}

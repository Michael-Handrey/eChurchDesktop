import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

abstract interface class AuthRepository {
  /// Autentica e já busca os dados do usuário (`/me`).
  Future<Result<AuthSession>> login({required String login, required String password});

  /// Troca o refresh token por um novo par de tokens (o refresh anterior é revogado no backend).
  Future<Result<AuthSession>> refresh({required String refreshToken});

  /// Revoga no backend o [refreshToken] e, se ainda válido, o [accessToken] (só este dispositivo).
  Future<Result<void>> logout({required String refreshToken, String? accessToken});
}

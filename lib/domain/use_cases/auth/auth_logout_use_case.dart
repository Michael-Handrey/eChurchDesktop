import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';

/// Revoga os tokens deste dispositivo no backend (melhor esforço) e apaga a sessão local.
/// O endpoint de logout é público e aceita só o refresh token, então a revogação
/// acontece mesmo com o access token expirado.
class AuthLogoutUseCase({
  required final AuthRepository _authRepository,
  required final AuthSessionRepository _authSessionRepository,
}) {
  final _log = AppLogger('AuthLogoutUseCase');

  Future<Result<void>> logout() async {
    if (await _authSessionRepository.fetch() case Ok(value: (:final session, remember: _)?)) {
      final revoked = await _authRepository.logout(refreshToken: session.refreshToken, accessToken: session.accessToken);
      if (revoked case Error(:final error)) {
        _log.warning('Falha ao revogar os tokens no backend', error: error, stackTrace: error.stackTrace);
      }
    }

    return _authSessionRepository.delete();
  }
}

import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

class AuthLoginUseCase({
  required final AuthRepository _authRepository,
  required final AuthSessionRepository _authSessionRepository,
}) {
  final _log = AppLogger('AuthLoginUseCase');

  Future<Result<AuthSessionUser>> login({required String login, required String password, required bool remember}) async {
    final authenticated = await _authRepository.login(login: login, password: password);

    switch (authenticated) {
      case Ok<AuthSession>(value: final session):
        if (await _authSessionRepository.save(session, remember: remember) case Error(:final error)) {
          await _undo(session);
          return Result.error(error);
        }
        return Result.ok(session.user);

      case Error<AuthSession>(:final error):
        return Result.error(error);
    }
  }

  /// Não deu para guardar a sessão: desfaz tudo, inclusive a sessão aberta no backend.
  Future<void> _undo(AuthSession session) async {
    await _authSessionRepository.delete();

    final revoked = await _authRepository.logout(refreshToken: session.refreshToken, accessToken: session.accessToken);
    if (revoked case Error(:final error)) {
      _log.warning('Falha ao revogar a sessão não guardada', error: error, stackTrace: error.stackTrace);
    }
  }
}

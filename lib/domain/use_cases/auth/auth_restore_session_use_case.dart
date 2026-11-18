import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

/// Restaura a sessão guardada na abertura do app:
/// - sem "Lembrar-me" → descarta;
/// - access token válido → usa;
/// - access expirado e refresh válido → renova no backend;
/// - ambos expirados / refresh recusado → descarta.
class AuthRestoreSessionUseCase({
  required final AuthRepository _authRepository,
  required final AuthSessionRepository _authSessionRepository,
}) {
  final _log = AppLogger('AuthRestoreSessionUseCase');

  Future<Result<AuthSessionUser?>> restore() async {
    final stored = await _authSessionRepository.fetch();

    switch (stored) {
      case Error<StoredAuthSession?>(:final error):
        return Result.error(error);

      case Ok<StoredAuthSession?>(value: null):
        return Result.ok(null);

      case Ok<StoredAuthSession?>(value: (:final session, :final remember)):
        if (!remember || !session.isRefreshTokenValid) return _discard();

        if (session.isAccessTokenValid) return Result.ok(session.user);

        return _refresh(session, remember: remember);
    }
  }

  Future<Result<AuthSessionUser?>> _refresh(AuthSession session, {required bool remember}) async {
    final refreshed = await _authRepository.refresh(refreshToken: session.refreshToken);

    switch (refreshed) {
      case Ok<AuthSession>(value: final newSession):
        _log.info('Sessão renovada com o refresh token');
        final saved = await _authSessionRepository.save(newSession, remember: remember);
        return switch (saved) {
          Ok<void>() => Result.ok(newSession.user),
          Error<void>(:final error) => Result.error(error),
        };

      // Backend fora do ar: mantém o usuário; as chamadas à API tratam a falha.
      case Error<AuthSession>(error: NetworkException()):
        return Result.ok(session.user);

      case Error<AuthSession>(:final error):
        _log.warning('Refresh token recusado', error: error);
        return _discard();
    }
  }

  Future<Result<AuthSessionUser?>> _discard() async {
    final deleted = await _authSessionRepository.delete();
    return switch (deleted) {
      Ok<void>() => Result.ok(null),
      Error<void>(:final error) => Result.error(error),
    };
  }
}

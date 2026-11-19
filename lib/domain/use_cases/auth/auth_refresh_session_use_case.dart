import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

/// Renova a sessão com o refresh token.
///
/// Uma renovação por vez (single-flight): o backend gira o refresh token a cada uso,
/// então duas renovações paralelas com o mesmo token fariam a segunda ser recusada
/// e derrubariam a sessão. Chamadas simultâneas recebem o mesmo resultado.
///
/// Resultado:
/// - `Ok(sessão)` → renovada, ou já renovada por outra chamada (o `rejectedAccessToken` não é mais o atual);
/// - `Ok(null)` → não há sessão ou o backend recusou o refresh: a sessão acabou;
/// - `Error` → falha transitória (rede, servidor): a sessão continua, tente depois.
class AuthRefreshSessionUseCase({
  required final AuthRepository _authRepository,
  required final AuthSessionRepository _authSessionRepository,
}) {
  final _log = AppLogger('AuthRefreshSessionUseCase');

  Future<Result<AuthSession?>>? _inFlight;

  Future<Result<AuthSession?>> refresh({String? rejectedAccessToken}) {
    return _inFlight ??= _refresh(rejectedAccessToken).whenComplete(() => _inFlight = null);
  }

  Future<Result<AuthSession?>> _refresh(String? rejectedAccessToken) async {
    final stored = await _authSessionRepository.fetch();

    switch (stored) {
      case Error<StoredAuthSession?>(:final error):
        return Result.error(error);

      case Ok<StoredAuthSession?>(value: null):
        return const Result.ok(null);

      case Ok<StoredAuthSession?>(value: (:final session, remember: _)):
        if (rejectedAccessToken != null && session.accessToken != rejectedAccessToken) {
          return Result.ok(session);
        }
        return _renew(session);
    }
  }

  Future<Result<AuthSession?>> _renew(AuthSession current) async {
    final refreshed = await _authRepository.refresh(refreshToken: current.refreshToken);

    switch (refreshed) {
      case Ok<AuthSession>(value: final next):
        return _store(current: current, next: next);

      case Error<AuthSession>(error: final NetworkException error):
        return Result.error(error);

      case Error<AuthSession>(error: final ServerException error):
        return Result.error(error);

      case Error<AuthSession>(:final error):
        _log.warning('Refresh token recusado', error: error, stackTrace: error.stackTrace);
        return const Result.ok(null);
    }
  }

  Future<Result<AuthSession?>> _store({required AuthSession current, required AuthSession next}) async {
    switch (await _authSessionRepository.replace(current: current, next: next)) {
      case Ok<bool>(value: true):
        _log.info('Sessão renovada');
        return Result.ok(next);

      case Ok<bool>():
        // Logout (ou novo login) aconteceu durante a renovação: os tokens novos
        // não podem ressuscitar a sessão. Revoga-os no backend e devolve a sessão atual, se houver.
        _log.info('Sessão mudou durante a renovação; descartando os tokens novos');
        final revoked = await _authRepository.logout(refreshToken: next.refreshToken, accessToken: next.accessToken);
        if (revoked case Error(:final error)) {
          _log.warning('Falha ao revogar os tokens descartados', error: error, stackTrace: error.stackTrace);
        }
        return switch (await _authSessionRepository.fetch()) {
          Ok(value: (:final session, remember: _)?) => Result.ok(session),
          _ => const Result.ok(null),
        };

      case Error<bool>(:final error):
        // Só o disco falhou: a sessão nova já está em memória e vale nesta execução.
        _log.warning('Sessão renovada, mas não foi possível guardá-la', error: error, stackTrace: error.stackTrace);
        return Result.ok(next);
    }
  }
}

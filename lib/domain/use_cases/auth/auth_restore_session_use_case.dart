import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';

/// Restaura a sessão guardada na abertura do app:
/// - sem "Lembrar-me" → descarta (só existe no disco se gravada por versão antiga);
/// - refresh token expirado → descarta;
/// - access token válido → usa;
/// - access expirado → renova; backend recusou → descarta;
/// - backend fora do ar → mantém o usuário; o `AuthInterceptor` renova na primeira chamada à API.
class AuthRestoreSessionUseCase({
  required final AuthSessionRepository _authSessionRepository,
  required final AuthRefreshSessionUseCase _authRefreshSessionUseCase,
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

        return _refresh(session);
    }
  }

  Future<Result<AuthSessionUser?>> _refresh(AuthSession session) async {
    switch (await _authRefreshSessionUseCase.refresh()) {
      case Ok<AuthSession?>(value: final renewed?):
        return Result.ok(renewed.user);

      case Ok<AuthSession?>():
        return _discard();

      case Error<AuthSession?>(:final error):
        _log.warning('Não foi possível renovar a sessão agora; mantendo o usuário', error: error, stackTrace: error.stackTrace);
        return Result.ok(session.user);
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

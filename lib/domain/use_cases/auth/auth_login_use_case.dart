import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

class AuthLoginUseCase({
  required final AuthRepository _authRepository,
  required final AuthSessionRepository _authSessionRepository,
}) {
  Future<Result<AuthSessionUser>> login({required String login, required String password, required bool remember}) async {
    final authenticated = await _authRepository.login(login: login, password: password);

    switch (authenticated) {
      case Ok<AuthSession>(value: final session):
        final saved = await _authSessionRepository.save(session, remember: remember);
        return switch (saved) {
          Ok<void>() => Result.ok(session.user),
          Error<void>(:final error) => Result.error(error),
        };

      case Error<AuthSession>(:final error):
        return Result.error(error);
    }
  }
}

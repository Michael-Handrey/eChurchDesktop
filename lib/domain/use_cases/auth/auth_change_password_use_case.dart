import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';

/// Troca a senha e renova a sessão: o token atual ainda carrega a marca de
/// primeiro acesso, e só um token novo libera o resto da API.
///
/// - `Ok(usuário)` → senha trocada e sessão renovada;
/// - `Ok(null)` → senha trocada, mas a renovação falhou: o usuário precisa entrar de novo;
/// - `Error` → a senha **não** foi trocada (senha atual incorreta, regra de força, rede...).
class AuthChangePasswordUseCase({
  required final AccountRepository _accountRepository,
  required final AuthRefreshSessionUseCase _authRefreshSessionUseCase,
}) {
  final _log = AppLogger('AuthChangePasswordUseCase');

  Future<Result<AuthSessionUser?>> changePassword({required String currentPassword, required String newPassword}) async {
    final changed = await _accountRepository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    if (changed case Error(:final error)) return Result.error(error);

    switch (await _authRefreshSessionUseCase.refresh()) {
      case Ok<AuthSession?>(value: final session?):
        return Result.ok(session.user);

      case Ok<AuthSession?>():
        _log.warning('Senha trocada, mas a sessão não foi renovada');
        return const Result.ok(null);

      case Error<AuthSession?>(:final error):
        _log.warning('Senha trocada, mas a sessão não foi renovada', error: error, stackTrace: error.stackTrace);
        return const Result.ok(null);
    }
  }
}

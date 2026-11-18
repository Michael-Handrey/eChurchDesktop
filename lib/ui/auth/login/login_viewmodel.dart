import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_login_use_case.dart';
import 'package:flutter/foundation.dart';

typedef LoginCredentials = ({String login, String password});

class LoginViewModel({
  required final AuthLoginUseCase _loginUseCase,
  required final AuthSessionNotifier _sessionNotifier,
}) extends ChangeNotifier {
  final _log = AppLogger('LoginViewModel');
  late final login = Command1<void, LoginCredentials>(_login);

  var _rememberMe = true;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  Future<Result<void>> _login(LoginCredentials credentials) async {
    final result = await _loginUseCase.login(login: credentials.login, password: credentials.password, remember: _rememberMe);

    switch (result) {
      case Ok<AuthSessionUser>(:final value):
        _sessionNotifier.signedIn(value);
        return Result.done;
      case Error<AuthSessionUser>(:final error):
        _log.error('Falha ao entrar', error: error, stackTrace: error.stackTrace);
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    login.dispose();
    super.dispose();
  }
}

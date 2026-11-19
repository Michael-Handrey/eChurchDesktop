import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/auth/password_policy.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_change_password_use_case.dart';
import 'package:flutter/foundation.dart';

typedef PasswordChange = ({String currentPassword, String newPassword});

class FirstAccessViewModel({
  required final AuthChangePasswordUseCase _changePasswordUseCase,
  required final AuthSessionNotifier _sessionNotifier,
}) extends ChangeNotifier {
  final _log = AppLogger('FirstAccessViewModel');

  late final changePassword = Command1<void, PasswordChange>(_changePassword);
  late final logout = Command0<void>(_logout);

  var _mustSignInAgain = false;

  /// Senha trocada, mas a sessão não foi renovada: a tela avisa e faz logout.
  bool get mustSignInAgain => _mustSignInAgain;

  String get firstName => (_sessionNotifier.user?.name ?? '').trim().split(RegExp(r'\s+')).first;

  String get _login => _sessionNotifier.user?.login ?? '';

  List<PasswordRuleCheck> rulesFor(String password) => PasswordPolicy.check(password, _login);

  bool canSubmit({required String currentPassword, required String newPassword, required String confirmation}) => currentPassword.isNotEmpty && newPassword != currentPassword && newPassword == confirmation && PasswordPolicy.accepts(newPassword, _login);

  Future<Result<void>> _changePassword(PasswordChange change) async {
    final result = await _changePasswordUseCase.changePassword(currentPassword: change.currentPassword, newPassword: change.newPassword);

    switch (result) {
      case Ok<AuthSessionUser?>(value: final user?):
        _sessionNotifier.passwordChanged(user);
        return Result.done;

      case Ok<AuthSessionUser?>():
        _mustSignInAgain = true;
        return Result.done;

      case Error<AuthSessionUser?>(:final error):
        _log.error('Falha ao trocar a senha', error: error, stackTrace: error.stackTrace);
        return Result.error(error);
    }
  }

  Future<Result<void>> _logout() async {
    await _sessionNotifier.logout();
    return Result.done;
  }

  @override
  void dispose() {
    changePassword.dispose();
    logout.dispose();
    super.dispose();
  }
}

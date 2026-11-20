import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/auth/password_policy.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_change_password_use_case.dart';
import 'package:echurch_desktop/ui/auth/first_access/first_access_viewmodel.dart' show PasswordChange;
import 'package:flutter/foundation.dart';

/// Troca da própria senha com o sistema aberto (a de primeiro acesso é a `FirstAccessScreen`).
class ChangePasswordViewModel({
  required final AuthChangePasswordUseCase _changePasswordUseCase,
  required final AuthSessionNotifier _sessionNotifier,
}) extends ChangeNotifier {
  final _log = AppLogger('ChangePasswordViewModel');

  late final changePassword = Command1<void, PasswordChange>(_changePassword);

  var _mustSignInAgain = false;

  /// Senha trocada, mas a sessão não foi renovada: o usuário precisa entrar de novo.
  bool get mustSignInAgain => _mustSignInAgain;

  String get _login => _sessionNotifier.user?.login ?? '';

  List<PasswordRuleCheck> rulesFor(String password) => PasswordPolicy.check(password, _login);

  bool canSubmit({required String currentPassword, required String newPassword, required String confirmation}) => currentPassword.isNotEmpty && newPassword != currentPassword && newPassword == confirmation && PasswordPolicy.accepts(newPassword, _login);

  Future<void> signInAgain() => _sessionNotifier.logout();

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
        _log.error('Falha ao alterar a senha', error: error, stackTrace: error.stackTrace);
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    changePassword.dispose();
    super.dispose();
  }
}

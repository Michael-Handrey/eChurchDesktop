import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/app_password_field.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/share/password_rules.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

enum _PasswordMode { generate, choose }

/// Confirma a redefinição e deixa o administrador escolher entre gerar a senha
/// provisória ou digitar uma. Fecha devolvendo o [PasswordReset] quando dá certo.
class const ResetPasswordDialog({
  super.key,
  required final UsersViewModel viewModel,
  required final ManagedUser user,
}) extends StatefulWidget {
  static Future<PasswordReset?> show(BuildContext context, {required UsersViewModel viewModel, required ManagedUser user}) => showDialog<PasswordReset>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ResetPasswordDialog(viewModel: viewModel, user: user),
  );

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _password = TextEditingController();
  var _mode = _PasswordMode.generate;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.viewModel.resetPassword.addListener(_onResult);
    _password.addListener(() => setState(() => _error = null));
  }

  void _onResult() {
    final command = widget.viewModel.resetPassword;
    switch (command.result) {
      case Ok<PasswordReset>(:final value):
        command.clearResult();
        Navigator.of(context).pop(value);
      case Error<PasswordReset>(:final error):
        command.clearResult();
        setState(() => _error = ErrorMessages.of(error));
      case null:
        setState(() {}); // running mudou
    }
  }

  bool get _canSubmit => _mode == _PasswordMode.generate || widget.viewModel.acceptsPassword(_password.text, widget.user);

  void _submit() {
    if (!_canSubmit || widget.viewModel.resetPassword.running) return;
    final password = _mode == _PasswordMode.choose ? _password.text : null;
    widget.viewModel.resetPassword.execute((user: widget.user, password: password));
  }

  @override
  void dispose() {
    widget.viewModel.resetPassword.removeListener(_onResult);
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.resetPassword.running;

    return AlertDialog(
      icon: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
      title: Text('Redefinir a senha de ${widget.user.name}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              const Text(
                'O usuário vai receber uma senha provisória e terá que cadastrar uma nova no próximo acesso. '
                'As sessões abertas dele serão encerradas.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
              ),
              SegmentedButton<_PasswordMode>(
                segments: const [
                  ButtonSegment(value: .generate, icon: Icon(Icons.auto_awesome_outlined), label: Text('Gerar automaticamente')),
                  ButtonSegment(value: .choose, icon: Icon(Icons.edit_outlined), label: Text('Definir senha')),
                ],
                selected: {_mode},
                onSelectionChanged: running
                    ? null
                    : (selection) => setState(() {
                        _mode = selection.first;
                        _error = null;
                      }),
              ),
              if (_mode == _PasswordMode.generate)
                const Text(
                  'O sistema cria uma senha forte, que será mostrada uma única vez para você repassar.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                )
              else ...[
                AppPasswordField(
                  controller: _password,
                  enabled: !running,
                  autofocus: true,
                  label: 'Senha provisória',
                  hint: 'Digite a senha provisória',
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: _submit,
                ),
                PasswordRulesWidget(rules: widget.viewModel.rulesFor(_password.text, widget.user)),
              ],
              if (_error case final message?) AppErrorBanner(message: message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running || !_canSubmit ? null : _submit,
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Redefinir senha'),
        ),
      ],
    );
  }
}

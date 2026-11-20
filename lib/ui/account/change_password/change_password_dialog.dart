import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/ui/account/change_password/change_password_bindings.dart';
import 'package:echurch_desktop/ui/account/change_password/change_password_viewmodel.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/app_password_field.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/share/password_rules.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// "Alterar minha senha": senha atual, nova senha (com as regras) e confirmação.
class const ChangePasswordDialog({super.key, required final ChangePasswordViewModel viewModel}) extends StatefulWidget {
  /// Abre o diálogo com as dependências dele e avisa quando a senha foi alterada.
  static Future<void> show(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordBindings(screenBuilder: (context) => ChangePasswordDialog(viewModel: context.read())),
    );
    if ((changed ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada.')));
    }
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  ChangePasswordViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.changePassword.addListener(_onResult);
    for (final controller in [_current, _new, _confirmation]) {
      controller.addListener(() => setState(() => _error = null));
    }
  }

  void _onResult() {
    final command = _viewModel.changePassword;
    switch (command.result) {
      case Ok<void>():
        command.clearResult();
        // Sem sessão renovada, o diálogo mostra o aviso e o botão de entrar de novo.
        if (_viewModel.mustSignInAgain) {
          setState(() {});
        } else {
          Navigator.of(context).pop(true);
        }
      case Error<void>(:final error):
        command.clearResult();
        setState(() => _error = ErrorMessages.of(error));
      case null:
        setState(() {}); // running mudou
    }
  }

  bool get _canSubmit => _viewModel.canSubmit(currentPassword: _current.text, newPassword: _new.text, confirmation: _confirmation.text);

  void _submit() {
    if (!_canSubmit || _viewModel.changePassword.running) return;
    _viewModel.changePassword.execute((currentPassword: _current.text, newPassword: _new.text));
  }

  @override
  void dispose() {
    _viewModel.changePassword.removeListener(_onResult);
    _current.dispose();
    _new.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.mustSignInAgain) {
      return AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
        title: const Text('Senha alterada'),
        content: const Text('Entre novamente com a nova senha para continuar.'),
        actions: [
          FilledButton(
            onPressed: () {
              // Fecha antes: o logout troca a tela pelo login.
              final signInAgain = _viewModel.signInAgain;
              Navigator.of(context).pop(false);
              signInAgain();
            },
            child: const Text('Entrar novamente'),
          ),
        ],
      );
    }

    final running = _viewModel.changePassword.running;
    final sameAsCurrent = _new.text.isNotEmpty && _new.text == _current.text;
    final mismatch = _confirmation.text.isNotEmpty && _confirmation.text != _new.text;

    return AlertDialog(
      icon: const Icon(Icons.key_outlined, color: AppColors.primary),
      title: const Text('Alterar minha senha'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              AppPasswordField(
                controller: _current,
                enabled: !running,
                autofocus: true,
                label: 'Senha atual',
                hint: 'Digite a senha que você usa hoje',
                textInputAction: .next,
              ),
              AppPasswordField(
                controller: _new,
                enabled: !running,
                label: 'Nova senha',
                hint: 'Crie sua nova senha',
                textInputAction: .next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              PasswordRulesWidget(rules: _viewModel.rulesFor(_new.text)),
              if (sameAsCurrent) const _Hint('A nova senha precisa ser diferente da atual.'),
              AppPasswordField(
                controller: _confirmation,
                enabled: !running,
                label: 'Confirme a nova senha',
                hint: 'Digite a nova senha de novo',
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: _submit,
              ),
              if (mismatch) const _Hint('As senhas não conferem.'),
              if (_error case final message?) AppErrorBanner(message: message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running || !_canSubmit ? null : _submit,
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Alterar senha'),
        ),
      ],
    );
  }
}

class const _Hint(final String text) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.error, fontSize: 12.5));
}

import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/ui/auth/first_access/first_access_viewmodel.dart';
import 'package:echurch_desktop/ui/auth/first_access/widgets/first_access_form.dart';
import 'package:echurch_desktop/ui/auth/login/widgets/brand_panel.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Troca obrigatória da senha provisória. Ao trocar, o redirect do router
/// (sessão sem a marca de primeiro acesso) leva ao dashboard.
class const FirstAccessScreen({super.key, required final FirstAccessViewModel viewModel}) extends StatefulWidget {
  @override
  State<FirstAccessScreen> createState() => _FirstAccessScreenState();
}

class _FirstAccessScreenState extends State<FirstAccessScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirmation = TextEditingController();
  final _errorMessage = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    widget.viewModel.changePassword.addListener(_onChangePasswordResult);
    for (final controller in [_current, _new, _confirmation]) {
      controller.addListener(_clearError);
    }
  }

  void _onChangePasswordResult() {
    final command = widget.viewModel.changePassword;
    switch (command.result) {
      case Ok():
        command.clearResult();
        _onPasswordChanged();
      case Error(:final error):
        command.clearResult();
        _errorMessage.value = ErrorMessages.of(error);
      case null:
        break;
    }
  }

  void _onPasswordChanged() {
    // O ScaffoldMessenger é do MaterialApp: o aviso continua visível após o redirect.
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (widget.viewModel.mustSignInAgain) {
      messenger?.showSnackBar(const SnackBar(content: Text('Senha alterada. Entre novamente com a nova senha.')));
      widget.viewModel.logout.execute();
      return;
    }

    messenger?.showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso.')));
  }

  void _clearError() => _errorMessage.value = null;

  bool get _canSubmit => widget.viewModel.canSubmit(currentPassword: _current.text, newPassword: _new.text, confirmation: _confirmation.text);

  void _submit() {
    if (!_canSubmit || widget.viewModel.changePassword.running) return;
    widget.viewModel.changePassword.execute((currentPassword: _current.text, newPassword: _new.text));
  }

  @override
  void dispose() {
    widget.viewModel.changePassword.removeListener(_onChangePasswordResult);
    _current.dispose();
    _new.dispose();
    _confirmation.dispose();
    _errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const Expanded(flex: 5, child: LoginBrandPanelWidget()),
          Expanded(
            flex: 6,
            child: ListenableBuilder(
              listenable: Listenable.merge([viewModel.changePassword, viewModel.logout, _current, _new, _confirmation, _errorMessage]),
              builder: (context, _) {
                final busy = viewModel.changePassword.running || viewModel.logout.running;

                return FirstAccessFormWidget(
                  firstName: viewModel.firstName,
                  currentController: _current,
                  newController: _new,
                  confirmationController: _confirmation,
                  rules: viewModel.rulesFor(_new.text),
                  confirmationMismatch: _confirmation.text.isNotEmpty && _confirmation.text != _new.text,
                  sameAsCurrent: _new.text.isNotEmpty && _new.text == _current.text,
                  isLoading: busy,
                  errorMessage: _errorMessage.value,
                  onSubmit: _canSubmit ? _submit : null,
                  onLogout: busy ? null : viewModel.logout.execute,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

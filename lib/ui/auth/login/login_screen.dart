import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/ui/auth/login/login_viewmodel.dart';
import 'package:echurch_desktop/ui/auth/login/widgets/brand_panel.dart';
import 'package:echurch_desktop/ui/auth/login/widgets/login_form.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Após o login, o redirect do router (refreshListenable = [AuthSessionNotifier])
/// leva ao dashboard; a tela só trata loading e erro.
class const LoginScreen({
  super.key,
  required final LoginViewModel viewModel,
  required final AuthSessionNotifier session,
}) extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _errorMessage = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    widget.viewModel.login.addListener(_onLoginResult);
    _login.addListener(_clearError);
    _password.addListener(_clearError);
  }

  void _onLoginResult() {
    final command = widget.viewModel.login;
    if (command.result case Error(:final error)) {
      command.clearResult();
      _errorMessage.value = ErrorMessages.of(error);
    }
  }

  void _clearError() => _errorMessage.value = null;

  void _submit() {
    final login = _login.text.trim();
    final password = _password.text;
    if (login.isEmpty || password.isEmpty || widget.viewModel.login.running) return;

    widget.viewModel.login.execute((login: login, password: password));
  }

  /// Sem recuperação automática por enquanto (por e-mail está no ROADMAP):
  /// o administrador gera uma senha provisória, trocada no primeiro acesso.
  Future<void> _showForgotPassword() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
      title: const Text('Esqueceu a senha?'),
      content: const Text(
        'Fale com o administrador da igreja. Ele vai gerar uma senha provisória para você.\n\n'
        'No próximo acesso, entre com ela e cadastre uma nova senha.',
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendi')),
      ],
    ),
  );

  @override
  void dispose() {
    widget.viewModel.login.removeListener(_onLoginResult);
    _login.dispose();
    _password.dispose();
    _errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const Expanded(flex: 5, child: LoginBrandPanelWidget()),
          Expanded(
            flex: 6,
            child: ListenableBuilder(
              listenable: Listenable.merge([widget.session, widget.viewModel, widget.viewModel.login, _login, _password, _errorMessage]),
              builder: (context, _) {
                // Restaurando a sessão guardada: evita mostrar o formulário por um instante antes do redirect.
                if (!widget.session.isRestored) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final filled = _login.text.trim().isNotEmpty && _password.text.isNotEmpty;

                return LoginFormWidget(
                  loginController: _login,
                  passwordController: _password,
                  rememberMe: widget.viewModel.rememberMe,
                  onToggleRememberMe: widget.viewModel.toggleRememberMe,
                  onForgotPassword: _showForgotPassword,
                  isLoading: widget.viewModel.login.running,
                  errorMessage: _errorMessage.value,
                  onSubmit: filled ? _submit : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

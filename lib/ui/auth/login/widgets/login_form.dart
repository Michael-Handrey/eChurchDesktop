import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/app_password_field.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

class const LoginFormWidget({
  super.key,
  required final TextEditingController loginController,
  required final TextEditingController passwordController,
  required final bool rememberMe,
  required final VoidCallback onToggleRememberMe,
  required final bool isLoading,
  required final VoidCallback onForgotPassword,
  final String? errorMessage,
  final VoidCallback? onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const .symmetric(horizontal: 24, vertical: 32),
          child: AutofillGroup(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              children: [
                const LoginHeaderWidget(),
                const SizedBox(height: 32),
                LoginUserInputWidget(controller: loginController, enabled: !isLoading),
                const SizedBox(height: 20),
                AppPasswordField(controller: passwordController, enabled: !isLoading, onSubmitted: onSubmit),
                const SizedBox(height: 16),
                LoginRememberForgotRowWidget(rememberMe: rememberMe, onToggleRememberMe: isLoading ? null : onToggleRememberMe, onForgotPassword: onForgotPassword),
                if (errorMessage case final message?) ...[
                  const SizedBox(height: 16),
                  AppErrorBanner(message: message),
                ],
                const SizedBox(height: 28),
                LoginSubmitButtonWidget(isLoading: isLoading, onPressed: onSubmit),
                const SizedBox(height: 32),
                const LoginSupportFooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class const LoginHeaderWidget({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          'Bem-vindo de volta',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Informe suas credenciais para acessar o painel da igreja.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class const LoginUserInputWidget({
  super.key,
  required final TextEditingController controller,
  required final bool enabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppFieldShell(
      label: 'Usuário',
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: true,
        textInputAction: .next,
        autofillHints: const [AutofillHints.username],
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          hintText: 'Seu login de acesso',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: .symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class const LoginRememberForgotRowWidget({
  super.key,
  required final bool rememberMe,
  required final VoidCallback onForgotPassword,
  final VoidCallback? onToggleRememberMe,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        InkWell(
          onTap: onToggleRememberMe,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const .symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: .min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: onToggleRememberMe == null ? null : (_) => onToggleRememberMe!(),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Lembrar-me', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onForgotPassword,
          style: TextButton.styleFrom(padding: const .symmetric(horizontal: 4, vertical: 2)),
          child: const Text(
            'Esqueceu a senha?',
            style: TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class const LoginSubmitButtonWidget({
  super.key,
  required final bool isLoading,
  final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: isLoading ? .85 : .45),
          disabledForegroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.textOnPrimary),
              )
            : const Row(
                mainAxisAlignment: .center,
                children: [
                  Text('Entrar no Sistema', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}

class const LoginSupportFooterWidget({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text.rich(
        TextSpan(
          text: 'Problemas no acesso? ',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          children: [
            TextSpan(
              text: 'Fale com o suporte da igreja',
              style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

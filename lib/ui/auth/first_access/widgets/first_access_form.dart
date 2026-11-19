import 'package:echurch_desktop/domain/models/auth/password_policy.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/app_password_field.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

class const FirstAccessFormWidget({
  super.key,
  required final String firstName,
  required final TextEditingController currentController,
  required final TextEditingController newController,
  required final TextEditingController confirmationController,
  required final List<PasswordRuleCheck> rules,
  required final bool confirmationMismatch,
  required final bool sameAsCurrent,
  required final bool isLoading,
  final String? errorMessage,
  final VoidCallback? onSubmit,
  final VoidCallback? onLogout,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const .symmetric(horizontal: 24, vertical: 32),
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: .center,
                crossAxisAlignment: .stretch,
                children: [
                  FirstAccessHeaderWidget(firstName: firstName),
                  const SizedBox(height: 28),
                  AppPasswordField(
                    controller: currentController,
                    enabled: !isLoading,
                    autofocus: true,
                    label: 'Senha provisória',
                    hint: 'A senha que você recebeu',
                    textInputAction: .next,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 20),
                  AppPasswordField(
                    controller: newController,
                    enabled: !isLoading,
                    label: 'Nova senha',
                    hint: 'Crie sua senha',
                    textInputAction: .next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 12),
                  PasswordRulesWidget(rules: rules),
                  if (sameAsCurrent) ...[
                    const SizedBox(height: 6),
                    const _FieldHint('A nova senha deve ser diferente da provisória.'),
                  ],
                  const SizedBox(height: 20),
                  AppPasswordField(
                    controller: confirmationController,
                    enabled: !isLoading,
                    label: 'Confirme a nova senha',
                    hint: 'Digite a nova senha de novo',
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: onSubmit,
                  ),
                  if (confirmationMismatch) ...[
                    const SizedBox(height: 6),
                    const _FieldHint('As senhas não conferem.'),
                  ],
                  if (errorMessage case final message?) ...[
                    const SizedBox(height: 16),
                    AppErrorBanner(message: message),
                  ],
                  const SizedBox(height: 28),
                  FirstAccessSubmitButtonWidget(isLoading: isLoading, onPressed: onSubmit),
                  const SizedBox(height: 12),
                  TextButton(onPressed: onLogout, child: const Text('Sair e trocar depois')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const FirstAccessHeaderWidget({super.key, required final String firstName}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          firstName.isEmpty ? 'Crie sua senha' : 'Olá, $firstName',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Você entrou com uma senha provisória. Para continuar, cadastre uma senha só sua.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}

/// Checagem ao vivo das regras de força da senha.
class const PasswordRulesWidget({super.key, required final List<PasswordRuleCheck> rules}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 4,
      children: [
        for (final rule in rules)
          Semantics(
            label: '${rule.label}: ${rule.passed ? 'atendido' : 'pendente'}',
            excludeSemantics: true,
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  rule.passed ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: rule.passed ? AppColors.success : AppColors.textMuted,
                ),
                Text(
                  rule.label,
                  style: TextStyle(color: rule.passed ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class const _FieldHint(final String text) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.error, fontSize: 12.5));
  }
}

class const FirstAccessSubmitButtonWidget({
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
            : const Text('Salvar nova senha', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
      ),
    );
  }
}

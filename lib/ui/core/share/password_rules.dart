import 'package:echurch_desktop/domain/models/auth/password_policy.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Checagem ao vivo das regras de força da senha ([PasswordPolicy.check]).
/// Usado na troca de senha do primeiro acesso e na redefinição pelo administrador.
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

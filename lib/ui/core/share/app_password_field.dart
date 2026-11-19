import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Rótulo + caixa com o visual padrão dos campos de formulário.
class const AppFieldShell({super.key, required final String label, required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// Campo de senha com o botão de mostrar/ocultar.
class const AppPasswordField({
  super.key,
  required final TextEditingController controller,
  required final bool enabled,
  final String label = 'Senha de Acesso',
  final String hint = 'Digite sua senha',
  final bool autofocus = false,
  final TextInputAction textInputAction = .done,
  final Iterable<String> autofillHints = const [AutofillHints.password],
  final VoidCallback? onSubmitted,
}) extends StatefulWidget {
  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  // Estado efêmero de UI: só esta caixa precisa saber.
  final _obscured = ValueNotifier(true);

  @override
  void dispose() {
    _obscured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFieldShell(
      label: widget.label,
      child: ValueListenableBuilder(
        valueListenable: _obscured,
        builder: (context, obscured, _) => TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          obscureText: obscured,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
            suffixIcon: IconButton(
              onPressed: () => _obscured.value = !obscured,
              tooltip: obscured ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(
                obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const .symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }
}

import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Confirmação simples (sim/não). Devolve `true` quando confirmou.
class const ConfirmDialog({
  super.key,
  required final IconData icon,
  required final Color color,
  required final String title,
  required final String message,
  required final String confirmLabel,
}) extends StatelessWidget {
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    Color color = AppColors.primary,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmDialog(icon: icon, color: color, title: title, message: message, confirmLabel: confirmLabel),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, color: color),
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(message, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: color),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

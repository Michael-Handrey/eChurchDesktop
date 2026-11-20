import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Mostra a senha provisória uma única vez: depois de fechar, ela não pode ser vista de novo.
class const TemporaryPasswordDialog({super.key, required final String userName, required final PasswordReset reset}) extends StatefulWidget {
  static Future<void> show(BuildContext context, {required String userName, required PasswordReset reset}) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TemporaryPasswordDialog(userName: userName, reset: reset),
  );

  @override
  State<TemporaryPasswordDialog> createState() => _TemporaryPasswordDialogState();
}

class _TemporaryPasswordDialogState extends State<TemporaryPasswordDialog> {
  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.reset.temporaryPassword));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
      title: const Text('Senha provisória definida'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 14,
          children: [
            Text.rich(
              TextSpan(
                text: 'Repasse a senha abaixo para ',
                children: [
                  TextSpan(
                    text: widget.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' (login ${widget.reset.login}). No próximo acesso, o sistema vai pedir uma nova senha.'),
                ],
              ),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            Container(
              padding: const .symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.reset.temporaryPassword,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: AppColors.textPrimary),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _copy,
                    icon: Icon(_copied ? Icons.check : Icons.copy_outlined, size: 18),
                    label: Text(_copied ? 'Copiada' : 'Copiar'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const .symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                crossAxisAlignment: .start,
                spacing: 8,
                children: [
                  Icon(Icons.warning_amber_outlined, size: 18, color: AppColors.warning),
                  Expanded(
                    child: Text(
                      'Esta senha aparece só agora. Ao fechar, não será possível vê-la de novo: '
                      'se ela se perder, redefina outra vez.',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Concluir'))],
    );
  }
}

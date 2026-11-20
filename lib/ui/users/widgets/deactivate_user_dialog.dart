import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Confirma a desativação do usuário. Fecha devolvendo `true` quando desativou.
class const DeactivateUserDialog({
  super.key,
  required final UsersViewModel viewModel,
  required final ManagedUser user,
}) extends StatefulWidget {
  static Future<bool?> show(BuildContext context, {required UsersViewModel viewModel, required ManagedUser user}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DeactivateUserDialog(viewModel: viewModel, user: user),
  );

  @override
  State<DeactivateUserDialog> createState() => _DeactivateUserDialogState();
}

class _DeactivateUserDialogState extends State<DeactivateUserDialog> {
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.viewModel.setActive.addListener(_onResult);
  }

  void _onResult() {
    final command = widget.viewModel.setActive;
    switch (command.result) {
      case Ok<void>():
        command.clearResult();
        Navigator.of(context).pop(true);
      case Error<void>(:final error):
        command.clearResult();
        setState(() => _error = ErrorMessages.of(error));
      case null:
        setState(() {}); // running mudou
    }
  }

  @override
  void dispose() {
    widget.viewModel.setActive.removeListener(_onResult);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.setActive.running;

    return AlertDialog(
      icon: const Icon(Icons.person_off_outlined, color: AppColors.error),
      title: Text('Desativar ${widget.user.name}?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 12,
          children: [
            const Text(
              'O usuário não vai mais conseguir entrar no sistema. Se estiver usando agora, '
              'o acesso é encerrado em até 15 minutos. Os dados dele continuam guardados, '
              'e você pode reativá-lo quando quiser.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            if (_error case final message?) AppErrorBanner(message: message),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running ? null : () => widget.viewModel.setActive.execute((user: widget.user, active: false)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Desativar'),
        ),
      ],
    );
  }
}

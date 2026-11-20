import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/access_labels.dart';
import 'package:echurch_desktop/ui/users/groups_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Confirma a exclusão de um grupo sem usuários. Fecha devolvendo `true` quando excluiu.
class const DeleteGroupDialog({
  super.key,
  required final GroupsViewModel viewModel,
  required final SecurityGroup group,
}) extends StatefulWidget {
  static Future<bool?> show(BuildContext context, {required GroupsViewModel viewModel, required SecurityGroup group}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DeleteGroupDialog(viewModel: viewModel, group: group),
  );

  @override
  State<DeleteGroupDialog> createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends State<DeleteGroupDialog> {
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.viewModel.delete.addListener(_onResult);
  }

  void _onResult() {
    final command = widget.viewModel.delete;
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
    widget.viewModel.delete.removeListener(_onResult);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.delete.running;

    return AlertDialog(
      icon: const Icon(Icons.delete_outline, color: AppColors.error),
      title: Text('Excluir o grupo ${AccessLabels.group(widget.group.name)}?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 12,
          children: [
            const Text('O grupo não tem usuários. Essa ação não pode ser desfeita.', style: TextStyle(color: AppColors.textSecondary)),
            if (_error case final message?) AppErrorBanner(message: message),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running ? null : () => widget.viewModel.delete.execute(widget.group),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Excluir'),
        ),
      ],
    );
  }
}

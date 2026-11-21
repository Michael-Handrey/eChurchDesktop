import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Desativa um membro (membros não são excluídos). Motivo e descrição obrigatórios.
/// Fecha devolvendo `true`.
class const DeactivateMemberDialog({super.key, required final MembersViewModel viewModel, required final MemberRow member}) extends StatefulWidget {
  static Future<bool?> show(BuildContext context, {required MembersViewModel viewModel, required MemberRow member}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DeactivateMemberDialog(viewModel: viewModel, member: member),
  );

  @override
  State<DeactivateMemberDialog> createState() => _DeactivateMemberDialogState();
}

class _DeactivateMemberDialogState extends State<DeactivateMemberDialog> {
  final _description = TextEditingController();
  DeactivationReason? _reason;
  String? _error;

  bool get _valid => _reason != null && _description.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.viewModel.deactivate.addListener(_onResult);
    _description.addListener(() => setState(() {}));
  }

  void _onResult() {
    final command = widget.viewModel.deactivate;
    switch (command.result) {
      case Ok<MemberDetails>():
        command.clearResult();
        Navigator.of(context).pop(true);
      case Error<MemberDetails>(:final error):
        command.clearResult();
        setState(() => _error = ErrorMessages.of(error));
      case null:
        setState(() {}); // running mudou
    }
  }

  @override
  void dispose() {
    widget.viewModel.deactivate.removeListener(_onResult);
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason;
    if (reason == null || !_valid) return;
    widget.viewModel.deactivate.execute((member: widget.member, reason: reason, description: _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.deactivate.running;

    return AlertDialog(
      icon: const Icon(Icons.person_off_outlined, color: AppColors.error),
      title: const Text('Desativar membro'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 480),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 12,
          children: [
            Text(widget.member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Text(
              'O membro sai da lista de ativos, mas o cadastro continua guardado e pode ser reativado depois.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            DropdownButtonFormField<DeactivationReason>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: [
                for (final reason in DeactivationReason.values)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(reason.label, overflow: .ellipsis),
                  ),
              ],
              onChanged: running ? null : (reason) => setState(() => _reason = reason),
            ),
            TextField(
              controller: _description,
              enabled: !running,
              minLines: 2,
              maxLines: 4,
              maxLength: MembersViewModel.maxDescription,
              decoration: const InputDecoration(labelText: 'Descrição', hintText: 'Ex.: transferido para a igreja de Londrina em 10/11.', alignLabelWithHint: true),
            ),
            if (_error case final message?) AppErrorBanner(message: message),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running || !_valid ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Desativar'),
        ),
      ],
    );
  }
}

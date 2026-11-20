import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/groups_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Cria ([group] nulo) ou altera um grupo: nome e permissões. Fecha devolvendo `true` quando salvou.
class const GroupFormDialog({
  super.key,
  required final GroupsViewModel viewModel,
  final SecurityGroup? group,
}) extends StatefulWidget {
  static Future<bool?> show(BuildContext context, {required GroupsViewModel viewModel, SecurityGroup? group}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => GroupFormDialog(viewModel: viewModel, group: group),
  );

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  late final _name = TextEditingController(text: widget.group?.name ?? '');
  late final _selected = {...?widget.group?.permissions};
  String? _error;

  bool get _isNew => widget.group == null;

  @override
  void initState() {
    super.initState();
    widget.viewModel.save.addListener(_onResult);
    _name.addListener(() => setState(() => _error = null));
  }

  void _onResult() {
    final command = widget.viewModel.save;
    switch (command.result) {
      case Ok<SecurityGroup>():
        command.clearResult();
        Navigator.of(context).pop(true);
      case Error<SecurityGroup>(:final error):
        command.clearResult();
        setState(() => _error = ErrorMessages.of(error));
      case null:
        setState(() {}); // running mudou
    }
  }

  String? get _nameProblem => widget.viewModel.nameProblem(_name.text, id: widget.group?.id);

  void _toggle(String permission, bool selected) => setState(() {
    selected ? _selected.add(permission) : _selected.remove(permission);
    _error = null;
  });

  void _submit() {
    if (_nameProblem != null || widget.viewModel.save.running) return;
    widget.viewModel.save.execute((id: widget.group?.id, name: _name.text, permissions: {..._selected}));
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_onResult);
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.save.running;
    // "Informe o nome" só aparece depois que algo foi digitado.
    final nameProblem = _name.text.isEmpty ? null : _nameProblem;

    return AlertDialog(
      icon: Icon(_isNew ? Icons.group_add_outlined : Icons.edit_outlined, color: AppColors.primary),
      title: Text(_isNew ? 'Novo grupo' : 'Editar grupo'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 14,
            children: [
              TextField(
                controller: _name,
                enabled: !running,
                autofocus: _isNew,
                maxLength: 100,
                decoration: InputDecoration(labelText: 'Nome do grupo', hintText: 'Ex.: Tesouraria', errorText: nameProblem),
                onSubmitted: (_) => _submit(),
              ),
              const Text(
                'Permissões',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    for (final option in widget.viewModel.permissionOptions)
                      CheckboxListTile(
                        value: _selected.contains(option.name),
                        onChanged: running ? null : (value) => _toggle(option.name, value ?? false),
                        title: Text(option.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(option.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        controlAffinity: .leading,
                        dense: true,
                      ),
                  ],
                ),
              ),
              const Text(
                'As permissões são definidas pelo sistema: cada uma libera um conjunto de funções. '
                'A mudança vale para os usuários do grupo na próxima renovação da sessão (em até 15 minutos).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              if (_error case final message?) AppErrorBanner(message: message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running || _nameProblem != null ? null : _submit,
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isNew ? 'Criar grupo' : 'Salvar'),
        ),
      ],
    );
  }
}

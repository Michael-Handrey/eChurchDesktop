import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Igreja e grupos do usuário. Fecha devolvendo `true` quando salvou.
class const UserAccessDialog({
  super.key,
  required final UsersViewModel viewModel,
  required final ManagedUser user,
}) extends StatefulWidget {
  static Future<bool?> show(BuildContext context, {required UsersViewModel viewModel, required ManagedUser user}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UserAccessDialog(viewModel: viewModel, user: user),
  );

  @override
  State<UserAccessDialog> createState() => _UserAccessDialogState();
}

class _UserAccessDialogState extends State<UserAccessDialog> {
  late final _selected = {...widget.user.groupIds};
  late int? _churchId = widget.user.churchId;
  String? _error;

  ManagedUser get _user => widget.user;

  @override
  void initState() {
    super.initState();
    widget.viewModel.updateAccess.addListener(_onResult);
  }

  void _onResult() {
    final command = widget.viewModel.updateAccess;
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

  bool get _groupsChanged => _selected.length != _user.groupIds.length || !_selected.containsAll(_user.groupIds);

  bool get _changed => _churchId != _user.churchId || _groupsChanged;

  void _toggle(int id, bool selected) => setState(() {
    selected ? _selected.add(id) : _selected.remove(id);
    _error = null;
  });

  void _submit() {
    if (!_changed || _selected.isEmpty || widget.viewModel.updateAccess.running) return;
    widget.viewModel.updateAccess.execute((user: _user, churchId: _churchId, groupIds: {..._selected}));
  }

  @override
  void dispose() {
    widget.viewModel.updateAccess.removeListener(_onResult);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.updateAccess.running;
    final options = widget.viewModel.groupOptions;
    final churches = widget.viewModel.churches;

    return AlertDialog(
      icon: const Icon(Icons.manage_accounts_outlined, color: AppColors.primary),
      title: Text('Acesso de ${_user.name}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 12,
            children: [
              const _SectionTitle('Igreja'),
              DropdownButtonFormField<int>(
                // Igreja que não está na lista (ex.: excluída) aparece vazia até escolher outra.
                initialValue: churches.any((church) => church.id == _churchId) ? _churchId : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.church_outlined, size: 20),
                  hintText: 'Escolha a igreja',
                ),
                items: [for (final church in churches) DropdownMenuItem(value: church.id, child: Text(church.name))],
                onChanged: running
                    ? null
                    : (value) => setState(() {
                        _churchId = value;
                        _error = null;
                      }),
              ),
              const SizedBox(height: 4),
              const _SectionTitle('Grupos'),
              const Text(
                'As permissões do usuário são as dos grupos marcados. A mudança vale na próxima '
                'renovação da sessão dele (em até 15 minutos) ou quando ele entrar de novo.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              if (options.isEmpty)
                const Text('Nenhum grupo cadastrado. Crie um na aba "Grupos e permissões".')
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      for (final option in options)
                        CheckboxListTile(
                          value: _selected.contains(option.group.id),
                          onChanged: running ? null : (value) => _toggle(option.group.id, value ?? false),
                          title: Text(option.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(option.permissionsLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          controlAffinity: .leading,
                          dense: true,
                        ),
                    ],
                  ),
                ),
              // A API exige pelo menos um grupo (a entidade User não aceita usuário sem grupo).
              if (_selected.isEmpty && options.isNotEmpty)
                const Text(
                  'Escolha pelo menos um grupo.',
                  style: TextStyle(color: AppColors.error, fontSize: 12.5),
                ),
              if (_error case final message?) AppErrorBanner(message: message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running || !_changed || _selected.isEmpty ? null : _submit,
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}

class const _SectionTitle(final String text) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
  );
}

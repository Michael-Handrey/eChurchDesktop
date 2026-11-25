import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/confirm_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:echurch_desktop/ui/members/widgets/member_status_chip.dart';
import 'package:echurch_desktop/ui/ministries/ministries_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const MinistriesBindings({super.key, required final WidgetBuilder screenBuilder}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => MinistriesViewModel(repository: context.read(), members: context.read(), churchContext: context.read(), session: context.read()).initialized(),
    builder: (context, child) => screenBuilder(context),
  );
}

void _show(BuildContext context, String message) {
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Ministérios da igreja escolhida: tipo, nome, líder, vice-líder e membros. Secretaria/Administrador
/// cadastram, editam, desativam/reativam e mexem nos membros; quem só consulta vê.
class const MinistriesScreen({super.key, required final MinistriesViewModel viewModel}) extends StatelessWidget {
  Future<void> _edit(BuildContext context, [Ministry? ministry]) async {
    final saved = await MinistryFormDialog.show(context, viewModel: viewModel, ministry: ministry);
    if ((saved ?? false) && context.mounted) _show(context, ministry == null ? 'Ministério cadastrado.' : 'Ministério atualizado.');
  }

  Future<void> _toggleActive(BuildContext context, Ministry ministry) async {
    final deactivate = ministry.active;
    final confirmed = await ConfirmDialog.show(
      context,
      icon: deactivate ? Icons.block : Icons.restore,
      color: deactivate ? AppColors.error : AppColors.primary,
      title: deactivate ? 'Desativar o ministério?' : 'Reativar o ministério?',
      message: deactivate ? '${ministry.name} some do formulário do membro. Os membros continuam ligados a ele (nada é apagado) e dá para reativar depois.' : '${ministry.name} volta a aparecer no formulário do membro.',
      confirmLabel: deactivate ? 'Desativar' : 'Reativar',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.setActive.execute((ministry: ministry, active: !deactivate));
    final result = viewModel.setActive.result;
    viewModel.setActive.clearResult();
    if (!context.mounted) return;
    _show(context, switch (result) {
      Error(:final error) => ErrorMessages.of(error),
      _ => deactivate ? 'Ministério desativado.' : 'Ministério reativado.',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load]),
        builder: (context, _) {
          final load = viewModel.load;
          final church = viewModel.churchName == null ? '' : ' — ${viewModel.churchName}';
          return Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              Row(
                crossAxisAlignment: .end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 4,
                      children: [
                        const Text(
                          'Ministérios',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                        Text(
                          viewModel.canManage
                              ? 'Cadastre os ministérios, os líderes e os membros de cada um$church.'
                              : viewModel.onlyLeads
                              ? 'Os ministérios que você lidera$church: inclua ou tire membros.'
                              : 'Ministérios da igreja$church.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  if (viewModel.canManage) FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add, size: 18), label: const Text('Novo ministério')),
                ],
              ),
              Row(
                children: [
                  SegmentedButton<MinistryTab>(
                    showSelectedIcon: false,
                    segments: [for (final tab in MinistryTab.values) ButtonSegment(value: tab, label: Text(MinistriesViewModel.tabLabel(tab)))],
                    selected: {viewModel.tab},
                    onSelectionChanged: (selection) => viewModel.setTab(selection.first),
                  ),
                  const Spacer(),
                  IconButton(tooltip: 'Atualizar lista', onPressed: load.running ? null : load.execute, icon: const Icon(Icons.refresh)),
                ],
              ),
              Expanded(
                child: switch (load.result) {
                  Error(:final error) => _Message(icon: Icons.cloud_off_outlined, text: ErrorMessages.of(error), action: ('Tentar de novo', load.execute)),
                  _ when load.running && viewModel.ministries.isEmpty => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  _ when viewModel.ministries.isEmpty => _Message(
                    icon: Icons.groups_2_outlined,
                    text: viewModel.tab == MinistryTab.inactive
                        ? 'Nenhum ministério inativo.'
                        : viewModel.onlyLeads
                        ? 'Você não lidera nenhum ministério nesta igreja.'
                        : 'Nenhum ministério nesta igreja.',
                  ),
                  _ => _Table(
                    viewModel: viewModel,
                    onEdit: (ministry) => _edit(context, ministry),
                    onMembers: (ministry) => MinistryMembersDialog.show(context, viewModel: viewModel, ministry: ministry),
                    onToggleActive: (ministry) => _toggleActive(context, ministry),
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class const _Table({
  required final MinistriesViewModel viewModel,
  required final ValueChanged<Ministry> onEdit,
  required final ValueChanged<Ministry> onMembers,
  required final ValueChanged<Ministry> onToggleActive,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget text(String? value, {bool bold = false, bool muted = false}) => Text(
      value ?? '—',
      maxLines: 1,
      overflow: .ellipsis,
      style: TextStyle(fontWeight: bold ? FontWeight.w600 : null, color: muted || value == null ? AppColors.textSecondary : AppColors.textPrimary),
    );
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 24,
          showCheckboxColumn: false,
          headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceSubtle),
          headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
          columns: [
            const DataColumn(label: Text('Nome'), columnWidth: FlexColumnWidth(3)),
            const DataColumn(label: Text('Tipo'), columnWidth: FlexColumnWidth(3)),
            const DataColumn(label: Text('Líder'), columnWidth: FlexColumnWidth(3)),
            const DataColumn(label: Text('Vice-líder'), columnWidth: FlexColumnWidth(3)),
            const DataColumn(label: Text('Membros'), headingRowAlignment: .center, columnWidth: MaxColumnWidth(FixedColumnWidth(100), IntrinsicColumnWidth())),
            DataColumn(label: const Text(''), columnWidth: MaxColumnWidth(FixedColumnWidth(viewModel.canManage ? 380 : 140), const IntrinsicColumnWidth())),
          ],
          rows: [
            for (final ministry in viewModel.ministries)
              DataRow(
                color: ministry.active ? null : const WidgetStatePropertyAll(AppColors.background),
                cells: [
                  DataCell(
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(child: text(ministry.name, bold: true, muted: !ministry.active)),
                        if (!ministry.active) const MemberStatusChip(status: MemberStatus.inactive),
                      ],
                    ),
                    onTap: () => onMembers(ministry),
                  ),
                  DataCell(text(ministry.type, muted: true)),
                  DataCell(text(ministry.leaderName, muted: !ministry.active)),
                  DataCell(text(ministry.viceLeaderName, muted: !ministry.active)),
                  DataCell(Center(child: text('${ministry.memberCount}'))),
                  DataCell(
                    Row(
                      mainAxisAlignment: .end,
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(onPressed: () => onMembers(ministry), icon: const Icon(Icons.groups_outlined, size: 18), label: const Text('Membros')),
                        if (viewModel.canManage) ...[
                          OutlinedButton.icon(onPressed: () => onEdit(ministry), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar')),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: ministry.active ? AppColors.error : null),
                            onPressed: () => onToggleActive(ministry),
                            icon: Icon(ministry.active ? Icons.block : Icons.restore, size: 18),
                            label: Text(ministry.active ? 'Desativar' : 'Reativar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Cadastrar ou editar: tipo, nome, igreja, líder e vice-líder (buscados entre os membros).
class MinistryFormDialog extends StatefulWidget {
  const MinistryFormDialog({super.key, required this.viewModel, this.ministry});

  final MinistriesViewModel viewModel;
  final Ministry? ministry;

  static Future<bool?> show(BuildContext context, {required MinistriesViewModel viewModel, Ministry? ministry}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MinistryFormDialog(viewModel: viewModel, ministry: ministry),
  );

  @override
  State<MinistryFormDialog> createState() => _MinistryFormDialogState();
}

class _MinistryFormDialogState extends State<MinistryFormDialog> {
  late final _type = TextEditingController(text: widget.ministry?.type ?? '');
  late final _name = TextEditingController(text: widget.ministry?.name ?? '');
  late int? _churchId = widget.ministry?.churchId ?? widget.viewModel.churchId;
  late SpouseOption? _leader = widget.ministry?.leaderId == null ? null : SpouseOption(id: widget.ministry!.leaderId, name: widget.ministry!.leaderName ?? '');
  late SpouseOption? _vice = widget.ministry?.viceLeaderId == null ? null : SpouseOption(id: widget.ministry!.viceLeaderId, name: widget.ministry!.viceLeaderName ?? '');
  String? _error;

  bool get _valid => _type.text.trim().isNotEmpty && _name.text.trim().isNotEmpty && _churchId != null;

  @override
  void initState() {
    super.initState();
    _type.addListener(() => setState(() {}));
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _type.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final command = widget.viewModel.save;
    await command.execute((id: widget.ministry?.id, draft: (type: _type.text, name: _name.text, churchId: _churchId!, leaderId: _leader?.id, viceLeaderId: _vice?.id)));
    final result = command.result;
    command.clearResult();
    if (!mounted) return;
    switch (result) {
      case Error(:final error):
        setState(() => _error = ErrorMessages.of(error));
      default:
        Navigator.of(context).pop(true);
    }
  }

  Widget _person(String label, SpouseOption? selected, ValueChanged<SpouseOption?> onChanged) => Row(
    crossAxisAlignment: .start,
    spacing: 4,
    children: [
      Expanded(
        child: LookupField<SpouseOption>(
          label: label,
          selected: selected,
          labelOf: (option) => option.name,
          subtitleOf: (option) => option.church,
          search: widget.viewModel.searchMembers,
          onSelected: onChanged,
        ),
      ),
      if (selected != null)
        Padding(
          padding: const .only(top: 4),
          child: IconButton(tooltip: 'Tirar', onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 18)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel.save,
      builder: (context, _) {
        final running = widget.viewModel.save.running;
        return AlertDialog(
          icon: const Icon(Icons.groups_2_outlined, color: AppColors.primary),
          title: Text(widget.ministry == null ? 'Novo ministério' : 'Editar ministério'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              spacing: 14,
              children: [
                TextField(
                  controller: _name,
                  enabled: !running,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: formDecoration('Nome', required: true, hint: 'Ex.: Filhos da Promessa'),
                ),
                TextField(
                  controller: _type,
                  enabled: !running,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: formDecoration('Tipo', required: true, hint: 'Ex.: Ministério de Jovens'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _churchId,
                  isExpanded: true,
                  decoration: formDecoration('Igreja', required: true),
                  items: [
                    for (final church in widget.viewModel.churches)
                      DropdownMenuItem(
                        value: church.id,
                        child: Text(church.name, overflow: .ellipsis),
                      ),
                  ],
                  onChanged: running ? null : (value) => setState(() => _churchId = value),
                ),
                _person('Líder', _leader, (value) => setState(() => _leader = value)),
                _person('Vice-líder', _vice, (value) => setState(() => _vice = value)),
                const Text('O líder e o vice-líder entram como membros do ministério.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                if (_error case final message?) AppErrorBanner(message: message),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: running || !_valid ? null : _save,
              child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.ministry == null ? 'Cadastrar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }
}

/// Membros do ministério: ver; Secretaria/Administrador incluem e tiram.
class MinistryMembersDialog extends StatefulWidget {
  const MinistryMembersDialog({super.key, required this.viewModel, required this.ministry});

  final MinistriesViewModel viewModel;
  final Ministry ministry;

  static Future<void> show(BuildContext context, {required MinistriesViewModel viewModel, required Ministry ministry}) => showDialog<void>(
    context: context,
    builder: (_) => MinistryMembersDialog(viewModel: viewModel, ministry: ministry),
  );

  @override
  State<MinistryMembersDialog> createState() => _MinistryMembersDialogState();
}

class _MinistryMembersDialogState extends State<MinistryMembersDialog> {
  String? _error;

  MinistriesViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.loadMembers.execute(widget.ministry.id);
  }

  Future<void> _add(MinistryCandidate option) async {
    await _viewModel.addMember.execute((ministryId: widget.ministry.id, personId: option.id));
    _after(_viewModel.addMember.result);
    _viewModel.addMember.clearResult();
  }

  Future<void> _remove(MemberRow member) async {
    await _viewModel.removeMember.execute((ministryId: widget.ministry.id, personId: member.id));
    _after(_viewModel.removeMember.result);
    _viewModel.removeMember.clearResult();
  }

  void _after(Result<Object?>? result) {
    if (!mounted) return;
    setState(
      () => _error = switch (result) {
        Error(:final error) => ErrorMessages.of(error),
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ministry = widget.ministry;
    final isLeader = {?ministry.leaderId, ?ministry.viceLeaderId};
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _viewModel.loadMembers, _viewModel.addMember, _viewModel.removeMember]),
      builder: (context, _) {
        final loading = _viewModel.loadMembers.running;
        final busy = _viewModel.addMember.running || _viewModel.removeMember.running;
        final members = _viewModel.members;
        return AlertDialog(
          icon: const Icon(Icons.groups_outlined, color: AppColors.primary),
          title: Text(ministry.name),
          content: SizedBox(
            width: 560,
            height: 460,
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: 12,
              children: [
                Text(
                  [ministry.type, if (ministry.leaderName case final leader?) 'Líder: $leader'].join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (ministry.canEditMembers && ministry.active)
                  LookupField<MinistryCandidate>(
                    label: 'Incluir membro',
                    selected: null,
                    labelOf: (option) => option.name,
                    subtitleOf: (option) => option.details,
                    search: (text) => _viewModel.searchCandidates(ministry.id, text),
                    enabled: !busy,
                    onSelected: _add,
                  ),
                if (_error case final message?) AppErrorBanner(message: message),
                Text(members.length == 1 ? '1 membro' : '${members.length} membros', style: const TextStyle(fontWeight: FontWeight.w600)),
                Expanded(
                  child: loading && members.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : members.isEmpty
                      ? const Center(
                          child: Text('Nenhum membro neste ministério.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : Material(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSubtle),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final leader = member.id == ministry.leaderId
                                  ? 'Líder'
                                  : member.id == ministry.viceLeaderId
                                  ? 'Vice-líder'
                                  : null;
                              return ListTile(
                                dense: true,
                                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [?leader, ?member.ecclesiasticalRoleName, ?member.churchName].join(' · '),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: .min,
                                  spacing: 8,
                                  children: [
                                    MemberStatusChip(status: member.status),
                                    if (ministry.canEditMembers && !isLeader.contains(member.id)) IconButton(tooltip: 'Tirar do ministério', onPressed: busy ? null : () => _remove(member), icon: const Icon(Icons.person_remove_outlined, size: 20)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
        );
      },
    );
  }
}

class const _Message({required final IconData icon, required final String text, final (String, VoidCallback)? action}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      spacing: 12,
      children: [
        Icon(icon, size: 40, color: AppColors.textMuted),
        Text(
          text,
          textAlign: .center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        if (action case (final label, final onPressed)) FilledButton.tonal(onPressed: onPressed, child: Text(label)),
      ],
    ),
  );
}

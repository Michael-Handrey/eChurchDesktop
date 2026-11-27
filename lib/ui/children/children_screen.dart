import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/domain/models/child/child.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/children/children_viewmodel.dart';
import 'package:echurch_desktop/ui/children/widgets/child_form_dialog.dart';
import 'package:echurch_desktop/ui/core/share/confirm_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:echurch_desktop/ui/members/widgets/member_status_chip.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const ChildrenBindings({super.key, required final WidgetBuilder screenBuilder}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => ChildrenViewModel(repository: context.read(), ministries: context.read(), churchContext: context.read()).initialized(),
    builder: (context, child) => screenBuilder(context),
  );
}

void _show(BuildContext context, String message) {
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Crianças e Adolescentes (0 a 17 anos) dos membros, da igreja escolhida: abas, filtro de ministério e busca
/// (nome da criança ou do responsável); cadastrar, editar, desativar e reativar (Secretaria e Administrador).
class const ChildrenScreen({super.key, required final ChildrenViewModel viewModel}) extends StatelessWidget {
  Future<void> _edit(BuildContext context, [ChildRow? child]) async {
    final saved = await ChildFormDialog.show(context, viewModel: viewModel, childId: child?.id);
    if ((saved ?? false) && context.mounted) _show(context, child == null ? 'Criança cadastrada.' : 'Cadastro atualizado.');
  }

  Future<void> _toggleActive(BuildContext context, ChildRow child) async {
    final deactivate = child.active;
    final confirmed = await ConfirmDialog.show(
      context,
      icon: deactivate ? Icons.block : Icons.restore,
      color: deactivate ? AppColors.error : AppColors.primary,
      title: deactivate ? 'Desativar o cadastro?' : 'Reativar o cadastro?',
      message: deactivate ? '${child.name} sai da lista e da contagem. Nada é apagado e dá para reativar depois.' : '${child.name} volta para a lista e para a contagem.',
      confirmLabel: deactivate ? 'Desativar' : 'Reativar',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.setActive.execute((child: child, active: !deactivate));
    final result = viewModel.setActive.result;
    viewModel.setActive.clearResult();
    if (!context.mounted) return;
    _show(context, switch (result) {
      Error(:final error) => ErrorMessages.of(error),
      _ => deactivate ? 'Cadastro desativado.' : 'Cadastro reativado.',
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
                          'Crianças e Adolescentes',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                        Text(
                          'Filhos, netos, sobrinhos e enteados dos membros, de 0 a 17 anos$church.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add, size: 18), label: const Text('Nova criança')),
                ],
              ),
              _Toolbar(viewModel: viewModel),
              Expanded(
                child: _Content(viewModel: viewModel, onEdit: (child) => _edit(context, child), onToggleActive: (child) => _toggleActive(context, child)),
              ),
              Row(
                mainAxisAlignment: .end,
                spacing: 4,
                children: [
                  Text(viewModel.rangeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(tooltip: 'Página anterior', onPressed: viewModel.hasPrevious ? viewModel.previousPage : null, icon: const Icon(Icons.chevron_left)),
                  IconButton(tooltip: 'Próxima página', onPressed: viewModel.hasNext ? viewModel.nextPage : null, icon: const Icon(Icons.chevron_right)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class const _Toolbar({required final ChildrenViewModel viewModel}) extends StatelessWidget {
  static const _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.border),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        SegmentedButton<ChildTab>(
          segments: [for (final tab in ChildTab.values) ButtonSegment(value: tab, label: Text(tab.label))],
          selected: {viewModel.tab},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => viewModel.setTab(selection.first),
        ),
        const Spacer(),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<MinistryFilter>(
            key: const ValueKey('child-ministry-filter'),
            initialValue: viewModel.ministryFilter,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, filled: true, fillColor: AppColors.surface, border: _border, enabledBorder: _border, prefixIcon: const Icon(Icons.diversity_3_outlined, size: 20)),
            items: [
              const DropdownMenuItem(value: AnyMinistry(), child: Text('Todos os ministérios')),
              const DropdownMenuItem(value: NoMinistry(), child: Text('Sem ministério')),
              for (final ministry in viewModel.childMinistries)
                DropdownMenuItem(
                  value: InMinistry(ministry.id),
                  child: Text(ministry.name, overflow: .ellipsis),
                ),
            ],
            onChanged: (value) => viewModel.setMinistryFilter(value ?? const AnyMinistry()),
          ),
        ),
        SizedBox(
          width: 280,
          // A busca continua no viewmodel: ao voltar para a lista, o campo começa com ela.
          child: TextFormField(
            key: const ValueKey('child-search'),
            initialValue: viewModel.text,
            onChanged: viewModel.setText,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar pela criança ou pelo responsável',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: _border,
              enabledBorder: _border,
            ),
          ),
        ),
        IconButton(tooltip: 'Atualizar lista', onPressed: viewModel.load.running ? null : viewModel.load.execute, icon: const Icon(Icons.refresh)),
      ],
    );
  }
}

class const _Content({required final ChildrenViewModel viewModel, required final ValueChanged<ChildRow> onEdit, required final ValueChanged<ChildRow> onToggleActive}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final load = viewModel.load;
    if (load.running && viewModel.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (load.result case Error(:final error)) {
      return Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 12,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textMuted),
            Text(
              ErrorMessages.of(error),
              textAlign: .center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            FilledButton.tonal(onPressed: load.execute, child: const Text('Tentar de novo')),
          ],
        ),
      );
    }
    if (viewModel.rows.isEmpty) {
      return Center(
        child: Text(
          viewModel.isFiltered ? 'Nenhuma criança encontrada com esses filtros.' : 'Nenhuma criança nesta lista.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    Widget text(String? value, {bool bold = false, bool muted = false}) => Text(
      value == null || value.isEmpty ? '—' : value,
      maxLines: 1,
      overflow: .ellipsis,
      style: TextStyle(fontWeight: bold ? FontWeight.w600 : null, color: muted || value == null || value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary),
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
          columns: const [
            DataColumn(label: Text('Nome'), columnWidth: FlexColumnWidth(3)),
            DataColumn(label: Text('Idade'), headingRowAlignment: .center, columnWidth: MaxColumnWidth(FixedColumnWidth(150), IntrinsicColumnWidth())),
            DataColumn(label: Text('Ministério'), columnWidth: FlexColumnWidth(2)),
            DataColumn(label: Text('Responsáveis'), columnWidth: FlexColumnWidth(4)),
            DataColumn(label: Text(''), columnWidth: MaxColumnWidth(FixedColumnWidth(280), IntrinsicColumnWidth())),
          ],
          rows: [
            for (final child in viewModel.rows)
              DataRow(
                color: child.active ? null : const WidgetStatePropertyAll(AppColors.background),
                cells: [
                  DataCell(
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(child: text(child.name, bold: true, muted: !child.active)),
                        if (!child.active) const MemberStatusChip(status: MemberStatus.inactive),
                      ],
                    ),
                    onTap: () => onEdit(child),
                  ),
                  DataCell(
                    Center(
                      child: Tooltip(
                        message: 'Nascimento: ${MembersViewModel.formatDate(child.birthDate)}',
                        child: text(child.age == 1 ? '1 ano' : '${child.age} anos', muted: !child.active),
                      ),
                    ),
                  ),
                  DataCell(text(child.ministryName, muted: true)),
                  DataCell(text(child.guardians, muted: !child.active)),
                  DataCell(
                    Row(
                      mainAxisAlignment: .end,
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(onPressed: () => onEdit(child), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar')),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: child.active ? AppColors.error : null),
                          onPressed: () => onToggleActive(child),
                          icon: Icon(child.active ? Icons.block : Icons.restore, size: 18),
                          label: Text(child.active ? 'Desativar' : 'Reativar'),
                        ),
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

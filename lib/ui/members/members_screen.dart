import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/core/share/all_churches_chip.dart';
import 'package:echurch_desktop/ui/core/share/confirm_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/duplicates/duplicates_screen.dart';
import 'package:echurch_desktop/ui/members/form/member_form_bindings.dart';
import 'package:echurch_desktop/ui/members/form/member_form_screen.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:echurch_desktop/ui/members/spouse_review/spouse_review_screen.dart';
import 'package:echurch_desktop/ui/members/widgets/deactivate_member_dialog.dart';
import 'package:echurch_desktop/ui/members/widgets/member_details_dialog.dart';
import 'package:echurch_desktop/ui/members/widgets/members_table.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Membros da igreja em uso: ativos, inativos ou todos; busca por nome e filtro por cargo;
/// detalhes; desativar (com motivo) e reativar para Secretaria/Administrador. Membros não são
/// excluídos. Cadastro e edição: etapa 2 (ROADMAP).
class const MembersScreen({super.key, required final MembersViewModel viewModel}) extends StatelessWidget {
  static void _show(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deactivate(BuildContext context, MemberRow member) async {
    final done = await DeactivateMemberDialog.show(context, viewModel: viewModel, member: member);
    if ((done ?? false) && context.mounted) _show(context, '${member.name} foi desativado(a).');
  }

  Future<void> _reactivate(BuildContext context, MemberRow member) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.restore,
      title: 'Reativar o membro?',
      message: '${member.name} volta para a lista de ativos. O motivo da desativação fica registrado no histórico.',
      confirmLabel: 'Reativar',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.reactivate.execute(member);
    final result = viewModel.reactivate.result;
    viewModel.reactivate.clearResult();
    if (context.mounted) {
      _show(context, switch (result) {
        Error(:final error) => ErrorMessages.of(error),
        _ => '${member.name} foi reativado(a).',
      });
    }
  }

  void _closeForm(BuildContext context, {required bool wasNew, int? savedId}) {
    viewModel.closeForm(savedId: savedId);
    if (savedId != null) _show(context, wasNew ? 'Membro cadastrado.' : 'Alterações salvas.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        // Revisão de cônjuges: a página no lugar da lista.
        if (viewModel.showingSpouseReview) {
          return SpouseReviewBindings(
            screenBuilder: (reviewContext) => SpouseReviewScreen(
              viewModel: reviewContext.read(),
              onClose: (changed) => viewModel.closeSpouseReview(changed: changed),
            ),
          );
        }
        // Cadastros duplicados: a página no lugar da lista.
        if (viewModel.showingDuplicates) {
          return DuplicatesBindings(
            screenBuilder: (duplicatesContext) => DuplicatesScreen(
              viewModel: duplicatesContext.read(),
              onClose: (changed) => viewModel.closeDuplicates(changed: changed),
            ),
          );
        }
        // Cadastro/edição: a página do formulário no lugar da lista.
        if (viewModel.form case (:final id)) {
          return MemberFormBindings(
            key: ValueKey(('member-form', id)),
            memberId: id,
            screenBuilder: (formContext) => MemberFormScreen(
              viewModel: formContext.read(),
              onClose: (savedId) => _closeForm(context, wasNew: id == null, savedId: savedId),
            ),
          );
        }
        return _list(context);
      },
    );
  }

  Widget _list(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load]),
        builder: (context, _) => Column(
          crossAxisAlignment: .stretch,
          spacing: 16,
          children: [
            _Header(viewModel: viewModel),
            _Toolbar(viewModel: viewModel),
            Expanded(
              child: _Content(
                viewModel: viewModel,
                onDeactivate: (member) => _deactivate(context, member),
                onReactivate: (member) => _reactivate(context, member),
              ),
            ),
            _Pager(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}

class const _Header({required final MembersViewModel viewModel}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final church = viewModel.churchName == null ? (viewModel.allChurches ? ' — todas as igrejas' : '') : ' — ${viewModel.churchName}';
    return Row(
      crossAxisAlignment: .end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              const Text(
                'Membros',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              Text(
                viewModel.canManage ? 'Cadastre, edite, desative ou reative os membros$church.' : 'Consulte os membros da igreja$church.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        ),
        if (viewModel.canManage && viewModel.duplicateCount > 0) ...[
          OutlinedButton.icon(
            onPressed: viewModel.openDuplicates,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
            icon: const Icon(Icons.content_copy_outlined, size: 18),
            label: Text('Cadastros duplicados (${viewModel.duplicateCount})'),
          ),
          const SizedBox(width: 8),
        ],
        if (viewModel.canManage && viewModel.spouseReviewCount > 0) ...[
          OutlinedButton.icon(
            onPressed: viewModel.openSpouseReview,
            icon: const Icon(Icons.favorite_border, size: 18),
            label: Text('Revisar cônjuges (${viewModel.spouseReviewCount})'),
          ),
          const SizedBox(width: 8),
        ],
        if (viewModel.canManage) FilledButton.icon(onPressed: viewModel.openNew, icon: const Icon(Icons.person_add_alt_1_outlined, size: 18), label: const Text('Novo membro')),
      ],
    );
  }
}

class const _Toolbar({required final MembersViewModel viewModel}) extends StatelessWidget {
  /// Abaixo desta largura, os filtros vão para uma segunda linha.
  static const twoLinesBelow = 1000.0;

  static OutlineInputBorder get _border => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.border),
  );

  @override
  Widget build(BuildContext context) {
    final tabs = SegmentedButton<MemberTab>(
      showSelectedIcon: false,
      segments: [for (final tab in MemberTab.values) ButtonSegment(value: tab, label: Text(MembersViewModel.tabLabel(tab)))],
      selected: {viewModel.tab},
      onSelectionChanged: (selection) => viewModel.setTab(selection.first),
    );
    // Filtros à direita; sem espaço, a busca encolhe.
    final filters = Row(
      mainAxisAlignment: .end,
      spacing: 8,
      children: [
        if (viewModel.canSeeAllChurches) AllChurchesChip(selected: viewModel.allChurches, onChanged: viewModel.setAllChurches),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            key: const ValueKey('member-role-filter'),
            initialValue: viewModel.roleId,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, filled: true, fillColor: AppColors.surface, border: _border, enabledBorder: _border, prefixIcon: const Icon(Icons.badge_outlined, size: 20)),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos os cargos')),
              for (final role in viewModel.roles)
                DropdownMenuItem<int?>(
                  value: role.id,
                  child: Text(role.name, overflow: .ellipsis),
                ),
            ],
            onChanged: viewModel.setRole,
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            // A busca continua no viewmodel: ao voltar do formulário (ou de outra aba), o campo começa com ela.
            child: TextFormField(
              key: const ValueKey('member-search'),
              initialValue: viewModel.text,
              onChanged: viewModel.setText,
              decoration: InputDecoration(
                isDense: true,
                hintText: viewModel.canManage ? 'Buscar por nome, CPF ou telefone' : 'Buscar por nome ou telefone',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: _border,
                enabledBorder: _border,
              ),
            ),
          ),
        ),
      ],
    );
    final refresh = IconButton(tooltip: 'Atualizar lista', onPressed: viewModel.load.running ? null : viewModel.load.execute, icon: const Icon(Icons.refresh));

    // Tela estreita: abas e atualizar em cima, filtros embaixo.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= twoLinesBelow
          ? Row(
              spacing: 8,
              children: [
                tabs,
                Expanded(child: filters),
                refresh,
              ],
            )
          : Column(
              crossAxisAlignment: .stretch,
              spacing: 12,
              children: [
                Row(
                  children: [
                    Flexible(child: tabs),
                    const Spacer(),
                    refresh,
                  ],
                ),
                filters,
              ],
            ),
    );
  }
}

class const _Content({required final MembersViewModel viewModel, required final ValueChanged<MemberRow> onDeactivate, required final ValueChanged<MemberRow> onReactivate}) extends StatelessWidget {
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
    return MembersTableWidget(
      rows: viewModel.rows,
      canManage: viewModel.canManage,
      showChurch: viewModel.showChurchColumn,
      emptyMessage: viewModel.isFiltered ? 'Nenhum membro encontrado com esses filtros.' : 'Nenhum membro nesta lista.',
      onOpen: (member) => MemberDetailsDialog.show(
        context,
        details: viewModel.details,
        full: viewModel.canManage,
        member: member,
        onEdit: viewModel.canManage ? () => viewModel.openEdit(member.id) : null,
      ),
      onDeactivate: onDeactivate,
      onReactivate: onReactivate,
      onEdit: (member) => viewModel.openEdit(member.id),
    );
  }
}

class const _Pager({required final MembersViewModel viewModel}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .end,
      spacing: 4,
      children: [
        Text(viewModel.rangeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 8),
        IconButton(tooltip: 'Página anterior', onPressed: viewModel.hasPrevious ? viewModel.previousPage : null, icon: const Icon(Icons.chevron_left)),
        IconButton(tooltip: 'Próxima página', onPressed: viewModel.hasNext ? viewModel.nextPage : null, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

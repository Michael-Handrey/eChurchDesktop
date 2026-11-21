import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/confirm_dialog.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/prayer_request_details_dialog.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/prayer_request_form_dialog.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/prayer_requests_table.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/reject_prayer_request_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Pedidos de oração da igreja em uso (na Sede, também os sem igreja enviados pela comunidade):
/// registrar, acompanhar e — conforme o que a API permite a cada um — marcar no vaso (um, vários
/// ou todos), editar, rejeitar, excluir da lista, voltar para novo e restaurar. A impressão para o
/// vaso virá com os relatórios (ROADMAP).
class const PrayerRequestsScreen({super.key, required final PrayerRequestsViewModel viewModel}) extends StatelessWidget {
  static void _show(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _count(int count) => count == 1 ? '1 pedido' : '$count pedidos';

  Future<void> _create(BuildContext context) async {
    final saved = await PrayerRequestFormDialog.show(context, viewModel: viewModel);
    if ((saved ?? false) && context.mounted) _show(context, 'Pedido de oração registrado.');
  }

  Future<void> _action(BuildContext context, PrayerRequest request, PrayerRequestAction action) async {
    switch (action) {
      case PrayerRequestAction.edit:
        final saved = await PrayerRequestFormDialog.show(context, viewModel: viewModel, request: request);
        if ((saved ?? false) && context.mounted) _show(context, 'Pedido de oração atualizado.');
      case PrayerRequestAction.reject:
        final rejected = await RejectPrayerRequestDialog.show(context, viewModel: viewModel, request: request);
        if ((rejected ?? false) && context.mounted) _show(context, 'Pedido de oração rejeitado.');
      case PrayerRequestAction.inVase:
        viewModel.toggleSelection(request, true);
      case PrayerRequestAction.backToNew || PrayerRequestAction.exclude || PrayerRequestAction.restore:
        final (icon, color, title, message, confirm, done) = switch (action) {
          PrayerRequestAction.exclude => (
            Icons.delete_outline,
            AppColors.error,
            'Excluir o pedido da lista?',
            'O pedido de ${request.requesterName} sai da lista, mas continua guardado: só o administrador vê os excluídos e pode restaurá-los.',
            'Excluir',
            'Pedido excluído da lista.',
          ),
          PrayerRequestAction.restore => (
            Icons.restore,
            AppColors.primary,
            'Restaurar o pedido?',
            'O pedido de ${request.requesterName} volta para a lista, como rejeitado.',
            'Restaurar',
            'Pedido restaurado.',
          ),
          _ => (
            Icons.undo,
            AppColors.primary,
            'Voltar o pedido para novo?',
            request.status == PrayerRequestStatus.inVase ? 'Desfaz o "no vaso" do pedido de ${request.requesterName} (por exemplo, marcado por engano).' : 'Desfaz a rejeição do pedido de ${request.requesterName}.',
            'Voltar para novo',
            'Pedido voltou para novo.',
          ),
        };
        if (!await ConfirmDialog.show(context, icon: icon, color: color, title: title, message: message, confirmLabel: confirm)) return;
        await viewModel.quickAction.execute((request: request, action: action));
        final result = viewModel.quickAction.result;
        viewModel.quickAction.clearResult();
        if (context.mounted) {
          _show(context, switch (result) {
            Error(:final error) => ErrorMessages.of(error),
            _ => done,
          });
        }
    }
  }

  Future<void> _markSelected(BuildContext context) async {
    await viewModel.markInVase.execute();
    if (context.mounted) _afterVase(context, viewModel.markInVase.result);
    viewModel.markInVase.clearResult();
  }

  Future<void> _markAll(BuildContext context) async {
    final count = viewModel.newCount;
    final where = viewModel.isHeadquarters ? '${viewModel.churchName ?? 'Sede'} (inclusive os sem igreja)' : (viewModel.churchName ?? 'igreja');
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.inventory_2_outlined,
      title: 'Marcar todos no vaso?',
      message: 'Os ${_count(count)} novos de $where passam para "No vaso". Depois disso, só o administrador pode desfazer.',
      confirmLabel: 'Marcar todos',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.markAllInVase.execute();
    if (!context.mounted) return;
    _afterVase(context, viewModel.markAllInVase.result);
    viewModel.markAllInVase.clearResult();
  }

  void _afterVase(BuildContext context, Result<int>? result) {
    _show(context, switch (result) {
      Ok<int>(:final value) => '${_count(value)} no vaso.',
      Error(:final error) => ErrorMessages.of(error),
      null => '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load, viewModel.markInVase, viewModel.markAllInVase]),
        builder: (context, _) => Column(
          crossAxisAlignment: .stretch,
          spacing: 16,
          children: [
            _Header(viewModel: viewModel, onCreate: () => _create(context)),
            _Toolbar(viewModel: viewModel, onMarkSelected: () => _markSelected(context), onMarkAll: () => _markAll(context)),
            Expanded(
              child: _Content(viewModel: viewModel, onAction: (request, action) => _action(context, request, action)),
            ),
            _Pager(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}

class const _Header({required final PrayerRequestsViewModel viewModel, required final VoidCallback onCreate}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final church = viewModel.churchName == null ? '' : ' — ${viewModel.churchName}';
    return Row(
      crossAxisAlignment: .end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              const Text(
                'Pedidos de Oração',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              Text(
                viewModel.canManage ? 'Registre os pedidos e marque os que vão para o vaso de oração$church.' : 'Registre pedidos de oração e acompanhe os que você registrou.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        ),
        FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add, size: 18), label: const Text('Novo pedido')),
      ],
    );
  }
}

class const _Toolbar({required final PrayerRequestsViewModel viewModel, required final VoidCallback onMarkSelected, required final VoidCallback onMarkAll}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedIds.length;
    final busy = viewModel.markInVase.running || viewModel.markAllInVase.running;

    return Row(
      spacing: 8,
      children: [
        SegmentedButton<PrayerRequestTab>(
          showSelectedIcon: false,
          segments: [for (final tab in viewModel.tabs) ButtonSegment(value: tab, label: Text(PrayerRequestsViewModel.tabLabel(tab)))],
          selected: {viewModel.tab},
          onSelectionChanged: (selection) => viewModel.setTab(selection.first),
        ),
        const Spacer(),
        if (selected > 0)
          FilledButton.tonalIcon(
            onPressed: busy ? null : onMarkSelected,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text(selected == 1 ? 'Marcar 1 no vaso' : 'Marcar $selected no vaso'),
          )
        else if (viewModel.canMarkAll)
          OutlinedButton.icon(
            onPressed: busy ? null : onMarkAll,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text('Marcar todos no vaso (${viewModel.newCount})'),
          ),
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: viewModel.setText,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar por nome ou pedido',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        IconButton(tooltip: 'Atualizar lista', onPressed: viewModel.load.running ? null : viewModel.load.execute, icon: const Icon(Icons.refresh)),
      ],
    );
  }
}

class const _Content({required final PrayerRequestsViewModel viewModel, required final void Function(PrayerRequest request, PrayerRequestAction action) onAction}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final load = viewModel.load;
    if (load.running && viewModel.page.items.isEmpty) {
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
    return PrayerRequestsTableWidget(
      rows: viewModel.rows,
      canManage: viewModel.canManage,
      pageSelection: viewModel.pageSelection,
      hasSelectable: viewModel.hasSelectable,
      onSelectPage: viewModel.togglePageSelection,
      onOpen: (request) => PrayerRequestDetailsDialog.show(context, request),
      onSelect: viewModel.toggleSelection,
      onAction: onAction,
    );
  }
}

class const _Pager({required final PrayerRequestsViewModel viewModel}) extends StatelessWidget {
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

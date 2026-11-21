import 'dart:math' as math;

import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/prayer_request_status_chip.dart';
import 'package:material_ui/material_ui.dart';

/// Tabela de pedidos. Clicar no nome ou no pedido abre os detalhes (o texto aqui é cortado).
/// Caixas de seleção só nos pedidos que podem ir para o vaso; botões só das ações que a API permite.
class const PrayerRequestsTableWidget({
  super.key,
  required final List<PrayerRequestRowView> rows,
  required final bool canManage,
  required final bool? pageSelection,
  required final bool hasSelectable,
  required final ValueChanged<bool> onSelectPage,
  required final ValueChanged<PrayerRequest> onOpen,
  required final void Function(PrayerRequest request, bool selected) onSelect,
  required final void Function(PrayerRequest request, PrayerRequestAction action) onAction,
}) extends StatelessWidget {
  static const _minWidth = 1100.0;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('Nenhum pedido de oração encontrado.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: .antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            child: SizedBox(
              width: math.max(constraints.maxWidth, _minWidth),
              child: DataTable(
                columnSpacing: 24,
                showCheckboxColumn: false,
                headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceSubtle),
                headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
                columns: [
                  if (canManage && hasSelectable)
                    DataColumn(
                      columnWidth: const FixedColumnWidth(84), // caixa de seleção + margens da tabela
                      label: hasSelectable
                          ? Tooltip(
                              message: 'Selecionar todos desta página',
                              child: Checkbox(tristate: true, value: pageSelection, onChanged: (_) => onSelectPage(pageSelection != true)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  const DataColumn(label: Text('Data'), columnWidth: FixedColumnWidth(110)),
                  const DataColumn(label: Text('Quem pediu'), columnWidth: FlexColumnWidth(2)),
                  const DataColumn(label: Text('Pedido'), columnWidth: FlexColumnWidth(5)),
                  const DataColumn(label: Text('Situação'), columnWidth: MaxColumnWidth(FixedColumnWidth(120), IntrinsicColumnWidth())),
                  if (canManage) ...[
                    const DataColumn(label: Text('Registrado por'), columnWidth: FlexColumnWidth(2)),
                    const DataColumn(label: Text(''), columnWidth: MaxColumnWidth(FixedColumnWidth(300), IntrinsicColumnWidth())),
                  ],
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        if (canManage && hasSelectable) DataCell(row.selectable ? Checkbox(value: row.selected, onChanged: (value) => onSelect(row.request, value ?? false)) : const SizedBox.shrink()),
                        DataCell(Text(row.dateLabel)),
                        DataCell(_Text(row.request.requesterName, bold: true), onTap: () => onOpen(row.request)),
                        DataCell(_Text(row.request.description), onTap: () => onOpen(row.request)),
                        DataCell(PrayerRequestStatusChip(request: row.request)),
                        if (canManage) ...[
                          DataCell(_Text(row.request.fromCommunity ? 'Comunidade (app)' : row.request.createdByName ?? '—', muted: row.request.fromCommunity)),
                          DataCell(
                            Align(
                              alignment: .centerRight,
                              child: _Actions(request: row.request, onAction: onAction),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma linha, cortada com "…".
class const _Text(final String text, {final bool bold = false, final bool muted = false}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: .ellipsis,
    style: TextStyle(fontWeight: bold ? FontWeight.w600 : null, color: muted ? AppColors.textSecondary : AppColors.textPrimary),
  );
}

/// Botões das ações permitidas (o "no vaso" é pela seleção). Largura mínima fixa, alinhados.
class const _Actions({required final PrayerRequest request, required final void Function(PrayerRequest request, PrayerRequestAction action) onAction}) extends StatelessWidget {
  static ButtonStyle _width(double width, {Color? color}) => OutlinedButton.styleFrom(minimumSize: Size(width, 36), foregroundColor: color);

  @override
  Widget build(BuildContext context) {
    Widget button(PrayerRequestAction action, IconData icon, String label, {double width = 112, Color? color}) => OutlinedButton.icon(
      style: _width(width, color: color),
      onPressed: () => onAction(request, action),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );

    return Row(
      mainAxisSize: .min,
      spacing: 8,
      children: [
        if (request.can(PrayerRequestAction.edit)) button(PrayerRequestAction.edit, Icons.edit_outlined, 'Editar', width: 104),
        if (request.can(PrayerRequestAction.reject)) button(PrayerRequestAction.reject, Icons.block, 'Rejeitar', color: AppColors.error),
        if (request.can(PrayerRequestAction.backToNew)) button(PrayerRequestAction.backToNew, Icons.undo, 'Voltar p/ novo', width: 148),
        if (request.can(PrayerRequestAction.exclude)) button(PrayerRequestAction.exclude, Icons.delete_outline, 'Excluir', color: AppColors.error),
        if (request.can(PrayerRequestAction.restore)) button(PrayerRequestAction.restore, Icons.restore, 'Restaurar', width: 124),
      ],
    );
  }
}

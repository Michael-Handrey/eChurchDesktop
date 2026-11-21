import 'dart:math' as math;

import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:echurch_desktop/ui/members/widgets/member_status_chip.dart';
import 'package:material_ui/material_ui.dart';

/// Tabela de membros. Clicar no nome abre os detalhes. Desativar/Reativar só para quem gerencia.
/// Inativos em cinza.
class const MembersTableWidget({
  super.key,
  required final List<MemberRow> rows,
  required final bool canManage,

  /// Coluna Igreja: quando a lista junta várias igrejas.
  final bool showChurch = false,
  required final String emptyMessage,
  required final ValueChanged<MemberRow> onOpen,
  required final ValueChanged<MemberRow> onDeactivate,
  required final ValueChanged<MemberRow> onReactivate,
}) extends StatelessWidget {
  static const _minWidth = 960.0;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.textSecondary)),
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
        // Cabeçalho fixo: uma tabela só com os títulos em cima e outra com as linhas, rolando
        // embaixo. As larguras são fixas ou proporcionais (as "intrínsecas" só valem quando o
        // conteúdo passa do mínimo), então as colunas das duas se alinham.
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: .horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, _minWidth),
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                _table(header: true),
                Expanded(child: SingleChildScrollView(child: _table(header: false))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [header]: só a linha de títulos; senão, só as linhas (os títulos ficam, com altura zero, para as
  /// colunas medirem igual nas duas tabelas).
  DataTable _table({required bool header}) {
    final columns = <DataColumn>[
      const DataColumn(label: Text('Nome'), columnWidth: FlexColumnWidth(3)),
      const DataColumn(label: Text('Cargo'), headingRowAlignment: .center, columnWidth: FlexColumnWidth(2)),
      if (showChurch) const DataColumn(label: Text('Igreja'), headingRowAlignment: .center, columnWidth: FlexColumnWidth(2)),
      const DataColumn(label: Text('Telefone'), headingRowAlignment: .center, columnWidth: MaxColumnWidth(FixedColumnWidth(160), IntrinsicColumnWidth())),
      const DataColumn(label: Text('Aniversário'), headingRowAlignment: .center, columnWidth: MaxColumnWidth(FixedColumnWidth(120), IntrinsicColumnWidth())),
      const DataColumn(label: Text('Situação'), headingRowAlignment: .center, columnWidth: MaxColumnWidth(FixedColumnWidth(110), IntrinsicColumnWidth())),
      if (canManage) const DataColumn(label: Text(''), columnWidth: MaxColumnWidth(FixedColumnWidth(172), IntrinsicColumnWidth())),
    ];
    return DataTable(
      columnSpacing: 24,
      showCheckboxColumn: false,
      headingRowHeight: header ? 56 : 0,
      headingRowColor: header ? const WidgetStatePropertyAll(AppColors.surfaceSubtle) : null,
      headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
      columns: columns,
      rows: header
          ? const []
          : [
              for (final row in rows)
                DataRow(
                  color: row.status == MemberStatus.inactive ? const WidgetStatePropertyAll(AppColors.background) : null,
                  cells: [
                    DataCell(_Text(row.name, bold: true, muted: row.status == MemberStatus.inactive), onTap: () => onOpen(row)),
                    DataCell(Center(child: _Text(row.ecclesiasticalRoleName ?? '—', muted: row.ecclesiasticalRoleName == null || row.status == MemberStatus.inactive))),
                    if (showChurch) DataCell(Center(child: _Text(row.churchName ?? '—', muted: true))),
                    DataCell(Center(child: _Text(row.phone ?? '—', muted: row.phone == null || row.status == MemberStatus.inactive))),
                    DataCell(Center(child: _Text(MembersViewModel.birthdayLabel(row.birthDay, row.birthMonth) ?? '—', muted: true))),
                    DataCell(
                      Center(
                        child: MemberStatusChip(status: row.status, reason: row.deactivationReason),
                      ),
                    ),
                    if (canManage)
                      DataCell(
                        Align(
                          alignment: .centerRight,
                          child: switch (row.status) {
                            MemberStatus.active => OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(124, 36), foregroundColor: AppColors.error),
                              onPressed: () => onDeactivate(row),
                              icon: const Icon(Icons.person_off_outlined, size: 18),
                              label: const Text('Desativar'),
                            ),
                            MemberStatus.inactive => OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(124, 36)),
                              onPressed: () => onReactivate(row),
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('Reativar'),
                            ),
                            MemberStatus.other => const SizedBox.shrink(),
                          },
                        ),
                      ),
                  ],
                ),
            ],
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

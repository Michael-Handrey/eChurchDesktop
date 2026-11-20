import 'dart:math' as math;

import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/groups_viewmodel.dart';
import 'package:echurch_desktop/ui/users/widgets/access_chip.dart';
import 'package:material_ui/material_ui.dart';

class const GroupsTableWidget({
  super.key,
  required final List<GroupRowView> rows,
  required final ValueChanged<SecurityGroup> onEdit,
  required final ValueChanged<SecurityGroup> onDelete,
}) extends StatelessWidget {
  /// Abaixo disso a tabela rola na horizontal em vez de espremer as colunas.
  static const _minWidth = 800.0;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('Nenhum grupo cadastrado.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: .antiAlias,
      // Ocupa a largura toda; se a janela for estreita, rola na horizontal em vez de cortar.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            child: SizedBox(
              width: math.max(constraints.maxWidth, _minWidth),
              child: DataTable(
                columnSpacing: 28,
                headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceSubtle),
                headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
                // Larguras definidas: a tabela não muda de forma quando a lista muda.
                columns: const [
                  DataColumn(label: Text('Grupo'), columnWidth: FlexColumnWidth(2)),
                  DataColumn(label: Text('Permissões'), columnWidth: FlexColumnWidth(4)),
                  DataColumn(label: Text('Usuários'), numeric: true, columnWidth: MaxColumnWidth(FixedColumnWidth(110), IntrinsicColumnWidth())),
                  DataColumn(label: Text(''), columnWidth: MaxColumnWidth(FixedColumnWidth(280), IntrinsicColumnWidth())),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(row.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(
                          row.permissionLabels.isEmpty ? const Text('Sem permissões', style: TextStyle(color: AppColors.textMuted)) : Wrap(spacing: 6, runSpacing: 4, children: [for (final label in row.permissionLabels) AccessChipWidget(label: label)]),
                        ),
                        DataCell(Text('${row.group.userCount}')),
                        DataCell(
                          Align(
                            alignment: .centerRight,
                            child: Row(
                              mainAxisSize: .min,
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => onEdit(row.group),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Editar'),
                                ),
                                Tooltip(
                                  message: row.canDelete ? 'Excluir o grupo' : 'Tire os usuários do grupo antes de excluir',
                                  child: OutlinedButton.icon(
                                    onPressed: row.canDelete ? () => onDelete(row.group) : null,
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: const Text('Excluir'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

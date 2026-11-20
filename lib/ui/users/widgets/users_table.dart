import 'dart:math' as math;

import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:echurch_desktop/ui/users/widgets/access_chip.dart';
import 'package:material_ui/material_ui.dart';

class const UsersTableWidget({
  super.key,
  required final List<UserRowView> rows,
  required final ValueChanged<ManagedUser> onEditAccess,
  required final ValueChanged<ManagedUser> onResetPassword,
  required final VoidCallback onChangeOwnPassword,
  required final ValueChanged<ManagedUser> onToggleActive,
}) extends StatelessWidget {
  /// Abaixo disso a tabela rola na horizontal em vez de espremer as colunas.
  static const _minWidth = 1250.0;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('Nenhum usuário encontrado.', style: TextStyle(color: AppColors.textSecondary)),
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
                // Larguras definidas: filtrar ou buscar não muda o tamanho das colunas. Situação e ações têm
                // largura mínima fixa e só crescem se o conteúdo não couber (fonte maior, por exemplo).
                columns: const [
                  DataColumn(label: Text('Nome'), columnWidth: FlexColumnWidth(3)),
                  DataColumn(label: Text('Login'), columnWidth: FlexColumnWidth(2)),
                  DataColumn(label: Text('Igreja'), columnWidth: FlexColumnWidth(2)),
                  DataColumn(label: Text('Grupos'), columnWidth: FlexColumnWidth(3)),
                  DataColumn(label: Text('Situação'), columnWidth: MaxColumnWidth(FixedColumnWidth(220), IntrinsicColumnWidth())),
                  DataColumn(label: Text(''), columnWidth: MaxColumnWidth(FixedColumnWidth(480), IntrinsicColumnWidth())),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      // Usuário inativo: a linha toda fica apagada (os botões continuam usáveis, para reativar).
                      color: row.user.active ? null : const WidgetStatePropertyAll(AppColors.surfaceSubtle),
                      cells: [
                        DataCell(_CellText(row.user.name, active: row.user.active, bold: true)),
                        DataCell(_CellText(row.user.login, active: row.user.active)),
                        DataCell(_CellText(row.churchLabel, active: row.user.active)),
                        DataCell(_CellText(row.groupsLabel.isEmpty ? '—' : row.groupsLabel, active: row.user.active)),
                        DataCell(_Status(user: row.user)),
                        DataCell(
                          Align(
                            alignment: .centerRight,
                            child: _Actions(
                              row: row,
                              onEditAccess: onEditAccess,
                              onResetPassword: onResetPassword,
                              onChangeOwnPassword: onChangeOwnPassword,
                              onToggleActive: onToggleActive,
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

/// Botões de largura mínima fixa: ficam alinhados em coluna, linha a linha,
/// mesmo quando o texto muda ("Redefinir senha" × "Alterar senha", "Desativar" × "Reativar").
class const _Actions({
  required final UserRowView row,
  required final ValueChanged<ManagedUser> onEditAccess,
  required final ValueChanged<ManagedUser> onResetPassword,
  required final VoidCallback onChangeOwnPassword,
  required final ValueChanged<ManagedUser> onToggleActive,
}) extends StatelessWidget {
  static const _groupsWidth = 112.0;
  static const _passwordWidth = 190.0;
  static const _activeWidth = 132.0;

  static ButtonStyle _width(double width, {Color? color}) => OutlinedButton.styleFrom(
    minimumSize: Size(width, 36),
    foregroundColor: color,
  );

  @override
  Widget build(BuildContext context) {
    final user = row.user;

    return Row(
      mainAxisSize: .min,
      spacing: 8,
      children: [
        Tooltip(
          message: 'Igreja e grupos (permissões) deste usuário',
          child: OutlinedButton.icon(
            style: _width(_groupsWidth),
            onPressed: () => onEditAccess(user),
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('Acesso'),
          ),
        ),
        // A própria senha não se redefine: troca-se informando a senha atual.
        if (row.isCurrentUser)
          Tooltip(
            message: 'Alterar a sua senha',
            child: OutlinedButton.icon(
              style: _width(_passwordWidth),
              onPressed: onChangeOwnPassword,
              icon: const Icon(Icons.key_outlined, size: 18),
              label: const Text('Alterar senha'),
            ),
          )
        else
          Tooltip(
            message: 'Gerar ou definir uma senha provisória',
            child: OutlinedButton.icon(
              style: _width(_passwordWidth),
              onPressed: () => onResetPassword(user),
              icon: const Icon(Icons.lock_reset_outlined, size: 18),
              label: const Text('Redefinir senha'),
            ),
          ),
        Tooltip(
          message: row.isCurrentUser
              ? 'Você não pode desativar o seu próprio usuário'
              : user.active
              ? 'Impedir o acesso deste usuário'
              : 'Liberar o acesso deste usuário de novo',
          child: OutlinedButton.icon(
            style: _width(_activeWidth, color: user.active ? AppColors.error : AppColors.success),
            onPressed: row.isCurrentUser ? null : () => onToggleActive(user),
            icon: Icon(user.active ? Icons.person_off_outlined : Icons.person_outline, size: 18),
            label: Text(user.active ? 'Desativar' : 'Reativar'),
          ),
        ),
      ],
    );
  }
}

/// Texto de uma linha só, cortado com "…" quando não cabe; apagado se o usuário estiver inativo.
class const _CellText(final String text, {required final bool active, final bool bold = false}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 600),
      child: Text(
        text,
        maxLines: 1,
        overflow: .ellipsis,
        style: TextStyle(fontWeight: bold ? FontWeight.w600 : null, color: active ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }
}

class const _Status({required final ManagedUser user}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        AccessChipWidget(
          label: user.active ? 'Ativo' : 'Inativo',
          color: user.active ? AppColors.success : AppColors.textMuted,
          background: user.active ? AppColors.successBg : AppColors.surfaceSubtle,
        ),
        if (user.firstAccess) const AccessChipWidget(label: 'Senha provisória', color: AppColors.warning, background: AppColors.warningBg),
      ],
    );
  }
}

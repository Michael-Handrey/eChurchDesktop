import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/ui/core/share/confirm_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/duplicates/duplicates_viewmodel.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:echurch_desktop/ui/members/widgets/member_status_chip.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const DuplicatesBindings({super.key, required final WidgetBuilder screenBuilder}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => DuplicatesViewModel(repository: context.read()).initialized(),
    builder: (context, child) => screenBuilder(context),
  );
}

/// Cadastros duplicados, um caso por vez: os dois cadastros lado a lado; a secretaria escolhe qual
/// fica e, nos campos diferentes (destacados), de qual vem o valor. "Juntar" desativa o outro como
/// "Cadastro duplicado" (nada é apagado). [onClose] recebe se algo mudou.
class const DuplicatesScreen({super.key, required final DuplicatesViewModel viewModel, required final ValueChanged<bool> onClose}) extends StatelessWidget {
  static void _show(BuildContext context, String message) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _merge(BuildContext context) async {
    final keep = viewModel.keep;
    final remove = viewModel.remove;
    if (keep == null || remove == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.merge_type,
      title: 'Juntar os cadastros?',
      message:
          'Fica o cadastro #${keep.id}, com os valores escolhidos, os ministérios dos dois e os cargos. '
          'O cadastro #${remove.id} é desativado como "Cadastro duplicado" (nada é apagado).',
      confirmLabel: 'Juntar',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.merge.execute();
    final result = viewModel.merge.result;
    viewModel.merge.clearResult();
    if (!context.mounted) return;
    _show(context, switch (result) {
      Error(:final error) => ErrorMessages.of(error),
      _ => 'Cadastros juntados.',
    });
  }

  Future<void> _dismiss(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.call_split,
      title: 'Não são a mesma pessoa?',
      message: 'Os dois cadastros continuam como estão e esta sugestão não aparece mais.',
      confirmLabel: 'Não são a mesma pessoa',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.dismiss.execute();
    final result = viewModel.dismiss.result;
    viewModel.dismiss.clearResult();
    if (!context.mounted) return;
    _show(context, switch (result) {
      Error(:final error) => ErrorMessages.of(error),
      _ => 'Sugestão descartada.',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load, viewModel.merge, viewModel.dismiss]),
        builder: (context, _) {
          final load = viewModel.load;
          final busy = viewModel.merge.running || viewModel.dismiss.running;
          return Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              _Header(viewModel: viewModel, busy: busy, onBack: () => onClose(viewModel.changed), onMerge: () => _merge(context), onDismiss: () => _dismiss(context)),
              Expanded(
                child: switch (load.result) {
                  Error(:final error) => _Message(icon: Icons.cloud_off_outlined, text: ErrorMessages.of(error), action: ('Tentar de novo', load.execute)),
                  _ when load.running && viewModel.isEmpty => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  _ when viewModel.pair == null => const _Message(icon: Icons.verified_outlined, text: 'Nenhum cadastro duplicado.'),
                  _ => SingleChildScrollView(child: _Comparison(viewModel: viewModel)),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class const _Header({
  required final DuplicatesViewModel viewModel,
  required final bool busy,
  required final VoidCallback onBack,
  required final VoidCallback onMerge,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final group = viewModel.current;
    final total = viewModel.groups.length;
    final subtitle = group == null ? 'A mesma pessoa com mais de um cadastro.' : 'Caso ${viewModel.index + 1} de $total · ${group.kind == DuplicateKind.cpf ? 'mesmo CPF' : 'mesmo nome e nascimento, CPF diferente'}';
    return Row(
      spacing: 8,
      children: [
        IconButton(tooltip: 'Voltar para a lista', onPressed: busy ? null : onBack, icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              const Text(
                'Cadastros duplicados',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            ],
          ),
        ),
        if (total > 1) ...[
          IconButton(tooltip: 'Caso anterior', onPressed: busy ? null : viewModel.previous, icon: const Icon(Icons.chevron_left)),
          IconButton(tooltip: 'Próximo caso (pular)', onPressed: busy ? null : viewModel.next, icon: const Icon(Icons.chevron_right)),
        ],
        if (group?.kind == DuplicateKind.nameBirth) OutlinedButton.icon(onPressed: busy ? null : onDismiss, icon: const Icon(Icons.call_split, size: 18), label: const Text('Não são a mesma pessoa')),
        if (viewModel.pair != null)
          FilledButton.icon(
            onPressed: busy ? null : onMerge,
            icon: viewModel.merge.running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.merge_type, size: 18),
            label: const Text('Juntar'),
          ),
      ],
    );
  }
}

/// Os dois cadastros lado a lado. Campos diferentes destacados: clicar no valor escolhe o que fica.
class const _Comparison({required final DuplicatesViewModel viewModel}) extends StatelessWidget {
  static String _date(DateTime? value) => value == null ? '—' : MembersViewModel.formatDate(value);

  @override
  Widget build(BuildContext context) {
    final (a, b) = viewModel.pair!;
    final differences = viewModel.differences.toSet();
    final kind = viewModel.current!.kind;

    TableRow row(String label, Widget left, Widget right, {bool highlight = false}) => TableRow(
      decoration: BoxDecoration(
        color: highlight ? AppColors.warningBg.withValues(alpha: 0.45) : null,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      children: [
        Padding(
          padding: const .symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        left,
        right,
      ],
    );

    Widget plain(String? text) => Padding(
      padding: const .symmetric(horizontal: 16, vertical: 10),
      child: Text(text ?? '—', style: TextStyle(color: text == null ? AppColors.textMuted : AppColors.textPrimary)),
    );

    Widget choice(MergeField field, DuplicateRecord record) {
      final chosen = viewModel.isChosen(field, record.id);
      final value = record.values[field];
      return InkWell(
        onTap: () => viewModel.choose(field, record.id),
        child: Padding(
          padding: const .symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Padding(
                padding: const .all(8),
                child: Icon(chosen ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: chosen ? AppColors.primary : AppColors.textMuted),
              ),
              Expanded(
                child: Text(
                  value ?? '(vazio)',
                  style: TextStyle(
                    color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                    fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                    decoration: chosen ? null : TextDecoration.lineThrough,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget header(DuplicateRecord record) {
      final keep = viewModel.keepId == record.id;
      return InkWell(
        onTap: () => viewModel.setKeep(record.id),
        child: Container(
          padding: const .all(12),
          color: keep ? AppColors.primarySubtle : AppColors.surfaceSubtle,
          child: Row(
            spacing: 8,
            children: [
              Icon(keep ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: keep ? AppColors.primary : AppColors.textMuted),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    Text('Cadastro #${record.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      keep ? 'Este fica' : 'Este será desativado',
                      style: TextStyle(color: keep ? AppColors.primary : AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              MemberStatusChip(status: record.status),
            ],
          ),
        ),
      );
    }

    final notice = kind == DuplicateKind.cpf ? 'Os dois cadastros têm o mesmo CPF: são a mesma pessoa. Escolha qual fica e, nos campos destacados, qual valor fica.' : 'Mesmo nome e data de nascimento, mas CPF diferente (talvez digitado errado). Confira se é a mesma pessoa antes de juntar.';

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 12,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(kind == DuplicateKind.cpf ? Icons.info_outline : Icons.help_outline, size: 18, color: AppColors.info),
            Expanded(
              child: Text(notice, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
        if (viewModel.extraRecords > 0)
          Text(
            'Há mais ${viewModel.extraRecords} cadastro(s) desta pessoa: depois de juntar estes dois, o próximo aparece aqui.',
            style: const TextStyle(color: AppColors.warning, fontSize: 12.5),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: .antiAlias,
          child: Table(
            columnWidths: const {0: FixedColumnWidth(190), 1: FlexColumnWidth(), 2: FlexColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [const SizedBox.shrink(), header(a), header(b)]),
              for (final field in MergeField.values)
                if (differences.contains(field)) row(field.label, choice(field, a), choice(field, b), highlight: true) else row(field.label, plain(a.values[field]), plain(b.values[field])),
              row('Cadastrado em', plain(_date(a.createdAt)), plain(_date(b.createdAt))),
              row('Credencial impressa', plain(a.credentialPrinted ? 'Sim' : 'Não'), plain(b.credentialPrinted ? 'Sim' : 'Não')),
              row('Ministérios', plain(a.ministryNames.isEmpty ? null : a.ministryNames.join(', ')), plain(b.ministryNames.isEmpty ? null : b.ministryNames.join(', '))),
              row('Cargos', plain(a.positions.isEmpty ? null : a.positions.join('\n')), plain(b.positions.isEmpty ? null : b.positions.join('\n'))),
            ],
          ),
        ),
        const Text(
          'Ao juntar: os ministérios dos dois cadastros ficam juntos e os cargos passam para o cadastro que fica. '
          'Se CPF, RG ou nascimento mudarem, a credencial precisa ser impressa de novo.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      ],
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

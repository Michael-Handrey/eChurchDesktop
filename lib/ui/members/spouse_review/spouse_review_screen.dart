import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';
import 'package:echurch_desktop/ui/core/share/confirm_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:echurch_desktop/ui/members/spouse_review/spouse_review_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const SpouseReviewBindings({super.key, required final WidgetBuilder screenBuilder}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => SpouseReviewViewModel(repository: context.read()).initialized(),
    builder: (context, child) => screenBuilder(context),
  );
}

/// Revisão de cônjuges: ligar os casais já cadastrados (em lote, um a um ou buscando o cônjuge).
/// [onClose] recebe se algo mudou (a lista de membros recarrega).
class const SpouseReviewScreen({super.key, required final SpouseReviewViewModel viewModel, required final ValueChanged<bool> onClose}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load]),
        builder: (context, _) {
          final load = viewModel.load;
          return Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              Row(
                spacing: 8,
                children: [
                  IconButton(tooltip: 'Voltar para a lista', onPressed: () => onClose(viewModel.changed), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 2,
                      children: [
                        const Text(
                          'Revisar cônjuges',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                        Text(
                          'Ligar os casais que já estão cadastrados. Falta revisar ${viewModel.review.pending}.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<SpouseReviewTab>(
                  showSelectedIcon: false,
                  segments: [
                    for (final tab in SpouseReviewTab.values) ButtonSegment(value: tab, label: Text('${SpouseReviewViewModel.tabLabel(tab)} (${viewModel.countOf(tab)})')),
                  ],
                  selected: {viewModel.tab},
                  onSelectionChanged: (selection) => viewModel.setTab(selection.first),
                ),
              ),
              Expanded(
                child: switch (load.result) {
                  Error(:final error) => _Message(icon: Icons.cloud_off_outlined, text: ErrorMessages.of(error), action: ('Tentar de novo', load.execute)),
                  _ when load.running && viewModel.review.pending == 0 => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  _ => switch (viewModel.tab) {
                    SpouseReviewTab.batch => _Batch(viewModel: viewModel),
                    SpouseReviewTab.oneByOne => _OneByOne(viewModel: viewModel),
                    SpouseReviewTab.withoutSuggestion => _Without(viewModel: viewModel),
                  },
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

void _show(BuildContext context, String message) {
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Mostra o erro do comando, ou [done] quando deu certo.
void _report(BuildContext context, Result<Object?>? result, String done) => _show(context, switch (result) {
  Error(:final error) => ErrorMessages.of(error),
  _ => done,
});

/// Busca um membro para ser o cônjuge de [person] (diálogo). Devolve o escolhido.
/// [forWrittenSpouse]: a busca é pelo cadastro do cônjuge escrito ("Cadastro de Roberta"), não "cônjuge de Aldeir".
Future<SpouseOption?> _pickMember(BuildContext context, SpouseReviewViewModel viewModel, SpousePerson person, {bool forWrittenSpouse = false}) => showDialog<SpouseOption>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(forWrittenSpouse && person.writtenSpouse != null ? 'Cadastro de ${person.writtenSpouse}' : 'Cônjuge de ${person.name}'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: 12,
        children: [
          if (forWrittenSpouse) Text('Cônjuge de ${person.name}. Busque pelo nome como está no cadastro.', style: const TextStyle(color: AppColors.textSecondary)) else if (person.writtenSpouse case final written?) Text('Escrito no cadastro: “$written”', style: const TextStyle(color: AppColors.textSecondary)),
          LookupField<SpouseOption>(
            label: 'Buscar membro',
            selected: null,
            labelOf: (option) => option.name,
            subtitleOf: (option) => option.church,
            search: (text) => viewModel.searchMembers(text, excludeId: person.id),
            onSelected: (option) => Navigator.of(dialogContext).pop(option),
          ),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar'))],
  ),
);

class const _Batch({required final SpouseReviewViewModel viewModel}) extends StatelessWidget {
  Future<void> _link(BuildContext context) async {
    final count = viewModel.checkedCount;
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.link,
      title: 'Vincular $count casais?',
      message: 'Cada pessoa passa a ter o cadastro do cônjuge ligado ao seu, nos dois lados. Dá para desfazer pelo formulário do membro ("Desvincular").',
      confirmLabel: 'Vincular',
    );
    if (!confirmed || !context.mounted) return;
    await viewModel.linkBatch.execute();
    final result = viewModel.linkBatch.result;
    viewModel.linkBatch.clearResult();
    if (context.mounted) _report(context, result, '$count casais vinculados.');
  }

  @override
  Widget build(BuildContext context) {
    final batch = viewModel.batch;
    if (batch.isEmpty) return const _Message(icon: Icons.verified_outlined, text: 'Nenhum casal de confiança alta para vincular.');
    final checked = viewModel.checkedCount;
    return ListenableBuilder(
      listenable: viewModel.linkBatch,
      builder: (context, _) => Column(
        crossAxisAlignment: .stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Checkbox(tristate: true, value: checked == batch.length ? true : (checked == 0 ? false : null), onChanged: (_) => viewModel.toggleAll(checked != batch.length)),
              Expanded(
                child: Text(
                  'Cada um tem o nome do outro, moram no mesmo endereço, os dois casados e na mesma igreja. Desmarque o que achar estranho: vai para "Um a um".',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              FilledButton.icon(
                onPressed: checked == 0 || viewModel.linkBatch.running ? null : () => _link(context),
                icon: viewModel.linkBatch.running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.link, size: 18),
                label: Text('Vincular os $checked marcados'),
              ),
            ],
          ),
          Expanded(
            child: Material(
              // Material (e não uma caixa com cor): o ListTile pinta o fundo e o clique nele.
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: batch.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSubtle),
                itemBuilder: (context, index) {
                  final suggestion = batch[index];
                  return CheckboxListTile(
                    value: viewModel.isChecked(suggestion),
                    onChanged: (value) => viewModel.toggle(suggestion, value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('${suggestion.person.name}  ⇄  ${suggestion.candidate.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [?suggestion.person.churchName, ?suggestion.person.address].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _OneByOne({required final SpouseReviewViewModel viewModel}) extends StatelessWidget {
  Future<void> _link(BuildContext context) async {
    await viewModel.linkCurrent.execute();
    final result = viewModel.linkCurrent.result;
    viewModel.linkCurrent.clearResult();
    if (context.mounted) _report(context, result, 'Casal vinculado.');
  }

  Future<void> _dismiss(BuildContext context) async {
    await viewModel.dismissCurrent.execute();
    final result = viewModel.dismissCurrent.result;
    viewModel.dismissCurrent.clearResult();
    if (context.mounted) _report(context, result, 'Sugestão descartada.');
  }

  Future<void> _searchOther(BuildContext context, SpousePerson person) async {
    final option = await _pickMember(context, viewModel, person);
    if (option?.id == null || !context.mounted) return;
    await viewModel.linkWith.execute((personId: person.id, spouseId: option!.id!));
    final result = viewModel.linkWith.result;
    viewModel.linkWith.clearResult();
    if (context.mounted) _report(context, result, 'Casal vinculado.');
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = viewModel.current;
    if (suggestion == null) return const _Message(icon: Icons.verified_outlined, text: 'Nenhuma sugestão para conferir.');
    final total = viewModel.oneByOne.length;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel.linkCurrent, viewModel.dismissCurrent, viewModel.linkWith]),
      builder: (context, _) {
        final busy = viewModel.linkCurrent.running || viewModel.dismissCurrent.running || viewModel.linkWith.running;
        return SingleChildScrollView(
          child: Container(
            padding: const .all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: 16,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    _Tag(text: 'Confiança ${suggestion.confidence.label.toLowerCase()}', color: suggestion.confidence == SpouseConfidence.medium ? AppColors.info : AppColors.warning),
                    Text(suggestion.kind.label, style: const TextStyle(color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('${viewModel.index + 1} de $total', style: const TextStyle(color: AppColors.textSecondary)),
                    IconButton(tooltip: 'Anterior', onPressed: busy ? null : viewModel.previous, icon: const Icon(Icons.chevron_left)),
                    IconButton(tooltip: 'Próxima (pular)', onPressed: busy ? null : viewModel.next, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                Row(
                  crossAxisAlignment: .start,
                  spacing: 16,
                  children: [
                    Expanded(child: _PersonCard(person: suggestion.person)),
                    const Padding(
                      padding: .only(top: 28),
                      child: Icon(Icons.sync_alt, color: AppColors.textMuted),
                    ),
                    Expanded(child: _PersonCard(person: suggestion.candidate)),
                  ],
                ),
                if (suggestion.notes.isNotEmpty)
                  Column(
                    crossAxisAlignment: .start,
                    spacing: 4,
                    children: [
                      for (final note in suggestion.notes)
                        Row(
                          spacing: 6,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                            Expanded(child: Text(note)),
                          ],
                        ),
                    ],
                  ),
                if (!suggestion.sameAddress && (suggestion.person.address != null || suggestion.candidate.address != null))
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Endereço para os dois:', style: TextStyle(fontWeight: FontWeight.w600)),
                      ChoiceChip(label: const Text('Não mexer'), selected: viewModel.addressFrom == null, onSelected: (_) => viewModel.setAddressFrom(null)),
                      if (suggestion.person.address != null) ChoiceChip(label: Text('O de ${suggestion.person.name.split(' ').first}'), selected: viewModel.addressFrom == suggestion.person.id, onSelected: (_) => viewModel.setAddressFrom(suggestion.person.id)),
                      if (suggestion.candidate.address != null) ChoiceChip(label: Text('O de ${suggestion.candidate.name.split(' ').first}'), selected: viewModel.addressFrom == suggestion.candidate.id, onSelected: (_) => viewModel.setAddressFrom(suggestion.candidate.id)),
                    ],
                  ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(onPressed: busy ? null : () => _searchOther(context, suggestion.person), icon: const Icon(Icons.search, size: 18), label: const Text('Buscar outro membro')),
                    OutlinedButton.icon(onPressed: busy ? null : () => _dismiss(context), icon: const Icon(Icons.close, size: 18), label: const Text('Não é este')),
                    FilledButton.icon(onPressed: busy ? null : () => _link(context), icon: const Icon(Icons.link, size: 18), label: const Text('Vincular')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class const _PersonCard({required final SpousePerson person}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget line(String label, String? value) => Padding(
      padding: const .only(top: 4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value ?? '—', style: TextStyle(color: value == null ? AppColors.textMuted : AppColors.textPrimary)),
          ),
        ],
      ),
    );
    return Container(
      padding: const .all(14),
      decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(person.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          line('Cônjuge escrito', person.writtenSpouse),
          line('Estado civil', person.maritalStatus?.label),
          line('Igreja', person.churchName),
          line('Endereço', person.address),
        ],
      ),
    );
  }
}

class const _Without({required final SpouseReviewViewModel viewModel}) extends StatelessWidget {
  Future<void> _search(BuildContext context, SpousePerson person) async {
    final option = await _pickMember(context, viewModel, person, forWrittenSpouse: true);
    if (option?.id == null || !context.mounted) return;
    await viewModel.linkWith.execute((personId: person.id, spouseId: option!.id!));
    final result = viewModel.linkWith.result;
    viewModel.linkWith.clearResult();
    if (context.mounted) _report(context, result, 'Casal vinculado.');
  }

  Future<void> _notMember(BuildContext context, SpousePerson person) async {
    await viewModel.notMember.execute(person.id);
    final result = viewModel.notMember.result;
    viewModel.notMember.clearResult();
    if (context.mounted) _report(context, result, 'Marcado: ${person.writtenSpouse ?? 'o cônjuge de ${person.name}'} não é membro.');
  }

  @override
  Widget build(BuildContext context) {
    final people = viewModel.withoutSuggestion;
    if (people.isEmpty) return const _Message(icon: Icons.verified_outlined, text: 'Ninguém sem sugestão.');
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 12,
      children: [
        const Text(
          'Estes cônjuges estão escritos só como nome e não correspondem a nenhum membro. Se for membro (com o nome escrito diferente), busque o cadastro; se não for, marque "Não é membro": o nome continua no cadastro do membro, sem vínculo.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Material(
            // Material (e não uma caixa com cor): o ListTile pinta o fundo e o clique nele.
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              itemCount: people.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (context, index) {
                final person = people[index];
                return ListTile(
                  // Em destaque, quem está sendo decidido: o cônjuge escrito (é membro ou não?).
                  title: Text(person.writtenSpouse ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    ['cônjuge de ${person.name}', ?person.churchName].join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(onPressed: () => _search(context, person), icon: const Icon(Icons.search, size: 18), label: const Text('Sim, buscar o cadastro')),
                      TextButton(onPressed: () => _notMember(context, person), child: const Text('Não é membro')),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class const _Tag({required final String text, required final Color color}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const .symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
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

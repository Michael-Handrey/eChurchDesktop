import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/ui/core/share/confirm_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/form/member_form_viewmodel.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:echurch_desktop/ui/members/form/widgets/member_form_sections.dart';
import 'package:material_ui/material_ui.dart';

/// Cadastro e edição de membro: uma página com índice das seções à esquerda (✓ completa,
/// ! com erro, ○ faltando obrigatório) e Cancelar/Salvar sempre visíveis no topo.
/// [onClose] recebe o id salvo, ou nulo ao cancelar.
class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key, required this.viewModel, required this.onClose});

  final MemberFormViewModel viewModel;
  final ValueChanged<int?> onClose;

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _controllers = MemberFormControllers();
  final _scroll = ScrollController();
  final _sectionKeys = {for (final section in MemberFormSection.values) section: GlobalKey()};
  var _revision = -1;

  MemberFormViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_syncTexts);
    _syncTexts();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_syncTexts);
    _controllers.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Carregou o membro ou o CEP preencheu o endereço: copia os textos para os campos.
  void _syncTexts() {
    if (_viewModel.textRevision == _revision) return;
    _revision = _viewModel.textRevision;
    _controllers.copyFrom(_viewModel.draft);
  }

  void _goTo(MemberFormSection section) {
    final context = _sectionKeys[section]?.currentContext;
    if (context != null) Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _save() async {
    await _viewModel.save.execute();
    final result = _viewModel.save.result;
    _viewModel.save.clearResult();
    if (!mounted) return;
    switch (result) {
      case Ok<int>(:final value):
        widget.onClose(value);
      case Error<int>(:final error):
        if (error is ValidationException && error.fields.isNotEmpty) {
          if (_viewModel.firstSectionWithError case final section?) _goTo(section);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMessages.of(error))));
      case null:
        break;
    }
  }

  Future<void> _cancel() async {
    if (_viewModel.hasChanges) {
      final discard = await ConfirmDialog.show(
        context,
        icon: Icons.edit_off_outlined,
        color: AppColors.error,
        title: 'Descartar as alterações?',
        message: 'O que foi preenchido e não foi salvo será perdido.',
        confirmLabel: 'Descartar',
      );
      if (!discard || !mounted) return;
    }
    widget.onClose(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([_viewModel, _viewModel.load, _viewModel.save]),
        builder: (context, _) {
          final load = _viewModel.load;
          return Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              _Header(viewModel: _viewModel, onCancel: _cancel, onSave: _save),
              Expanded(
                child: switch (load.result) {
                  Error(:final error) => _LoadError(message: ErrorMessages.of(error), onRetry: load.execute, onBack: () => widget.onClose(null)),
                  _ when load.running || _revision < 1 => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  _ => Row(
                    crossAxisAlignment: .start,
                    spacing: 24,
                    children: [
                      SizedBox(
                        width: 220,
                        child: _SectionIndex(viewModel: _viewModel, onTap: _goTo),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const .only(bottom: 240), // a última seção também chega ao topo
                          child: Column(
                            crossAxisAlignment: .stretch,
                            spacing: 16,
                            children: [
                              for (final section in MemberFormSection.values)
                                MemberFormSectionCard(
                                  key: _sectionKeys[section],
                                  section: section,
                                  child: MemberFormSectionFields(section: section, viewModel: _viewModel, controllers: _controllers),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class const _Header({required final MemberFormViewModel viewModel, required final VoidCallback onCancel, required final VoidCallback onSave}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final saving = viewModel.save.running;
    final name = viewModel.draft.name.trim();
    return Row(
      crossAxisAlignment: .center,
      spacing: 8,
      children: [
        IconButton(tooltip: 'Voltar para a lista', onPressed: saving ? null : onCancel, icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              Text(
                viewModel.isNew ? 'Novo membro' : 'Editar membro',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              Text(
                name.isEmpty ? 'Os campos com * são obrigatórios.' : name,
                maxLines: 1,
                overflow: .ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: saving ? null : onCancel, child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: saving || viewModel.load.running ? null : onSave,
          icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 18),
          label: Text(viewModel.isNew ? 'Cadastrar' : 'Salvar'),
        ),
      ],
    );
  }
}

/// Índice das seções: clicar leva até ela; o ícone mostra a situação de cada uma.
class const _SectionIndex({required final MemberFormViewModel viewModel, required final ValueChanged<MemberFormSection> onTap}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          for (final section in MemberFormSection.values)
            InkWell(
              onTap: () => onTap(section),
              child: Padding(
                padding: const .symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  spacing: 10,
                  children: [
                    switch (viewModel.statusOf(section)) {
                      SectionStatus.complete => const Icon(Icons.check_circle, size: 18, color: AppColors.success, semanticLabel: 'completa'),
                      SectionStatus.error => const Icon(Icons.error, size: 18, color: AppColors.error, semanticLabel: 'com erro'),
                      SectionStatus.pending => const Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.textMuted, semanticLabel: 'falta preencher'),
                    },
                    Expanded(
                      child: Text(
                        section.label,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class const _LoadError({required final String message, required final VoidCallback onRetry, required final VoidCallback onBack}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      spacing: 12,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textMuted),
        Text(
          message,
          textAlign: .center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Row(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Voltar')),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
      ],
    ),
  );
}

/// Textos dos campos (os de escolha ficam só no ViewModel).
class MemberFormControllers {
  final name = TextEditingController();
  final birthDate = TextEditingController();
  final cpf = TextEditingController();
  final rg = TextEditingController();
  final spouseName = TextEditingController();
  final fatherName = TextEditingController();
  final motherName = TextEditingController();
  final postalCode = TextEditingController();
  final streetName = TextEditingController();
  final streetNumber = TextEditingController();
  final complement = TextEditingController();
  final phone = TextEditingController();
  final secondaryPhone = TextEditingController();
  final email = TextEditingController();
  final baptismDate = TextEditingController();
  final acceptedJesusDate = TextEditingController();
  final notes = TextEditingController();

  List<TextEditingController> get _all => [name, birthDate, cpf, rg, spouseName, fatherName, motherName, postalCode, streetName, streetNumber, complement, phone, secondaryPhone, email, baptismDate, acceptedJesusDate, notes];

  void copyFrom(MemberDraft draft) {
    name.text = draft.name;
    birthDate.text = DateFormField.format(draft.birthDate);
    final cpfDigits = draft.cpf.replaceAll(RegExp(r'\D'), '');
    cpf.text = cpfDigits.length == 11 ? MaskFormatter.apply('###.###.###-##', cpfDigits) : draft.cpf;
    rg.text = draft.rg;
    spouseName.text = draft.spouseName;
    fatherName.text = draft.fatherName;
    motherName.text = draft.motherName;
    final cep = draft.postalCode.replaceAll(RegExp(r'\D'), '');
    postalCode.text = cep.length == 8 ? MaskFormatter.apply('#####-###', cep) : draft.postalCode;
    streetName.text = draft.streetName;
    streetNumber.text = draft.streetNumber;
    complement.text = draft.complement;
    phone.text = draft.phone;
    secondaryPhone.text = draft.secondaryPhone;
    email.text = draft.email;
    baptismDate.text = DateFormField.format(draft.baptismDate);
    acceptedJesusDate.text = DateFormField.format(draft.acceptedJesusDate);
    notes.text = draft.notes;
  }

  void dispose() {
    for (final controller in _all) {
      controller.dispose();
    }
  }
}

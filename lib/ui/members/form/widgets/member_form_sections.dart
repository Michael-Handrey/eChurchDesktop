import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/form/member_form_screen.dart';
import 'package:echurch_desktop/ui/members/form/member_form_viewmodel.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Cartão de uma seção (título + campos).
class const MemberFormSectionCard({super.key, required final MemberFormSection section, required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const .fromLTRB(20, 16, 20, 20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        Text(
          section.label.toUpperCase(),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
        child,
      ],
    ),
  );
}

/// Campos de cada seção.
class const MemberFormSectionFields({super.key, required final MemberFormSection section, required final MemberFormViewModel viewModel, required final MemberFormControllers controllers}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (section) {
    MemberFormSection.personal => _Personal(viewModel, controllers),
    MemberFormSection.documents => _Documents(viewModel, controllers),
    MemberFormSection.family => _Family(viewModel, controllers),
    MemberFormSection.address => _Address(viewModel, controllers),
    MemberFormSection.contact => _Contact(viewModel, controllers),
    MemberFormSection.church => _Church(viewModel, controllers),
    MemberFormSection.notes => _Notes(viewModel, controllers),
  };
}

/// Campo de texto ligado a um campo do rascunho.
Widget _text(
  MemberFormViewModel viewModel,
  TextEditingController controller, {
  required String field,
  required String label,
  required MemberDraft Function(MemberDraft draft, String value) apply,
  bool required = false,
  bool enabled = true,
  String? hint,
  String? helper,
  List<TextInputFormatter>? formatters,
  int? maxLength,
  int maxLines = 1,
  TextCapitalization capitalization = TextCapitalization.none,
}) => TextField(
  key: ValueKey('member-form-$field'),
  controller: controller,
  enabled: enabled,
  inputFormatters: formatters,
  maxLength: maxLength,
  maxLines: maxLines,
  minLines: maxLines > 1 ? 3 : null,
  textCapitalization: capitalization,
  onChanged: (value) => viewModel.update((draft) => apply(draft, value), field: field),
  decoration: formDecoration(label, required: required, error: viewModel.errorOf(field), hint: hint, helper: helper),
);

/// Lista de escolha ligada a um campo do rascunho. A chave muda com o valor: carregar o membro atualiza a escolha.
Widget _dropdown<T>(
  MemberFormViewModel viewModel, {
  required String field,
  required String label,
  required T? value,
  required List<(T, String)> items,
  required ValueChanged<T?> onChanged,
  bool required = false,
  String? emptyLabel,
}) => DropdownButtonFormField<T?>(
  key: ValueKey(('member-form-$field', value)),
  initialValue: value,
  isExpanded: true,
  decoration: formDecoration(label, required: required, error: viewModel.errorOf(field)),
  items: [
    if (emptyLabel != null)
      DropdownMenuItem<T?>(
        value: null,
        child: Text(emptyLabel, style: const TextStyle(color: AppColors.textSecondary)),
      ),
    for (final (item, text) in items)
      DropdownMenuItem<T?>(
        value: item,
        child: Text(text, overflow: .ellipsis),
      ),
  ],
  onChanged: onChanged,
);

void _showError(BuildContext context, Result<Object?>? result) {
  if (result case Error(:final error)) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMessages.of(error))));
}

class const _Personal(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = viewModel.draft;
    return Column(
      spacing: 16,
      children: [
        FormRow(
          flex: const [3, 1],
          children: [
            _text(
              viewModel,
              controllers.name,
              field: 'name',
              label: 'Nome completo',
              required: true,
              capitalization: TextCapitalization.words,
              apply: (d, v) => d.copyWith(name: v),
            ),
            DateFormField(
              key: const ValueKey('member-form-birthDate'),
              controller: controllers.birthDate,
              label: 'Nascimento',
              required: true,
              error: viewModel.errorOf('birthDate'),
              onChanged: (date) => viewModel.update((d) => date == null ? d.copyWith(clearBirthDate: true) : d.copyWith(birthDate: date), field: 'birthDate'),
            ),
          ],
        ),
        FormRow(
          children: [
            _dropdown<Gender>(
              viewModel,
              field: 'gender',
              label: 'Sexo',
              required: true,
              value: draft.gender,
              items: [for (final gender in Gender.values) (gender, gender.label)],
              onChanged: (value) => viewModel.update((d) => d.copyWith(gender: value), field: 'gender'),
            ),
            _dropdown<String>(
              viewModel,
              field: 'nationality',
              label: 'Nacionalidade',
              required: true,
              value: draft.nationality,
              items: [for (final option in viewModel.options.nationalities) (option.value, option.label)],
              onChanged: (value) => viewModel.update((d) => d.copyWith(nationality: value), field: 'nationality'),
            ),
            LookupField<CityOption>(
              key: const ValueKey('member-form-birthCityId'),
              label: 'Cidade de nascimento',
              required: true,
              selected: draft.birthCity,
              labelOf: (city) => city.label,
              search: viewModel.searchCities,
              error: viewModel.errorOf('birthCityId'),
              onSelected: (city) => viewModel.update((d) => d.copyWith(birthCity: city), field: 'birthCityId'),
            ),
          ],
        ),
        FormRow(
          children: [
            LookupField<NamedOption>(
              key: const ValueKey('member-form-professionId'),
              label: 'Profissão',
              selected: draft.profession,
              labelOf: (profession) => profession.name,
              search: viewModel.searchProfessions,
              createLabel: 'Cadastrar a profissão',
              onCreate: (text) async {
                await viewModel.createProfession.execute(text);
                if (context.mounted) _showError(context, viewModel.createProfession.result);
              },
              onSelected: (profession) => viewModel.update((d) => d.copyWith(profession: profession), field: 'professionId'),
            ),
            const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }
}

class const _Documents(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FormRow(
    children: [
      _text(
        viewModel,
        controllers.cpf,
        field: 'cpf',
        label: 'CPF',
        required: true,
        hint: '000.000.000-00',
        formatters: [MaskFormatter('###.###.###-##')],
        apply: (d, v) => d.copyWith(cpf: v),
      ),
      _text(
        viewModel,
        controllers.rg,
        field: 'rg',
        label: 'RG',
        required: true,
        apply: (d, v) => d.copyWith(rg: v),
      ),
    ],
  );
}

class const _Family(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final married = viewModel.draft.maritalStatus == MaritalStatus.married;
    return Column(
      spacing: 16,
      children: [
        FormRow(
          flex: const [1, 2],
          children: [
            _dropdown<MaritalStatus>(
              viewModel,
              field: 'maritalStatus',
              label: 'Estado civil',
              required: true,
              value: viewModel.draft.maritalStatus,
              items: [for (final status in MaritalStatus.values) (status, status.label)],
              onChanged: (value) => viewModel.update((d) => d.copyWith(maritalStatus: value), field: 'maritalStatus'),
            ),
            _Spouse(viewModel: viewModel, required: married),
          ],
        ),
        FormRow(
          children: [
            _text(
              viewModel,
              controllers.fatherName,
              field: 'fatherName',
              label: 'Pai',
              capitalization: TextCapitalization.words,
              apply: (d, v) => d.copyWith(fatherName: v),
            ),
            _text(
              viewModel,
              controllers.motherName,
              field: 'motherName',
              label: 'Mãe',
              required: viewModel.isMinor,
              helper: viewModel.isMinor ? 'Obrigatório para menores de 18 anos' : null,
              capitalization: TextCapitalization.words,
              apply: (d, v) => d.copyWith(motherName: v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cônjuge: busca entre os membros (vínculo nos dois lados) ou só o nome, quando não é membro.
class const _Spouse({required final MemberFormViewModel viewModel, required final bool required}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = viewModel.draft;
    final spouse = draft.spouse;
    final enabled = draft.canHaveSpouse;
    return Column(
      crossAxisAlignment: .start,
      spacing: 4,
      children: [
        LookupField<SpouseOption>(
          key: ValueKey(('member-form-spouse', draft.maritalStatus)),
          label: 'Cônjuge',
          required: required,
          enabled: enabled,
          selected: spouse,
          labelOf: (option) => option.name,
          subtitleOf: (option) => option.church,
          search: viewModel.searchSpouses,
          createLabel: 'Usar só o nome',
          createSubtitle: 'O cônjuge não é membro',
          onCreate: (text) async => viewModel.setSpouse(SpouseOption(name: text.trim())),
          onSelected: viewModel.setSpouse,
          error: viewModel.errorOf('spouseId') ?? viewModel.errorOf('spouseName'),
          helper: enabled ? null : 'Só para casados ou viúvos',
        ),
        if (enabled && spouse != null)
          Row(
            spacing: 6,
            children: [
              Icon(spouse.isLinked ? Icons.link : Icons.short_text, size: 16, color: spouse.isLinked ? AppColors.primary : AppColors.textMuted),
              Expanded(
                child: Text(
                  spouse.isLinked ? 'Vinculado ao cadastro de ${spouse.name}. Ao salvar, vale para os dois.' : 'Só o nome (não está vinculado a um cadastro).',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              if (spouse.isLinked) TextButton(onPressed: viewModel.unlinkSpouse, child: const Text('Desvincular')) else TextButton(onPressed: viewModel.clearSpouse, child: const Text('Limpar')),
            ],
          ),
      ],
    );
  }
}

class const _Address(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = viewModel.draft;
    final searching = viewModel.lookupCep.running;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        FormRow(
          flex: const [2, 2, 5],
          children: [
            TextField(
              key: const ValueKey('member-form-address.postalCode'),
              controller: controllers.postalCode,
              inputFormatters: [MaskFormatter('#####-###')],
              onChanged: (value) {
                viewModel.update((d) => d.copyWith(postalCode: value), field: 'address.postalCode');
                // CEP completo: busca o endereço sozinho.
                if (value.replaceAll(RegExp(r'\D'), '').length == 8) viewModel.lookupCep.execute();
              },
              decoration: formDecoration(
                'CEP',
                required: true,
                hint: '00000-000',
                error: viewModel.errorOf('address.postalCode'),
                suffix: searching
                    ? const Padding(
                        padding: .all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(tooltip: 'Buscar endereço pelo CEP', icon: const Icon(Icons.search, size: 18), onPressed: viewModel.lookupCep.execute),
              ),
            ),
            _dropdown<StreetType>(
              viewModel,
              field: 'address.streetType',
              label: 'Tipo',
              required: true,
              value: draft.streetType,
              items: [for (final type in StreetType.values) (type, type.label)],
              onChanged: (value) => viewModel.update((d) => d.copyWith(streetType: value), field: 'address.streetType'),
            ),
            _text(
              viewModel,
              controllers.streetName,
              field: 'address.streetName',
              label: 'Logradouro',
              required: true,
              apply: (d, v) => d.copyWith(streetName: v),
            ),
          ],
        ),
        if (viewModel.cepMessage case final message?)
          Text(
            message,
            style: const TextStyle(color: AppColors.warning, fontSize: 12.5),
          ),
        FormRow(
          flex: const [1, 3],
          children: [
            _text(
              viewModel,
              controllers.streetNumber,
              field: 'address.streetNumber',
              label: 'Número',
              required: true,
              hint: 's/n se não houver',
              apply: (d, v) => d.copyWith(streetNumber: v),
            ),
            _text(
              viewModel,
              controllers.complement,
              field: 'address.complement',
              label: 'Complemento',
              apply: (d, v) => d.copyWith(complement: v),
            ),
          ],
        ),
        FormRow(
          children: [
            LookupField<CityOption>(
              key: const ValueKey('member-form-address.city'),
              label: 'Cidade',
              selected: draft.city,
              labelOf: (city) => city.label,
              search: viewModel.searchCities,
              onSelected: viewModel.setCity,
            ),
            LookupField<NamedOption>(
              key: ValueKey(('member-form-address.district', draft.city?.id)),
              label: 'Bairro',
              enabled: draft.city != null,
              helper: draft.city == null ? 'Escolha a cidade primeiro' : null,
              selected: draft.district,
              labelOf: (district) => district.name,
              search: (text) => [
                for (final district in viewModel.districts)
                  if (district.name.toLowerCase().contains(text.toLowerCase())) district,
              ],
              createLabel: 'Cadastrar o bairro',
              onCreate: (text) async {
                await viewModel.createDistrict.execute(text);
                if (context.mounted) _showError(context, viewModel.createDistrict.result);
              },
              onSelected: (district) => viewModel.update((d) => d.copyWith(district: district), field: 'address.district'),
            ),
          ],
        ),
        if (viewModel.suggestedDistrict case final district?)
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              Expanded(
                child: Text('O CEP indica o bairro “$district”, que ainda não está no cadastro.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ),
              TextButton(
                onPressed: viewModel.createDistrict.running
                    ? null
                    : () async {
                        await viewModel.createDistrict.execute(district);
                        if (context.mounted) _showError(context, viewModel.createDistrict.result);
                      },
                child: Text('Cadastrar “$district”'),
              ),
            ],
          ),
      ],
    );
  }
}

class const _Contact(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FormRow(
    flex: const [2, 2, 3],
    children: [
      _text(
        viewModel,
        controllers.phone,
        field: 'contact.phone',
        label: 'Telefone',
        hint: '(00) 00000-0000',
        formatters: [MaskFormatter.phone()],
        apply: (d, v) => d.copyWith(phone: v),
      ),
      _text(
        viewModel,
        controllers.secondaryPhone,
        field: 'contact.secondaryPhone',
        label: 'Outro telefone',
        formatters: [MaskFormatter.phone()],
        apply: (d, v) => d.copyWith(secondaryPhone: v),
      ),
      _text(
        viewModel,
        controllers.email,
        field: 'contact.email',
        label: 'E-mail',
        apply: (d, v) => d.copyWith(email: v),
      ),
    ],
  );
}

class const _Church(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = viewModel.draft;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        FormRow(
          children: [
            _dropdown<int>(
              viewModel,
              field: 'churchId',
              label: 'Igreja',
              required: true,
              value: draft.churchId,
              items: [for (final church in viewModel.churches) (church.id, church.name)],
              onChanged: (value) => viewModel.update((d) => d.copyWith(churchId: value), field: 'churchId'),
            ),
            _dropdown<int>(
              viewModel,
              field: 'ecclesiasticalRoleId',
              label: 'Cargo',
              value: draft.ecclesiasticalRoleId,
              emptyLabel: 'Sem cargo',
              items: [for (final role in viewModel.options.roles) (role.id, role.name)],
              onChanged: (value) => viewModel.update((d) => value == null ? d.copyWith(clearRole: true) : d.copyWith(ecclesiasticalRoleId: value), field: 'ecclesiasticalRoleId'),
            ),
          ],
        ),
        FormRow(
          children: [
            DateFormField(
              key: const ValueKey('member-form-baptismDate'),
              controller: controllers.baptismDate,
              label: 'Batismo',
              error: viewModel.errorOf('baptismDate'),
              onChanged: (date) => viewModel.update((d) => date == null ? d.copyWith(clearBaptismDate: true) : d.copyWith(baptismDate: date), field: 'baptismDate'),
            ),
            DateFormField(
              key: const ValueKey('member-form-acceptedJesusDate'),
              controller: controllers.acceptedJesusDate,
              label: 'Aceitou Jesus',
              error: viewModel.errorOf('acceptedJesusDate'),
              onChanged: (date) => viewModel.update((d) => date == null ? d.copyWith(clearAcceptedJesusDate: true) : d.copyWith(acceptedJesusDate: date), field: 'acceptedJesusDate'),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: .start,
          spacing: 8,
          children: [
            const Text('Ministérios', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (viewModel.options.ministries.isEmpty)
              const Text('Nenhum ministério cadastrado.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ministry in viewModel.options.ministries)
                    FilterChip(
                      label: Text(ministry.name),
                      selected: draft.ministryIds.contains(ministry.id),
                      onSelected: (selected) => viewModel.toggleMinistry(ministry.id, selected),
                      selectedColor: AppColors.primarySubtle,
                      checkmarkColor: AppColors.primary,
                    ),
                ],
              ),
            if (draft.leaderships.isNotEmpty)
              Text(
                '${draft.leaderships.join(' · ')} (no cadastro de Ministérios).',
                key: const ValueKey('member-form-leaderships'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: .start,
          spacing: 8,
          children: [
            const Text('Funções ministeriais', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (viewModel.options.ministerialRoles.isEmpty)
              const Text('Nenhuma função cadastrada.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in viewModel.options.ministerialRoles)
                    FilterChip(
                      label: Text(role.name),
                      selected: draft.ministerialRoleIds.contains(role.id),
                      onSelected: (selected) => viewModel.toggleMinisterialRole(role.id, selected),
                      selectedColor: AppColors.primarySubtle,
                      checkmarkColor: AppColors.primary,
                    ),
                ],
              ),
            const Text(
              'Líder e vice-líder de ministério: no cadastro de Ministérios.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class const _Notes(final MemberFormViewModel viewModel, final MemberFormControllers controllers) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _text(
    viewModel,
    controllers.notes,
    field: 'notes',
    label: 'Observações',
    maxLines: 6,
    maxLength: MemberFormViewModel.maxNotes,
    apply: (d, v) => d.copyWith(notes: v),
  );
}

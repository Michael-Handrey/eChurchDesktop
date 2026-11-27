import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/child/child.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';
import 'package:echurch_desktop/ui/children/children_viewmodel.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:material_ui/material_ui.dart';

/// Cadastrar ou editar uma criança: nome, nascimento, igreja, ministério (só os da faixa de idade),
/// responsáveis (membros, com o parentesco) e observações. Ao escolher um responsável com cônjuge
/// vinculado, sugere incluir o cônjuge também. Fecha devolvendo `true` quando salvou.
class ChildFormDialog extends StatefulWidget {
  const ChildFormDialog({super.key, required this.viewModel, this.childId, this.today});

  final ChildrenViewModel viewModel;

  /// Nulo = cadastro novo.
  final int? childId;

  /// Data de hoje (os testes fixam).
  final DateTime? today;

  static Future<bool?> show(BuildContext context, {required ChildrenViewModel viewModel, int? childId}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChildFormDialog(viewModel: viewModel, childId: childId),
  );

  @override
  State<ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<ChildFormDialog> {
  final _name = TextEditingController();
  final _birth = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _birthDate;
  late int? _churchId = widget.viewModel.churchId;
  int? _ministryId;

  /// Ministério gravado (continua valendo fora da faixa até a secretaria decidir).
  Ministry? _currentMinistry;
  var _guardians = <ChildGuardian>[];

  /// Responsável escolhido cujo cônjuge vinculado ainda não está na lista.
  GuardianOption? _spouseSuggestion;
  var _loading = false;
  String? _error;

  DateTime get _today => widget.today ?? DateTime.now();
  bool get _isNew => widget.childId == null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (!_isNew) _loadChild();
  }

  Future<void> _loadChild() async {
    setState(() => _loading = true);
    final command = widget.viewModel.details;
    await command.execute(widget.childId!);
    final result = command.result;
    command.clearResult();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok<ChildDetails>(:final value):
          _name.text = value.name;
          _birthDate = value.birthDate;
          _birth.text = DateFormField.format(value.birthDate);
          _notes.text = value.notes ?? '';
          _churchId = value.churchId ?? _churchId;
          _ministryId = value.ministryId;
          if (value.ministryId case final id?) {
            _currentMinistry = widget.viewModel.childMinistries.where((ministry) => ministry.id == id).firstOrNull ?? Ministry(id: id, type: '', name: value.ministryName ?? '');
          }
          _guardians = [...value.guardians];
        case Error<ChildDetails>(:final error):
          _error = ErrorMessages.of(error);
        case null:
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _birth.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _age => _birthDate == null ? null : ageAt(_birthDate!, _today);

  /// Os da faixa de idade, mais o que ela já tem (mesmo fora da faixa).
  List<Ministry> get _ministryOptions {
    if (_birthDate == null) return const [];
    final compatible = widget.viewModel.ministriesFor(_birthDate!, today: _today);
    final current = _currentMinistry;
    return [
      ...compatible,
      if (current != null && !compatible.any((ministry) => ministry.id == current.id)) current,
    ];
  }

  String? get _birthError {
    final age = _age;
    if (_birthDate == null || age == null) return null;
    if (_birthDate!.isAfter(_today)) return 'Data no futuro';
    if (age > 17 && _isNew) return 'Com 18 anos ou mais, cadastre como membro';
    return null;
  }

  bool get _valid => _name.text.trim().isNotEmpty && _birthDate != null && _birthError == null && _churchId != null && _guardians.isNotEmpty;

  void _onBirthChanged(DateTime? date) => setState(() {
    _birthDate = date;
    _error = null;
    // Ministério que não cabe mais na idade sai (o gravado fica).
    if (_ministryId case final id? when id != _currentMinistry?.id && !_ministryOptions.any((ministry) => ministry.id == id)) _ministryId = null;
  });

  void _addGuardian(GuardianOption option) => setState(() {
    _error = null;
    if (_guardians.any((guardian) => guardian.personId == option.id)) return;
    _guardians = [..._guardians, ChildGuardian(personId: option.id, name: option.name, kinship: Kinship.parentFor(option.gender), churchName: option.churchName)];
    final spouseId = option.spouseId;
    _spouseSuggestion = spouseId != null && !_guardians.any((guardian) => guardian.personId == spouseId) ? option : null;
  });

  void _acceptSpouse() => setState(() {
    final option = _spouseSuggestion;
    if (option == null || option.spouseId == null) return;
    _guardians = [..._guardians, ChildGuardian(personId: option.spouseId!, name: option.spouseName ?? '', kinship: Kinship.parentFor(option.spouseGender))];
    _spouseSuggestion = null;
  });

  void _removeGuardian(ChildGuardian guardian) => setState(() {
    _guardians = [
      for (final item in _guardians)
        if (item.personId != guardian.personId) item,
    ];
    if (_spouseSuggestion?.id == guardian.personId) _spouseSuggestion = null;
  });

  void _setKinship(ChildGuardian guardian, Kinship kinship) => setState(() {
    _guardians = [for (final item in _guardians) item.personId == guardian.personId ? item.withKinship(kinship) : item];
  });

  Future<void> _save() async {
    final command = widget.viewModel.save;
    await command.execute((
      id: widget.childId,
      name: _name.text,
      birthDate: _birthDate!,
      churchId: _churchId!,
      ministryId: _ministryId,
      notes: _notes.text,
      guardians: _guardians,
    ));
    final result = command.result;
    command.clearResult();
    if (!mounted) return;
    switch (result) {
      case Error(:final error):
        setState(() => _error = ErrorMessages.of(error));
      default:
        Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, widget.viewModel.save]),
      builder: (context, _) {
        final running = widget.viewModel.save.running;
        final age = _age;
        final options = _ministryOptions;
        return AlertDialog(
          icon: const Icon(Icons.face_outlined, color: AppColors.primary),
          title: Text(_isNew ? 'Nova criança' : 'Editar cadastro'),
          content: SizedBox(
            width: 620,
            child: _loading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .stretch,
                      spacing: 14,
                      children: [
                        TextField(
                          key: const ValueKey('child-name'),
                          controller: _name,
                          enabled: !running,
                          autofocus: _isNew,
                          textCapitalization: TextCapitalization.words,
                          decoration: formDecoration('Nome', required: true),
                        ),
                        Row(
                          crossAxisAlignment: .start,
                          spacing: 12,
                          children: [
                            Expanded(
                              child: DateFormField(
                                key: const ValueKey('child-birth'),
                                controller: _birth,
                                label: 'Nascimento',
                                required: true,
                                error: _birthError,
                                lastDate: _today,
                                onChanged: _onBirthChanged,
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: widget.viewModel.churches.any((church) => church.id == _churchId) ? _churchId : null,
                                isExpanded: true,
                                decoration: formDecoration('Igreja', required: true),
                                items: [
                                  for (final church in widget.viewModel.churches)
                                    DropdownMenuItem(
                                      value: church.id,
                                      child: Text(church.name, overflow: .ellipsis),
                                    ),
                                ],
                                onChanged: running || !_isNew ? null : (value) => setState(() => _churchId = value),
                              ),
                            ),
                          ],
                        ),
                        DropdownButtonFormField<int?>(
                          key: ValueKey(('child-ministry', options.length, _birthDate)),
                          initialValue: options.any((ministry) => ministry.id == _ministryId) ? _ministryId : null,
                          isExpanded: true,
                          decoration: formDecoration(
                            'Ministério',
                            helper: switch (age) {
                              null => 'Informe o nascimento para ver os ministérios da idade.',
                              _ when options.isEmpty => 'Nenhum ministério para $age ${age == 1 ? 'ano' : 'anos'} (ex.: de 0 a 2 anos).',
                              _ => null,
                            },
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Sem ministério')),
                            for (final ministry in options)
                              DropdownMenuItem<int?>(
                                value: ministry.id,
                                child: Text(
                                  [
                                    ministry.name,
                                    if (ministry.ageRangeLabel case final range?) '($range)',
                                    if (age != null && ministry.minAge != null && (age < ministry.minAge! || age > ministry.maxAge!)) '— fora da faixa',
                                  ].join(' '),
                                  overflow: .ellipsis,
                                ),
                              ),
                          ],
                          onChanged: running || options.isEmpty ? null : (value) => setState(() => _ministryId = value),
                        ),
                        const Text(
                          'Responsáveis *',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                        LookupField<GuardianOption>(
                          label: 'Incluir responsável (membro)',
                          selected: null,
                          labelOf: (option) => option.name,
                          subtitleOf: (option) => [?option.churchName, if (option.spouseName case final spouse?) 'cônjuge: $spouse'].join(' · '),
                          search: widget.viewModel.searchGuardians,
                          enabled: !running,
                          onSelected: _addGuardian,
                        ),
                        if (_spouseSuggestion case final option?)
                          Container(
                            key: const ValueKey('child-spouse-suggestion'),
                            padding: const .symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primarySubtle, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              spacing: 8,
                              children: [
                                const Icon(Icons.favorite_border, size: 18, color: AppColors.primary),
                                Expanded(child: Text('Incluir também ${option.spouseName}, cônjuge de ${option.name}?')),
                                TextButton(onPressed: () => setState(() => _spouseSuggestion = null), child: const Text('Não')),
                                FilledButton.tonal(onPressed: _acceptSpouse, child: const Text('Incluir')),
                              ],
                            ),
                          ),
                        if (_guardians.isEmpty)
                          const Text('Inclua pelo menos um responsável membro.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5))
                        else
                          for (final guardian in _guardians)
                            Row(
                              key: ValueKey(('child-guardian', guardian.personId)),
                              spacing: 12,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(guardian.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (guardian.churchName case final church?) Text(church, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<Kinship>(
                                    initialValue: guardian.kinship,
                                    isExpanded: true,
                                    decoration: formDecoration('Parentesco'),
                                    items: [for (final kinship in Kinship.values) DropdownMenuItem(value: kinship, child: Text(kinship.label))],
                                    onChanged: running ? null : (value) => _setKinship(guardian, value ?? guardian.kinship),
                                  ),
                                ),
                                IconButton(tooltip: 'Tirar', onPressed: running ? null : () => _removeGuardian(guardian), icon: const Icon(Icons.close, size: 18)),
                              ],
                            ),
                        TextField(
                          controller: _notes,
                          enabled: !running,
                          maxLines: 2,
                          maxLength: 500,
                          decoration: formDecoration('Observações'),
                        ),
                        if (_error case final message?) AppErrorBanner(message: message),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: running || _loading || !_valid ? null : _save,
              child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isNew ? 'Cadastrar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:async';

import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/member/lookup_repository.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:flutter/foundation.dart';

/// Seções do formulário, na ordem da página e do índice. [fields]: os campos de cada uma (mesmos
/// nomes da API), para marcar no índice a seção com erro.
enum MemberFormSection {
  personal('Dados pessoais', {'name', 'birthDate', 'gender', 'nationality', 'birthCityId', 'professionId'}),
  documents('Documentos', {'cpf', 'rg'}),
  family('Família', {'maritalStatus', 'spouseName', 'spouseId', 'fatherName', 'motherName'}),
  address('Endereço', {'address', 'address.postalCode', 'address.streetType', 'address.streetName', 'address.streetNumber', 'address.complement', 'address.district', 'address.city'}),
  contact('Contato', {'contact', 'contact.phone', 'contact.secondaryPhone', 'contact.email'}),
  church('Igreja', {'churchId', 'ecclesiasticalRoleId', 'ministryIds', 'baptismDate', 'acceptedJesusDate'}),
  notes('Observações', {'notes'});

  const MemberFormSection(this.label, this.fields);

  final String label;
  final Set<String> fields;

  static MemberFormSection? of(String field) => values.where((section) => section.fields.contains(field)).firstOrNull;
}

/// Situação da seção no índice: completa (✓), com erro (!) ou faltando algo obrigatório (○).
enum SectionStatus { complete, error, pending }

/// Cadastro ([memberId] nulo) ou edição de um membro: página com índice. Os campos de texto ficam
/// nos controllers da tela; cada mudança chega aqui por [update]. O que muda os textos por fora
/// (carregar o membro, preencher pelo CEP) aumenta [textRevision] para a tela copiar de volta.
class MemberFormViewModel({
  required final MemberRepository _members,
  required final LookupRepository _lookup,
  required final ChurchContextNotifier _churchContext,
  final int? memberId,
}) extends ChangeNotifier implements ViewModelInitializable {
  static const maxNotes = 2000;

  final _log = AppLogger('MemberFormViewModel');

  late final load = Command0<void>(_load);
  late final save = Command0<int>(_save);
  late final lookupCep = Command0<CepAddress>(_lookupCep);
  late final createDistrict = Command1<NamedOption, String>(_createDistrict);
  late final createProfession = Command1<NamedOption, String>(_createProfession);

  var _draft = const MemberDraft();
  var _initial = const MemberDraft();
  var _options = const MemberFormOptions();
  var _districts = const <NamedOption>[];
  var _errors = const <String, String>{};
  var _submitted = false;
  var _textRevision = 0;
  String? _cepMessage;

  /// Bairro que veio do CEP e ainda não existe no cadastro (oferece criar).
  String? _suggestedDistrict;

  @override
  void init() => load.execute();

  bool get isNew => memberId == null;
  MemberDraft get draft => _draft;
  MemberFormOptions get options => _options;
  List<NamedOption> get districts => _districts;
  List<ChurchSummary> get churches => _churchContext.churches;
  int get textRevision => _textRevision;
  String? get cepMessage => _cepMessage;
  String? get suggestedDistrict => _suggestedDistrict;

  /// Algo mudou desde que abriu (para confirmar ao cancelar).
  bool get hasChanges => _draft != _initial;

  /// Menor de 18 anos: o nome da mãe é obrigatório (regra atual da API).
  bool get isMinor => (_draft.ageAt(DateTime.now()) ?? 99) < 18;

  /// Erro do campo (só depois da primeira tentativa de salvar, ou vindo da API).
  String? errorOf(String field) => _errors[field];
  Map<String, String> get errors => _errors;

  SectionStatus statusOf(MemberFormSection section) {
    final missing = _requiredErrors(_draft);
    if (_submitted && section.fields.any(_errors.containsKey)) return SectionStatus.error;
    return section.fields.any(missing.containsKey) ? SectionStatus.pending : SectionStatus.complete;
  }

  /// Primeira seção com erro (para rolar até ela depois de salvar).
  MemberFormSection? get firstSectionWithError => MemberFormSection.values.where((section) => section.fields.any(_errors.containsKey)).firstOrNull;

  /// Muda o rascunho. [field]: o campo mexido (apaga o erro dele).
  void update(MemberDraft Function(MemberDraft draft) change, {String? field}) {
    _draft = change(_draft);
    if (field != null && _errors.containsKey(field)) {
      _errors = {..._errors}..remove(field);
    }
    if (_submitted) _errors = {..._validate(_draft), ..._serverOnly()};
    notifyListeners();
  }

  /// Escolheu a cidade do endereço: carrega os bairros e limpa o bairro de outra cidade.
  Future<void> setCity(CityOption? city) async {
    if (city == null) return;
    final changed = city.id != _draft.city?.id;
    update(
      (draft) => draft.copyWith(city: city, clearDistrict: changed),
      field: 'address.city',
    );
    if (changed) _suggestedDistrict = null;
    await _loadDistricts(city.id);
  }

  /// Cidades para o autocompletar (a partir de 2 letras).
  Future<List<CityOption>> searchCities(String text) async => switch (await _lookup.cities(text)) {
    Ok<List<CityOption>>(:final value) => value,
    Error<List<CityOption>>() => const [],
  };

  /// Profissões para o autocompletar.
  Future<List<NamedOption>> searchProfessions(String text) async => switch (await _lookup.professions(text)) {
    Ok<List<NamedOption>>(:final value) => value,
    Error<List<NamedOption>>() => const [],
  };

  /// Membros para o campo Cônjuge (todas as igrejas do alcance; sem o próprio membro).
  Future<List<SpouseOption>> searchSpouses(String text) async {
    if (text.trim().length < 2) return const [];
    return switch (await _members.search(text: text, size: 8)) {
      Ok(:final value) => [
        for (final member in value.items)
          if (member.id != _draft.id) SpouseOption(id: member.id, name: member.name, church: member.churchName),
      ],
      Error() => const [],
    };
  }

  /// Escolheu o cônjuge: cadastrado (vínculo) ou só o nome (não é membro).
  void setSpouse(SpouseOption spouse) => update(
    (draft) => spouse.isLinked ? draft.copyWith(spouseId: spouse.id, spouseName: spouse.name) : draft.copyWith(clearSpouseId: true, spouseName: spouse.name),
    field: 'spouseName',
  );

  /// Tira o vínculo: o nome fica escrito (como cônjuge que não está cadastrado).
  void unlinkSpouse() => update((draft) => draft.copyWith(clearSpouseId: true), field: 'spouseId');

  /// Sem cônjuge (campo vazio).
  void clearSpouse() => update((draft) => draft.copyWith(clearSpouseId: true, spouseName: ''), field: 'spouseName');

  void toggleMinistry(int id, bool selected) {
    final ids = {..._draft.ministryIds};
    selected ? ids.add(id) : ids.remove(id);
    update((draft) => draft.copyWith(ministryIds: ids), field: 'ministryIds');
  }

  Future<Result<void>> _load() async {
    final optionsResult = await _members.formOptions();
    if (optionsResult case Ok<MemberFormOptions>(:final value)) {
      _options = value;
    } else if (optionsResult case Error<MemberFormOptions>(:final error)) {
      _log.error('Falha ao carregar as opções do formulário', error: error, stackTrace: error.stackTrace);
      notifyListeners();
      return Result.error(error);
    }

    final id = memberId;
    if (id == null) {
      _draft = MemberDraft(churchId: _churchContext.selected?.id);
    } else {
      switch (await _members.loadForEdit(id)) {
        case Ok<MemberDraft>(:final value):
          _draft = value;
          if (value.city case final city?) await _loadDistricts(city.id);
        case Error<MemberDraft>(:final error):
          _log.error('Falha ao carregar o membro $id', error: error, stackTrace: error.stackTrace);
          notifyListeners();
          return Result.error(error);
      }
    }
    _initial = _draft;
    _textRevision++;
    notifyListeners();
    return Result.done;
  }

  Future<void> _loadDistricts(int cityId) async {
    switch (await _lookup.districts(cityId)) {
      case Ok<List<NamedOption>>(:final value):
        _districts = value;
      case Error<List<NamedOption>>(:final error):
        _log.error('Falha ao carregar os bairros', error: error, stackTrace: error.stackTrace);
        _districts = const [];
    }
    notifyListeners();
  }

  /// Preenche o endereço pelo CEP (8 dígitos). Não apaga o número; o complemento só se estiver vazio.
  Future<Result<CepAddress>> _lookupCep() async {
    final digits = _draft.postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return Result.error(const ValidationException('O CEP tem 8 números.'));
    _cepMessage = null;
    final result = await _lookup.cep(digits);
    switch (result) {
      case Ok<CepAddress>(:final value):
        final city = value.cityId == null ? null : CityOption(id: value.cityId!, name: value.city, state: value.state);
        _draft = _draft.copyWith(
          streetType: value.streetType,
          streetName: value.street.isEmpty ? null : value.street,
          complement: _draft.complement.trim().isEmpty && value.complement.isNotEmpty ? value.complement : null,
          city: city,
          district: value.districtId == null ? null : NamedOption(id: value.districtId!, name: value.district),
          clearDistrict: value.districtId == null && city != null,
        );
        _suggestedDistrict = value.districtId == null && value.district.isNotEmpty ? value.district : null;
        if (city == null) _cepMessage = 'A cidade ${value.city}/${value.state} não está no cadastro. Escolha a cidade.';
        _errors = {..._errors}..removeWhere((key, _) => key.startsWith('address'));
        _textRevision++;
        notifyListeners();
        if (city != null) unawaited(_loadDistricts(city.id));
      case Error<CepAddress>(:final error):
        _cepMessage = error is NotFoundException ? 'CEP não encontrado. Confira os números ou preencha o endereço.' : 'Não foi possível consultar o CEP agora. Preencha o endereço.';
        notifyListeners();
    }
    return result;
  }

  Future<Result<NamedOption>> _createDistrict(String name) async {
    final city = _draft.city;
    if (city == null) return Result.error(const ValidationException('Escolha a cidade antes do bairro.'));
    final result = await _lookup.createDistrict(city.id, name);
    if (result case Ok<NamedOption>(:final value)) {
      _districts = [..._districts.where((item) => item.id != value.id), value]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _suggestedDistrict = null;
      update((draft) => draft.copyWith(district: value), field: 'address.district');
    }
    return result;
  }

  Future<Result<NamedOption>> _createProfession(String name) async {
    final result = await _lookup.createProfession(name);
    if (result case Ok<NamedOption>(:final value)) {
      update((draft) => draft.copyWith(profession: value), field: 'professionId');
    }
    return result;
  }

  Future<Result<int>> _save() async {
    _submitted = true;
    final errors = _validate(_draft);
    if (errors.isNotEmpty) {
      _errors = errors;
      notifyListeners();
      return Result.error(ValidationException('Revise os campos destacados.', fields: errors));
    }
    final result = await _members.save(_draft);
    switch (result) {
      case Ok<int>(:final value):
        _log.info('Membro $value ${isNew ? 'cadastrado' : 'alterado'}');
        _initial = _draft;
        _errors = const {};
      case Error<int>(:final error):
        _log.error('Falha ao salvar o membro', error: error, stackTrace: error.stackTrace);
        if (error case ValidationException(:final fields) when fields.isNotEmpty) _errors = fields;
    }
    notifyListeners();
    return result;
  }

  /// Erros que só a API sabe (ex.: CPF já cadastrado) continuam até o campo mudar.
  Map<String, String> _serverOnly() => {
    for (final MapEntry(:key, :value) in _errors.entries)
      if (!_requiredErrors(_draft).containsKey(key) && key == 'cpf' && value.startsWith('Já existe')) key: value,
  };

  /// Obrigatórios que faltam (sem contar formato).
  Map<String, String> _requiredErrors(MemberDraft draft) {
    const required = 'Obrigatório';
    return {
      if (draft.name.trim().isEmpty) 'name': required,
      if (draft.birthDate == null) 'birthDate': required,
      if (draft.gender == null) 'gender': required,
      if (draft.nationality.isEmpty) 'nationality': required,
      if (draft.birthCity == null) 'birthCityId': required,
      if (draft.cpf.replaceAll(RegExp(r'\D'), '').isEmpty) 'cpf': required,
      if (draft.rg.trim().isEmpty) 'rg': required,
      if (draft.maritalStatus == null) 'maritalStatus': required,
      if (draft.maritalStatus == MaritalStatus.married && draft.spouseName.trim().isEmpty) 'spouseName': required,
      if ((draft.ageAt(DateTime.now()) ?? 99) < 18 && draft.motherName.trim().isEmpty) 'motherName': required,
      if (draft.postalCode.replaceAll(RegExp(r'\D'), '').isEmpty) 'address.postalCode': required,
      if (draft.streetType == null) 'address.streetType': required,
      if (draft.streetName.trim().isEmpty) 'address.streetName': required,
      if (draft.streetNumber.trim().isEmpty) 'address.streetNumber': required,
      if (draft.churchId == null) 'churchId': required,
    };
  }

  Map<String, String> _validate(MemberDraft draft) {
    final errors = _requiredErrors(draft);
    final cpf = draft.cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.isNotEmpty && !isValidCpf(cpf)) errors['cpf'] = 'CPF inválido';
    final cep = draft.postalCode.replaceAll(RegExp(r'\D'), '');
    if (cep.isNotEmpty && cep.length != 8) errors['address.postalCode'] = 'O CEP tem 8 números';
    final email = draft.email.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) errors['contact.email'] = 'E-mail inválido';
    final birth = draft.birthDate;
    final today = DateTime.now();
    if (birth != null && birth.isAfter(today)) errors['birthDate'] = 'Data no futuro';
    for (final (field, date) in [('baptismDate', draft.baptismDate), ('acceptedJesusDate', draft.acceptedJesusDate)]) {
      if (date == null) continue;
      if (date.isAfter(today)) {
        errors[field] = 'Data no futuro';
      } else if (birth != null && date.isBefore(birth)) {
        errors[field] = 'Antes do nascimento';
      }
    }
    if (draft.notes.length > maxNotes) errors['notes'] = 'No máximo $maxNotes caracteres';
    return errors;
  }

  /// CPF com 11 números e dígitos verificadores certos.
  static bool isValidCpf(String digits) {
    if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;
    final numbers = [for (final char in digits.split('')) int.parse(char)];
    int check(int length) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += numbers[i] * (length + 1 - i);
      }
      final rest = (sum * 10) % 11;
      return rest == 10 ? 0 : rest;
    }

    return check(9) == numbers[9] && check(10) == numbers[10];
  }

  @override
  void dispose() {
    load.dispose();
    save.dispose();
    lookupCep.dispose();
    createDistrict.dispose();
    createProfession.dispose();
    super.dispose();
  }
}

import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';
import 'package:flutter/foundation.dart';

/// Abas da revisão: em lote (confiança alta), um a um (média e baixa) e sem sugestão.
enum SpouseReviewTab { batch, oneByOne, withoutSuggestion }

/// Revisão de cônjuges (decisão 7): ligar os casais que já estão cadastrados.
/// - **Em lote:** os de confiança alta, todos marcados; a secretaria desmarca o que achar estranho.
/// - **Um a um:** média e baixa; vincular (com a escolha do endereço), "não é este", buscar outro, pular.
/// - **Sem sugestão:** buscar o cônjuge entre os membros ou "não é membro".
class SpouseReviewViewModel({required final MemberRepository _repository}) extends ChangeNotifier implements ViewModelInitializable {
  final _log = AppLogger('SpouseReviewViewModel');

  late final load = Command0<void>(_load);
  late final linkBatch = Command0<int>(_linkBatch);
  late final linkCurrent = Command0<void>(_linkCurrent);
  late final dismissCurrent = Command0<void>(_dismissCurrent);
  late final linkWith = Command1<void, ({int personId, int spouseId})>(_linkWith);
  late final notMember = Command1<void, int>(_notMember);

  var _review = const SpouseReview();
  var _tab = SpouseReviewTab.batch;
  var _index = 0;
  var _changed = false;

  /// Lote: pares desmarcados (pelo id de quem tem o cônjuge escrito).
  final _unchecked = <int>{};

  /// Um a um: de quem é o endereço que fica para os dois (nulo = não mexer).
  int? _addressFrom;

  @override
  void init() => load.execute();

  SpouseReview get review => _review;
  SpouseReviewTab get tab => _tab;
  bool get changed => _changed;

  List<SpouseSuggestion> get batch => [
    for (final suggestion in _review.suggestions)
      if (suggestion.confidence == SpouseConfidence.high) suggestion,
  ];

  List<SpouseSuggestion> get oneByOne => [
    for (final suggestion in _review.suggestions)
      if (suggestion.confidence != SpouseConfidence.high) suggestion,
  ];

  List<SpousePerson> get withoutSuggestion => _review.withoutSuggestion;

  int countOf(SpouseReviewTab tab) => switch (tab) {
    SpouseReviewTab.batch => batch.length,
    SpouseReviewTab.oneByOne => oneByOne.length,
    SpouseReviewTab.withoutSuggestion => withoutSuggestion.length,
  };

  static String tabLabel(SpouseReviewTab tab) => switch (tab) {
    SpouseReviewTab.batch => 'Em lote (confiança alta)',
    SpouseReviewTab.oneByOne => 'Um a um',
    SpouseReviewTab.withoutSuggestion => 'Sem sugestão',
  };

  void setTab(SpouseReviewTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  // ---- lote

  bool isChecked(SpouseSuggestion suggestion) => !_unchecked.contains(suggestion.person.id);

  int get checkedCount => batch.where(isChecked).length;

  void toggle(SpouseSuggestion suggestion, bool checked) {
    checked ? _unchecked.remove(suggestion.person.id) : _unchecked.add(suggestion.person.id);
    notifyListeners();
  }

  /// Marca ou desmarca todos do lote.
  void toggleAll(bool checked) {
    checked ? _unchecked.clear() : _unchecked.addAll(batch.map((suggestion) => suggestion.person.id));
    notifyListeners();
  }

  // ---- um a um

  int get index => _index;
  SpouseSuggestion? get current => oneByOne.isEmpty ? null : oneByOne[_index.clamp(0, oneByOne.length - 1)];
  int? get addressFrom => _addressFrom;

  void setAddressFrom(int? personId) {
    _addressFrom = personId;
    notifyListeners();
  }

  void next() {
    if (oneByOne.length < 2) return;
    _index = (_index + 1) % oneByOne.length;
    _addressFrom = null;
    notifyListeners();
  }

  void previous() {
    if (oneByOne.length < 2) return;
    _index = (_index - 1 + oneByOne.length) % oneByOne.length;
    _addressFrom = null;
    notifyListeners();
  }

  /// Membros para "Buscar outro membro" (sem a própria pessoa).
  Future<List<SpouseOption>> searchMembers(String text, {required int excludeId}) async {
    if (text.trim().length < 2) return const [];
    return switch (await _repository.search(text: text, size: 8)) {
      Ok(:final value) => [
        for (final member in value.items)
          if (member.id != excludeId) SpouseOption(id: member.id, name: member.name, church: member.churchName),
      ],
      Error() => const [],
    };
  }

  // ---- ações

  Future<Result<void>> _load() async {
    final result = await _repository.spouseReview();
    switch (result) {
      case Ok<SpouseReview>(:final value):
        _review = value;
        _unchecked.removeWhere((id) => !batch.any((suggestion) => suggestion.person.id == id));
        if (_index >= oneByOne.length) _index = 0;
        _addressFrom = null;
        notifyListeners();
        return Result.done;
      case Error<SpouseReview>(:final error):
        _log.error('Falha ao carregar a revisão de cônjuges', error: error, stackTrace: error.stackTrace);
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<int>> _linkBatch() async {
    final links = [
      for (final suggestion in batch)
        if (isChecked(suggestion)) (personId: suggestion.person.id, spouseId: suggestion.candidate.id, addressFrom: null),
    ];
    if (links.isEmpty) return const Result.ok(0);
    final result = await _repository.linkSpouses(links);
    if (result case Error<void>(:final error)) {
      _log.error('Falha ao vincular os casais em lote', error: error, stackTrace: error.stackTrace);
      return Result.error(error);
    }
    _changed = true;
    await _load();
    return Result.ok(links.length);
  }

  Future<Result<void>> _linkCurrent() async {
    final suggestion = current;
    if (suggestion == null) return Result.done;
    return _afterChange(await _repository.linkSpouses([(personId: suggestion.person.id, spouseId: suggestion.candidate.id, addressFrom: _addressFrom)]));
  }

  Future<Result<void>> _dismissCurrent() async {
    final suggestion = current;
    if (suggestion == null) return Result.done;
    return _afterChange(await _repository.dismissSpouse(suggestion.person.id, candidateId: suggestion.candidate.id));
  }

  Future<Result<void>> _linkWith(({int personId, int spouseId}) args) async => _afterChange(await _repository.linkSpouses([(personId: args.personId, spouseId: args.spouseId, addressFrom: null)]));

  Future<Result<void>> _notMember(int personId) async => _afterChange(await _repository.dismissSpouse(personId));

  Future<Result<void>> _afterChange(Result<void> result) async {
    if (result case Error<void>(:final error)) {
      _log.error('Falha na revisão de cônjuges', error: error, stackTrace: error.stackTrace);
      return result;
    }
    _changed = true;
    return _load();
  }

  @override
  void dispose() {
    load.dispose();
    linkBatch.dispose();
    linkCurrent.dispose();
    dismissCurrent.dispose();
    linkWith.dispose();
    notMember.dispose();
    super.dispose();
  }
}

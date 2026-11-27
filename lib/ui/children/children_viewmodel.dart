import 'dart:async';

import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/child/child_repository.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository.dart';
import 'package:echurch_desktop/domain/models/child/child.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';
import 'package:flutter/foundation.dart';

/// Filtro de ministério da lista: todos, sem ministério ou um deles.
sealed class const MinistryFilter() {}

final class const AnyMinistry() extends MinistryFilter;

final class const NoMinistry() extends MinistryFilter;

final class const InMinistry(final int id) extends MinistryFilter {
  @override
  bool operator ==(Object other) => other is InMinistry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Crianças e Adolescentes da igreja escolhida no seletor (Secretaria e Administrador): lista com abas,
/// filtro de ministério e busca (nome da criança ou do responsável); cadastrar, editar, desativar e reativar.
/// Os ministérios com faixa de idade da igreja vêm para o filtro e para o formulário.
class ChildrenViewModel({
  required final ChildRepository _repository,
  required final MinistryRepository _ministries,
  required final ChurchContextNotifier _churchContext,
}) extends ChangeNotifier implements ViewModelInitializable {
  static const pageSize = 20;
  static const _searchDebounce = Duration(milliseconds: 350);

  final _log = AppLogger('ChildrenViewModel');

  late final load = Command0<void>(_load);
  late final save = Command1<ChildDetails, ChildDraft>(_save);
  late final setActive = Command1<ChildDetails, ({ChildRow child, bool active})>(_setActive);
  late final details = Command1<ChildDetails, int>(_details);

  var _page = const ChildPage(items: [], total: 0, page: 0, size: pageSize);
  var _tab = ChildTab.active;
  MinistryFilter _ministryFilter = const AnyMinistry();
  var _text = '';
  var _pageIndex = 0;
  int? _loadedChurchId;
  Timer? _searchTimer;
  var _childMinistries = const <Ministry>[];

  @override
  void init() {
    _churchContext.addListener(_onChurchChanged);
    _onChurchChanged();
  }

  List<ChildRow> get rows => _page.items;
  ChildTab get tab => _tab;
  MinistryFilter get ministryFilter => _ministryFilter;
  String get text => _text;
  String? get churchName => _churchContext.selected?.name;
  int? get churchId => _churchContext.selected?.id;
  List<ChurchSummary> get churches => _churchContext.churches;

  /// Ministérios ativos da igreja com faixa de idade (Soldadinhos de Cristo, Projeto Aviva...).
  List<Ministry> get childMinistries => _childMinistries;

  bool get isFiltered => _text.trim().isNotEmpty || _ministryFilter is! AnyMinistry;
  bool get hasPrevious => _page.page > 0;
  bool get hasNext => _page.page + 1 < _page.pageCount;

  String get rangeLabel {
    if (_page.total == 0) return '0 de 0';
    final first = _page.page * _page.size + 1;
    final last = first + _page.items.length - 1;
    return '$first–$last de ${_page.total}';
  }

  /// Os ministérios em que a criança pode entrar pela idade de hoje (vazio de 0 a 2 anos).
  List<Ministry> ministriesFor(DateTime birthDate, {DateTime? today}) {
    final age = ageAt(birthDate, today ?? DateTime.now());
    return [
      for (final ministry in _childMinistries)
        if (ministry.minAge! <= age && age <= ministry.maxAge!) ministry,
    ];
  }

  /// Membros para responsável (pelo menos duas letras).
  Future<List<GuardianOption>> searchGuardians(String text) async {
    if (text.trim().length < 2) return const [];
    switch (await _repository.guardianOptions(text)) {
      case Ok(:final value):
        return value;
      case Error(:final error):
        _log.error('Falha ao buscar responsáveis', error: error, stackTrace: error.stackTrace);
        return const [];
    }
  }

  void setTab(ChildTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    _restart();
  }

  void setMinistryFilter(MinistryFilter filter) {
    if (filter == _ministryFilter) return;
    _ministryFilter = filter;
    _restart();
  }

  /// Busca no nome da criança ou do responsável; espera a digitação parar.
  void setText(String value) {
    if (value == _text) return;
    _text = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _restart);
  }

  void nextPage() {
    if (!hasNext) return;
    _pageIndex = _page.page + 1;
    load.execute();
  }

  void previousPage() {
    if (!hasPrevious) return;
    _pageIndex = _page.page - 1;
    load.execute();
  }

  void _onChurchChanged() {
    final id = churchId;
    if (id == null || id == _loadedChurchId) return;
    _loadedChurchId = id;
    _ministryFilter = const AnyMinistry();
    unawaited(_loadMinistries(id));
    _restart();
  }

  void _restart() {
    _pageIndex = 0;
    load.execute();
  }

  Future<void> _loadMinistries(int churchId) async {
    switch (await _ministries.list(churchId: churchId)) {
      case Ok<List<Ministry>>(:final value):
        _childMinistries = [
          for (final ministry in value)
            if (ministry.active && ministry.minAge != null && ministry.maxAge != null) ministry,
        ]..sort((a, b) => a.minAge!.compareTo(b.minAge!));
        notifyListeners();
      case Error<List<Ministry>>(:final error):
        // Sem os ministérios a lista funciona; só o filtro e o campo do formulário ficam vazios.
        _log.error('Falha ao carregar os ministérios', error: error, stackTrace: error.stackTrace);
    }
  }

  Future<Result<void>> _load() async {
    final id = _loadedChurchId;
    if (id == null) return Result.done;
    final ministryId = switch (_ministryFilter) {
      AnyMinistry() => null,
      NoMinistry() => 0,
      InMinistry(:final id) => id,
    };
    try {
      switch (await _repository.search(churchId: id, ministryId: ministryId, text: _text, tab: _tab, page: _pageIndex, size: pageSize)) {
        case Ok<ChildPage>(:final value):
          _page = value;
          return Result.done;
        case Error<ChildPage>(:final error):
          _log.error('Falha ao carregar as crianças', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<ChildDetails>> _details(int id) async {
    final result = await _repository.find(id);
    if (result case Error<ChildDetails>(:final error)) {
      _log.error('Falha ao carregar a criança $id', error: error, stackTrace: error.stackTrace);
    }
    return result;
  }

  Future<Result<ChildDetails>> _save(ChildDraft draft) async {
    final result = await _repository.save(draft);
    _afterChange(result, draft.id == null ? 'cadastrar' : 'alterar');
    return result;
  }

  Future<Result<ChildDetails>> _setActive(({ChildRow child, bool active}) args) async {
    final result = await _repository.setActive(args.child.id, args.active);
    _afterChange(result, args.active ? 'reativar' : 'desativar');
    return result;
  }

  void _afterChange(Result<ChildDetails> result, String what) {
    switch (result) {
      case Ok<ChildDetails>(:final value):
        _log.info('Criança ${value.id}: $what');
        unawaited(load.execute());
      case Error<ChildDetails>(:final error):
        _log.error('Falha ao $what a criança', error: error, stackTrace: error.stackTrace);
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _churchContext.removeListener(_onChurchChanged);
    load.dispose();
    save.dispose();
    setActive.dispose();
    details.dispose();
    super.dispose();
  }
}

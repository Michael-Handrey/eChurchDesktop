import 'dart:async';

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/prayer_request/prayer_request_repository.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:flutter/foundation.dart';

/// Aba da tela: uma situação, todas, ou os excluídos (só o administrador).
enum PrayerRequestTab { newRequests, inVase, rejected, all, excluded }

/// Linha da tabela, pronta para a tela.
typedef PrayerRequestRowView = ({PrayerRequest request, String dateLabel, bool selectable, bool selected});

/// Pedido para registrar ([id] nulo) ou alterar.
typedef PrayerRequestSave = ({int? id, PrayerRequestDraft draft});

/// Rejeitar com motivo opcional.
typedef PrayerRequestRejectArgs = ({PrayerRequest request, String? reason});

/// Ação de um clique (sem formulário) sobre um pedido.
typedef PrayerRequestQuickAction = ({PrayerRequest request, PrayerRequestAction action});

/// Pedidos de oração da igreja em uso (seletor da barra superior); na Sede, também os sem igreja.
/// Quais ações cada pedido permite vêm da API (`PrayerRequest.actions`).
class PrayerRequestsViewModel({
  required final PrayerRequestRepository _repository,
  required final ChurchContextNotifier _churchContext,
  required final AuthSessionNotifier _session,
}) extends ChangeNotifier implements ViewModelInitializable {
  static const pageSize = 20;
  static const _searchDebounce = Duration(milliseconds: 350);

  final _log = AppLogger('PrayerRequestsViewModel');

  late final load = Command0<void>(_load);
  late final save = Command1<PrayerRequest, PrayerRequestSave>(_save);
  late final markInVase = Command0<int>(_markInVase);
  late final markAllInVase = Command0<int>(_markAllInVase);
  late final reject = Command1<PrayerRequest, PrayerRequestRejectArgs>(_reject);
  late final quickAction = Command1<PrayerRequest, PrayerRequestQuickAction>(_quickAction);

  PrayerRequestPage _page = const PrayerRequestPage(items: [], total: 0, page: 0, size: pageSize);
  var _tab = PrayerRequestTab.newRequests;
  var _text = '';
  var _pageIndex = 0;
  final _selected = <int>{};
  int? _loadedChurchId;
  Timer? _searchTimer;

  @override
  void init() {
    _churchContext.addListener(_onChurchChanged);
    _onChurchChanged();
  }

  /// Secretaria/Administrador: veem todos os pedidos e têm ações (as de cada pedido vêm da API).
  bool get canManage => _session.user?.canManage ?? false;
  bool get isAdmin => _session.user?.isAdmin ?? false;

  String? get churchName => _churchContext.selected?.name;
  bool get isHeadquarters => _churchContext.selected?.headquarters ?? false;
  int? get _churchId => _churchContext.selected?.id;

  PrayerRequestTab get tab => _tab;
  List<PrayerRequestTab> get tabs => [PrayerRequestTab.newRequests, PrayerRequestTab.inVase, PrayerRequestTab.rejected, PrayerRequestTab.all, if (isAdmin) PrayerRequestTab.excluded];
  String get text => _text;
  PrayerRequestPage get page => _page;
  Set<int> get selectedIds => Set.unmodifiable(_selected);

  bool get hasPrevious => _page.page > 0;
  bool get hasNext => _page.page + 1 < _page.pageCount;

  /// "Marcar todos no vaso": na aba de novos, com pedidos e sem busca (todos = todos os novos da igreja).
  bool get canMarkAll => canManage && _tab == PrayerRequestTab.newRequests && _text.trim().isEmpty && _page.total > 0;

  /// Quantos novos "marcar todos" vai mexer (o total da aba de novos).
  int get newCount => _tab == PrayerRequestTab.newRequests ? _page.total : 0;

  /// "1–20 de 57"
  String get rangeLabel {
    if (_page.total == 0) return 'Nenhum pedido';
    final first = _page.page * _page.size + 1;
    final last = first + _page.items.length - 1;
    return '$first–$last de ${_page.total}';
  }

  List<PrayerRequestRowView> get rows => [
    for (final request in _page.items)
      (
        request: request,
        dateLabel: formatDate(request.requestDate),
        selectable: request.can(PrayerRequestAction.inVase),
        selected: _selected.contains(request.id),
      ),
  ];

  /// Seleção da página: todos os selecionáveis desta página estão marcados? (nulo = alguns)
  bool? get pageSelection {
    final selectable = [
      for (final row in rows)
        if (row.selectable) row.request.id,
    ];
    if (selectable.isEmpty) return false;
    final marked = selectable.where(_selected.contains).length;
    return marked == 0 ? false : (marked == selectable.length ? true : null);
  }

  bool get hasSelectable => rows.any((row) => row.selectable);

  static String tabLabel(PrayerRequestTab tab) => switch (tab) {
    PrayerRequestTab.newRequests => 'Novos',
    PrayerRequestTab.inVase => 'No vaso',
    PrayerRequestTab.rejected => 'Rejeitados',
    PrayerRequestTab.all => 'Todos',
    PrayerRequestTab.excluded => 'Excluídos',
  };

  static String statusLabel(PrayerRequestStatus status) => switch (status) {
    PrayerRequestStatus.newRequest => 'Novo',
    PrayerRequestStatus.inVase => 'No vaso',
    PrayerRequestStatus.rejected => 'Rejeitado',
  };

  static String formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void setTab(PrayerRequestTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    _restart();
  }

  /// Busca em nome e pedido; espera a digitação parar para consultar a API.
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

  void toggleSelection(PrayerRequest request, bool selected) {
    if (!request.can(PrayerRequestAction.inVase)) return;
    selected ? _selected.add(request.id) : _selected.remove(request.id);
    notifyListeners();
  }

  /// Marca/desmarca todos os selecionáveis da página.
  void togglePageSelection(bool selected) {
    for (final row in rows) {
      if (!row.selectable) continue;
      selected ? _selected.add(row.request.id) : _selected.remove(row.request.id);
    }
    notifyListeners();
  }

  void _onChurchChanged() {
    final churchId = _churchId;
    if (churchId == null || churchId == _loadedChurchId) return;
    _loadedChurchId = churchId;
    _restart();
  }

  void _restart() {
    _pageIndex = 0;
    _selected.clear();
    load.execute();
  }

  Future<Result<void>> _load() async {
    final churchId = _churchId;
    if (churchId == null) return Result.done;

    final status = switch (_tab) {
      PrayerRequestTab.newRequests => PrayerRequestStatus.newRequest,
      PrayerRequestTab.inVase => PrayerRequestStatus.inVase,
      PrayerRequestTab.rejected => PrayerRequestStatus.rejected,
      PrayerRequestTab.all || PrayerRequestTab.excluded => null,
    };
    try {
      final result = await _repository.search(churchId: churchId, status: status, text: _text, excluded: _tab == PrayerRequestTab.excluded, page: _pageIndex, size: pageSize);
      switch (result) {
        case Ok<PrayerRequestPage>(:final value):
          _page = value;
          _selected.removeWhere((id) => !value.items.any((item) => item.id == id && item.can(PrayerRequestAction.inVase)));
          return Result.done;
        case Error<PrayerRequestPage>(:final error):
          _log.error('Falha ao carregar os pedidos de oração', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<PrayerRequest>> _save(PrayerRequestSave args) async {
    final draft = (requesterName: args.draft.requesterName, description: args.draft.description, requestDate: args.draft.requestDate, churchId: args.draft.churchId ?? _churchId);
    final result = args.id == null ? await _repository.create(draft) : await _repository.update(args.id!, draft);
    _afterChange(result, args.id == null ? 'registrar' : 'alterar');
    return result;
  }

  Future<Result<int>> _markInVase() async {
    if (_selected.isEmpty) return const Result.ok(0);
    final result = await _repository.markInVase({..._selected});
    return _afterVase(result);
  }

  Future<Result<int>> _markAllInVase() async {
    final churchId = _churchId;
    if (churchId == null) return const Result.ok(0);
    return _afterVase(await _repository.markAllNewInVase(churchId));
  }

  Future<Result<int>> _afterVase(Result<List<PrayerRequest>> result) async {
    switch (result) {
      case Ok<List<PrayerRequest>>(:final value):
        _log.info('${value.length} pedidos no vaso');
        _selected.clear();
        unawaited(load.execute());
        return Result.ok(value.length);
      case Error<List<PrayerRequest>>(:final error):
        _log.error('Falha ao marcar pedidos no vaso', error: error, stackTrace: error.stackTrace);
        return Result.error(error);
    }
  }

  Future<Result<PrayerRequest>> _reject(PrayerRequestRejectArgs args) async {
    final result = await _repository.reject(args.request.id, reason: args.reason);
    _afterChange(result, 'rejeitar');
    return result;
  }

  Future<Result<PrayerRequest>> _quickAction(PrayerRequestQuickAction args) async {
    final id = args.request.id;
    final result = switch (args.action) {
      PrayerRequestAction.backToNew => await _repository.backToNew(id),
      PrayerRequestAction.exclude => await _repository.exclude(id),
      PrayerRequestAction.restore => await _repository.restore(id),
      PrayerRequestAction.edit || PrayerRequestAction.inVase || PrayerRequestAction.reject => throw ArgumentError('Ação com formulário: ${args.action}'),
    };
    _afterChange(result, args.action.apiValue);
    return result;
  }

  void _afterChange(Result<PrayerRequest> result, String what) {
    switch (result) {
      case Ok<PrayerRequest>(:final value):
        _log.info('Pedido de oração ${value.id}: $what');
        unawaited(load.execute());
      case Error<PrayerRequest>(:final error):
        _log.error('Falha ao $what o pedido de oração', error: error, stackTrace: error.stackTrace);
    }
  }

  @override
  void dispose() {
    _churchContext.removeListener(_onChurchChanged);
    _searchTimer?.cancel();
    load.dispose();
    save.dispose();
    markInVase.dispose();
    markAllInVase.dispose();
    reject.dispose();
    quickAction.dispose();
    super.dispose();
  }
}

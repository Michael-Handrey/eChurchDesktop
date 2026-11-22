import 'dart:async';

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:flutter/foundation.dart';

/// Aba da tela: ativos, inativos ou todos.
enum MemberTab { active, inactive, all }

/// Desativar: motivo e descrição são obrigatórios.
typedef MemberDeactivateArgs = ({MemberRow member, DeactivationReason reason, String description});

/// Membros da igreja em uso (seletor da barra superior): busca por nome, filtro por cargo,
/// detalhes e — para Secretaria/Administrador — desativar (com motivo) e reativar.
/// Membros não são excluídos. O cadastro e a edição vêm na etapa 2 (ROADMAP).
class MembersViewModel({
  required final MemberRepository _repository,
  required final ChurchContextNotifier _churchContext,
  required final AuthSessionNotifier _session,
}) extends ChangeNotifier implements ViewModelInitializable {
  static const pageSize = 20;
  static const maxDescription = 500;
  static const _searchDebounce = Duration(milliseconds: 350);

  final _log = AppLogger('MembersViewModel');

  late final load = Command0<void>(_load);
  late final details = Command1<MemberDetails, int>(_details);
  late final deactivate = Command1<MemberDetails, MemberDeactivateArgs>(_deactivate);
  late final reactivate = Command1<MemberDetails, MemberRow>(_reactivate);

  MemberPage _page = const MemberPage(items: [], total: 0, page: 0, size: pageSize);
  var _roles = const <EcclesiasticalRoleOption>[];
  var _tab = MemberTab.active;
  var _text = '';
  int? _roleId;

  /// "Todas as igrejas" ligado: lista de todas as que o usuário alcança (senão, a do seletor).
  var _allChurches = false;
  var _pageIndex = 0;
  int? _loadedChurchId;
  Timer? _searchTimer;

  /// Formulário aberto: ({id: nulo}) cadastra; ({id: 10}) edita. Nulo: mostra a lista.
  ({int? id})? _form;

  @override
  void init() {
    _churchContext.addListener(_onChurchChanged);
    _onChurchChanged();
    unawaited(_loadRoles());
    unawaited(loadDuplicateCount());
  }

  /// Quantos casos de cadastro duplicado existem (Secretaria/Administrador; mostra o botão).
  int get duplicateCount => _duplicateCount;
  var _duplicateCount = 0;

  /// Tela de cadastros duplicados aberta no lugar da lista.
  bool get showingDuplicates => _showingDuplicates;
  var _showingDuplicates = false;

  Future<void> loadDuplicateCount() async {
    if (!canManage) return;
    switch (await _repository.duplicates()) {
      case Ok(:final value):
        _duplicateCount = value.length;
        notifyListeners();
      case Error(:final error):
        // Sem a contagem a lista funciona; só o botão não aparece.
        _log.warning('Falha ao contar os cadastros duplicados', error: error, stackTrace: error.stackTrace);
    }
  }

  void openDuplicates() {
    if (!canManage) return;
    _showingDuplicates = true;
    notifyListeners();
  }

  /// Volta para a lista; juntou ou separou algo ([changed]): recarrega a lista e a contagem.
  void closeDuplicates({bool changed = false}) {
    _showingDuplicates = false;
    notifyListeners();
    unawaited(loadDuplicateCount());
    if (changed) load.execute();
  }

  /// Secretaria/Administrador: desativam e reativam (a API confere de novo).
  bool get canManage => _session.user?.canManage ?? false;

  /// Nome da igreja da lista; nulo em "Todas as igrejas".
  String? get churchName => _allChurches ? null : _churchContext.selected?.name;
  bool get allChurches => _allChurches;

  /// Só quem alcança mais de uma igreja tem o "Todas as igrejas" (e a coluna Igreja com ele ligado).
  bool get canSeeAllChurches => _churchContext.churches.length > 1;
  bool get showChurchColumn => canSeeAllChurches && _allChurches;

  ({int? id})? get form => _form;

  /// Abre o cadastro de um membro novo (Secretaria/Administrador).
  void openNew() {
    if (!canManage) return;
    _form = (id: null);
    notifyListeners();
  }

  /// Abre a edição do membro (Secretaria/Administrador).
  void openEdit(int id) {
    if (!canManage) return;
    _form = (id: id);
    notifyListeners();
  }

  /// Volta para a lista; salvou ([savedId]): recarrega.
  void closeForm({int? savedId}) {
    _form = null;
    notifyListeners();
    if (savedId != null) load.execute();
  }

  MemberTab get tab => _tab;
  String get text => _text;
  int? get roleId => _roleId;
  List<EcclesiasticalRoleOption> get roles => _roles;
  MemberPage get page => _page;
  List<MemberRow> get rows => _page.items;

  bool get hasPrevious => _page.page > 0;
  bool get hasNext => _page.page + 1 < _page.pageCount;

  /// Algum filtro além da aba (para a mensagem de lista vazia).
  bool get isFiltered => _text.trim().isNotEmpty || _roleId != null;

  /// "1–20 de 314"
  String get rangeLabel {
    if (_page.total == 0) return 'Nenhum membro';
    final first = _page.page * _page.size + 1;
    final last = first + _page.items.length - 1;
    return '$first–$last de ${_page.total}';
  }

  static String tabLabel(MemberTab tab) => switch (tab) {
    MemberTab.active => 'Ativos',
    MemberTab.inactive => 'Inativos',
    MemberTab.all => 'Todos',
  };

  static String statusLabel(MemberStatus status) => switch (status) {
    MemberStatus.active => 'Ativo',
    MemberStatus.inactive => 'Inativo',
    MemberStatus.other => 'Outra',
  };

  /// "15/03"; nulo sem data.
  static String? birthdayLabel(int? day, int? month) => day == null || month == null ? null : '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';

  static String formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void setTab(MemberTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    _restart();
  }

  /// Busca no nome; espera a digitação parar para consultar a API.
  void setText(String value) {
    if (value == _text) return;
    _text = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _restart);
  }

  void setAllChurches(bool value) {
    if (value == _allChurches || (value && !canSeeAllChurches)) return;
    _allChurches = value;
    _restart();
  }

  void setRole(int? roleId) {
    if (roleId == _roleId) return;
    _roleId = roleId;
    _restart();
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

  /// Trocar a igreja no seletor da barra superior mostra a lista dela (desliga o "Todas").
  void _onChurchChanged() {
    final churchId = _churchContext.selected?.id;
    if (churchId == null || churchId == _loadedChurchId) return;
    _loadedChurchId = churchId;
    _allChurches = false;
    _restart();
  }

  void _restart() {
    _pageIndex = 0;
    load.execute();
  }

  Future<void> _loadRoles() async {
    switch (await _repository.roles()) {
      case Ok<List<EcclesiasticalRoleOption>>(:final value):
        _roles = value;
        notifyListeners();
      case Error<List<EcclesiasticalRoleOption>>(:final error):
        // Sem os cargos a lista funciona; só o filtro fica vazio.
        _log.error('Falha ao carregar os cargos', error: error, stackTrace: error.stackTrace);
    }
  }

  Future<Result<void>> _load() async {
    // Antes da lista de igrejas chegar, não busca (sem igreja a API traria todas do alcance).
    if (_loadedChurchId == null) return Result.done;

    final status = switch (_tab) {
      MemberTab.active => MemberStatus.active,
      MemberTab.inactive => MemberStatus.inactive,
      MemberTab.all => null,
    };
    try {
      final result = await _repository.search(churchId: _allChurches ? null : _loadedChurchId, status: status, text: _text, ecclesiasticalRoleId: _roleId, page: _pageIndex, size: pageSize);
      switch (result) {
        case Ok<MemberPage>(:final value):
          _page = value;
          return Result.done;
        case Error<MemberPage>(:final error):
          _log.error('Falha ao carregar os membros', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<MemberDetails>> _details(int id) async {
    final result = await _repository.details(id);
    if (result case Error<MemberDetails>(:final error)) {
      _log.error('Falha ao carregar o membro $id', error: error, stackTrace: error.stackTrace);
    }
    return result;
  }

  Future<Result<MemberDetails>> _deactivate(MemberDeactivateArgs args) async {
    final result = await _repository.deactivate(args.member.id, reason: args.reason, description: args.description);
    _afterChange(result, 'desativar');
    return result;
  }

  Future<Result<MemberDetails>> _reactivate(MemberRow member) async {
    final result = await _repository.reactivate(member.id);
    _afterChange(result, 'reativar');
    return result;
  }

  void _afterChange(Result<MemberDetails> result, String what) {
    switch (result) {
      case Ok<MemberDetails>(:final value):
        _log.info('Membro ${value.id}: $what');
        unawaited(load.execute());
      case Error<MemberDetails>(:final error):
        _log.error('Falha ao $what o membro', error: error, stackTrace: error.stackTrace);
    }
  }

  @override
  void dispose() {
    _churchContext.removeListener(_onChurchChanged);
    _searchTimer?.cancel();
    load.dispose();
    details.dispose();
    deactivate.dispose();
    reactivate.dispose();
    super.dispose();
  }
}

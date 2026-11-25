import 'dart:async';

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';
import 'package:flutter/foundation.dart';

/// Aba da lista (mesmo padrão de Membros).
enum MinistryTab { active, inactive, all }

/// Salvar: [id] nulo cadastra.
typedef MinistrySave = ({int? id, MinistryDraft draft});

/// Ministérios da igreja escolhida no seletor: listar, cadastrar, editar, desativar/reativar e os
/// membros de cada um. Secretaria/Administrador alteram; quem só consulta vê. O Líder de ministério só vê os que
/// lidera e inclui ou tira membros deles ([Ministry.canEditMembers], decidido pela API).
class MinistriesViewModel({
  required final MinistryRepository _repository,
  required final MemberRepository _members,
  required final ChurchContextNotifier _churchContext,
  required final AuthSessionNotifier _session,
}) extends ChangeNotifier implements ViewModelInitializable {
  final _log = AppLogger('MinistriesViewModel');

  late final load = Command0<void>(_load);
  late final save = Command1<Ministry, MinistrySave>(_save);
  late final setActive = Command1<Ministry, ({Ministry ministry, bool active})>(_setActive);
  late final loadMembers = Command1<List<MemberRow>, int>(_loadMembers);
  late final addMember = Command1<List<MemberRow>, ({int ministryId, int personId})>(_addMember);
  late final removeMember = Command1<List<MemberRow>, ({int ministryId, int personId})>(_removeMember);

  var _ministries = const <Ministry>[];
  var _tab = MinistryTab.active;
  int? _loadedChurchId;

  /// Membros do ministério aberto no diálogo.
  var _memberRows = const <MemberRow>[];

  @override
  void init() {
    _churchContext.addListener(_onChurchChanged);
    _onChurchChanged();
  }

  bool get canManage => _session.user?.canManage ?? false;

  /// Líder de ministério sem Secretaria nem Usuário: a API traz só os ministérios que ele lidera.
  bool get onlyLeads => !(_session.user?.canSeeMembers ?? false) && (_session.user?.isMinistryLeader ?? false);
  String? get churchName => _churchContext.selected?.name;
  int? get churchId => _churchContext.selected?.id;
  List<ChurchSummary> get churches => _churchContext.churches;

  /// Os da aba escolhida (a API traz ativos, ou todos; os inativos saem de "todos").
  List<Ministry> get ministries => switch (_tab) {
    MinistryTab.active || MinistryTab.all => _ministries,
    MinistryTab.inactive => [
      for (final ministry in _ministries)
        if (!ministry.active) ministry,
    ],
  };
  MinistryTab get tab => _tab;

  static String tabLabel(MinistryTab tab) => switch (tab) {
    MinistryTab.active => 'Ativos',
    MinistryTab.inactive => 'Inativos',
    MinistryTab.all => 'Todos',
  };
  List<MemberRow> get members => _memberRows;

  void setTab(MinistryTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    load.execute();
  }

  /// Membros para escolher líder, vice ou incluir no ministério (todas as igrejas do alcance).
  Future<List<SpouseOption>> searchMembers(String text) async {
    if (text.trim().length < 2) return const [];
    return switch (await _members.search(text: text, status: MemberStatus.active, size: 8)) {
      Ok(:final value) => [for (final member in value.items) SpouseOption(id: member.id, name: member.name, church: member.churchName)],
      Error() => const [],
    };
  }

  /// Membros para incluir no ministério: nome, cargo e igreja (a API traz só os que ainda não estão nele).
  Future<List<MinistryCandidate>> searchCandidates(int ministryId, String text) async {
    if (text.trim().length < 2) return const [];
    switch (await _repository.candidates(ministryId, text)) {
      case Ok(:final value):
        return value;
      case Error(:final error):
        _log.error('Falha ao buscar membros para o ministério', error: error, stackTrace: error.stackTrace);
        return const [];
    }
  }

  void _onChurchChanged() {
    final id = churchId;
    if (id == null || id == _loadedChurchId) return;
    _loadedChurchId = id;
    load.execute();
  }

  Future<Result<void>> _load() async {
    final id = churchId;
    if (id == null) return Result.done;
    try {
      switch (await _repository.list(churchId: id, includeInactive: _tab != MinistryTab.active)) {
        case Ok<List<Ministry>>(:final value):
          _ministries = value;
          return Result.done;
        case Error<List<Ministry>>(:final error):
          _log.error('Falha ao carregar os ministérios', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<Ministry>> _save(MinistrySave args) async {
    final result = await _repository.save(args.id, args.draft);
    _afterChange(result, args.id == null ? 'cadastrar' : 'alterar');
    return result;
  }

  Future<Result<Ministry>> _setActive(({Ministry ministry, bool active}) args) async {
    final result = await _repository.setActive(args.ministry.id, args.active);
    _afterChange(result, args.active ? 'reativar' : 'desativar');
    return result;
  }

  void _afterChange(Result<Ministry> result, String what) {
    switch (result) {
      case Ok<Ministry>(:final value):
        _log.info('Ministério ${value.id}: $what');
        unawaited(load.execute());
      case Error<Ministry>(:final error):
        _log.error('Falha ao $what o ministério', error: error, stackTrace: error.stackTrace);
    }
  }

  Future<Result<List<MemberRow>>> _loadMembers(int ministryId) async => _setMembers(await _repository.members(ministryId));

  Future<Result<List<MemberRow>>> _addMember(({int ministryId, int personId}) args) async {
    final result = _setMembers(await _repository.addMembers(args.ministryId, [args.personId]));
    if (result is Ok) unawaited(load.execute());
    return result;
  }

  Future<Result<List<MemberRow>>> _removeMember(({int ministryId, int personId}) args) async {
    final result = _setMembers(await _repository.removeMembers(args.ministryId, [args.personId]));
    if (result is Ok) unawaited(load.execute());
    return result;
  }

  Result<List<MemberRow>> _setMembers(Result<List<MemberRow>> result) {
    switch (result) {
      case Ok<List<MemberRow>>(:final value):
        _memberRows = value;
      case Error<List<MemberRow>>(:final error):
        _log.error('Falha nos membros do ministério', error: error, stackTrace: error.stackTrace);
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _churchContext.removeListener(_onChurchChanged);
    load.dispose();
    save.dispose();
    setActive.dispose();
    loadMembers.dispose();
    addMember.dispose();
    removeMember.dispose();
    super.dispose();
  }
}

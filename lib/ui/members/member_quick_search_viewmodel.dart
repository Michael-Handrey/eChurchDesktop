import 'dart:async';

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:flutter/foundation.dart';

/// Busca rápida da barra superior: acha um membro pelo nome, telefone ou (Secretaria/Administrador)
/// CPF, em todas as igrejas que o usuário alcança e em qualquer situação. Mostra até [maxResults];
/// clicar abre a ficha.
class MemberQuickSearchViewModel({required final MemberRepository _repository, required final AuthSessionNotifier _session}) extends ChangeNotifier {
  static const maxResults = 8;
  static const minLength = 2;
  static const _debounce = Duration(milliseconds: 300);

  final _log = AppLogger('MemberQuickSearchViewModel');

  late final details = Command1<MemberDetails, int>(_details);

  var _query = '';
  var _results = const <MemberRow>[];
  var _total = 0;
  var _loading = false;
  Object? _error;
  var _requestId = 0;
  Timer? _timer;

  String get query => _query;
  List<MemberRow> get results => _results;

  /// Quantos membros a busca achou (pode passar de [maxResults]).
  int get total => _total;
  bool get loading => _loading;
  bool get hasError => _error != null;

  /// Já dá para buscar (texto com pelo menos [minLength] letras ou números).
  bool get isActive => _query.trim().length >= minLength;

  /// Secretaria/Administrador: busca também por CPF e vê a ficha completa.
  bool get canManage => _session.user?.canManage ?? false;

  String get hint => canManage ? 'Buscar membro por nome, CPF ou telefone  (Ctrl+K)' : 'Buscar membro por nome ou telefone  (Ctrl+K)';

  /// Espera a digitação parar para consultar a API.
  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _timer?.cancel();
    if (!isActive) {
      _requestId++;
      _results = const [];
      _total = 0;
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _timer = Timer(_debounce, _search);
  }

  void clear() => setQuery('');

  Future<void> _search() async {
    final id = ++_requestId;
    final result = await _repository.search(text: _query.trim(), size: maxResults);
    if (id != _requestId) return; // chegou depois de uma busca mais nova
    switch (result) {
      case Ok<MemberPage>(:final value):
        _results = value.items;
        _total = value.total;
        _error = null;
      case Error<MemberPage>(:final error):
        _log.error('Falha na busca rápida de membros', error: error, stackTrace: error.stackTrace);
        _results = const [];
        _total = 0;
        _error = error;
    }
    _loading = false;
    notifyListeners();
  }

  Future<Result<MemberDetails>> _details(int id) async {
    final result = await _repository.details(id);
    if (result case Error<MemberDetails>(:final error)) {
      _log.error('Falha ao carregar o membro $id', error: error, stackTrace: error.stackTrace);
    }
    return result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    details.dispose();
    super.dispose();
  }
}

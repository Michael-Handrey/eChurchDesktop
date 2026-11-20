import 'dart:async';

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/church/church_repository.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:flutter/foundation.dart';

/// Igreja em uso no sistema (seletor da barra superior). Começa na igreja do usuário logado;
/// as telas que listam dados por igreja (membros, relatórios...) seguem a escolhida aqui.
///
/// Quem pode trocar: quem alcança mais de uma igreja. A API devolve só as igrejas do alcance
/// de cada um ("sede supervisiona"): administrador e secretaria da sede trocam entre sede e
/// filiais; os demais (secretaria de filial, usuário só de consulta) ficam na própria igreja.
class ChurchContextNotifier({
  required final ChurchRepository _churchRepository,
  required final AuthSessionNotifier _sessionNotifier,
}) extends ChangeNotifier {
  final _log = AppLogger('ChurchContextNotifier');

  List<ChurchSummary> _churches = const [];
  int? _selectedId;
  String? _loadedFor;

  this {
    _sessionNotifier.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  List<ChurchSummary> get churches => _churches;

  ChurchSummary? get selected => _churches.where((church) => church.id == _selectedId).firstOrNull;

  bool get canSwitch => _churches.length > 1;

  void select(int churchId) {
    if (!canSwitch || churchId == _selectedId || !_churches.any((church) => church.id == churchId)) return;
    _selectedId = churchId;
    _log.info('Igreja em uso: ${selected?.name}');
    notifyListeners();
  }

  void _onSessionChanged() {
    final user = _sessionNotifier.user;

    // Sem sessão (ou na troca de senha provisória, quando a API ainda recusa o resto): limpa.
    if (user == null || user.firstAccess) {
      if (_loadedFor == null && _churches.isEmpty) return;
      _loadedFor = null;
      _churches = const [];
      _selectedId = null;
      notifyListeners();
      return;
    }

    if (_loadedFor == user.login) return;
    _loadedFor = user.login;
    unawaited(_load(user.churchId));
  }

  Future<void> _load(int? userChurchId) async {
    switch (await _churchRepository.list()) {
      case Ok<List<ChurchSummary>>(:final value):
        _churches = value;
        _selectedId = value.any((church) => church.id == userChurchId) ? userChurchId : value.firstOrNull?.id;
      case Error<List<ChurchSummary>>(:final error):
        // Sem a lista, o seletor fica vazio; tenta de novo no próximo login.
        _loadedFor = null;
        _log.warning('Não foi possível carregar as igrejas', error: error, stackTrace: error.stackTrace);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionNotifier.removeListener(_onSessionChanged);
    super.dispose();
  }
}

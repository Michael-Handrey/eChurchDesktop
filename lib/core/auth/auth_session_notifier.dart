import 'dart:async';

import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:flutter/foundation.dart';

class AuthSessionNotifier({
  required final AuthLogoutUseCase _authLogoutUseCase,
  required final AuthRestoreSessionUseCase _authRestoreSessionUseCase,
  required final Stream<void> sessionEnded,
}) extends ChangeNotifier {
  final _log = AppLogger('AuthSessionNotifier');
  late final StreamSubscription<void> _sessionEnded;

  AuthSessionUser? _user;
  var _restored = false;
  var _loggingOut = false;

  bool get isRestored => _restored;
  AuthSessionUser? get user => _user;
  bool get isSignedIn => _user != null;

  this {
    unawaited(_restore());

    _sessionEnded = sessionEnded.listen((_) {
      // O próprio logout pode receber 401; não reentrar.
      if (_loggingOut || !isSignedIn) return;
      _log.info('Backend encerrou a sessão');
      unawaited(logout());
    });
  }

  Future<void> _restore() async {
    final restored = await _authRestoreSessionUseCase.restore();

    if (_restored) return;

    switch (restored) {
      case Ok(:final value):
        _user = value;
        _log.info(value == null ? 'Sem sessão guardada' : 'Sessão restaurada');
      case Error(:final error):
        _log.error('Falha ao ler a sessão guardada', error: error);
    }

    _restored = true;
    notifyListeners();
  }

  String get initials {
    final name = _user?.name.trim() ?? '';
    if (name.isEmpty) return '';

    final words = name.split(RegExp(r'\s+'));
    final first = words.first[0];
    return (words.length == 1 ? first : first + words.last[0]).toUpperCase();
  }

  void signedIn(AuthSessionUser user) {
    _user = user;
    _restored = true;
    _log.info('Sessão iniciada');
    notifyListeners();
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;

    try {
      final logout = await _authLogoutUseCase.logout();
      if (logout case Error(:final error)) {
        _log.error('Falha ao apagar a sessão no logout', error: error);
      }
    } finally {
      _loggingOut = false;
    }

    final changed = _user != null || !_restored;

    _user = null;
    _restored = true;

    if (!changed) return;

    _log.info('Sessão encerrada');
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionEnded.cancel();
    super.dispose();
  }
}

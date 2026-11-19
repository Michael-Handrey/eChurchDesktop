import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/ui/core/window/app_window.dart';
import 'package:flutter/widgets.dart';

/// Ajusta a janela quando a sessão muda: maximiza ao entrar no sistema e volta
/// ao tamanho do login (centralizada) no logout. A troca de senha do primeiro
/// acesso continua no tamanho do login.
class const SessionWindowSizer({
  super.key,
  required final AuthSessionNotifier session,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<SessionWindowSizer> createState() => _SessionWindowSizerState();
}

class _SessionWindowSizerState extends State<SessionWindowSizer> {
  /// A janela começa no tamanho do login (`AppWindow.initialize`).
  var _maximized = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_apply);
    _apply();
  }

  void _apply() {
    final session = widget.session;
    final inSystem = session.isSignedIn && !session.mustChangePassword;
    if (inSystem == _maximized) return;

    _maximized = inSystem;
    inSystem ? AppWindow.showMain() : AppWindow.showLogin();
  }

  @override
  void dispose() {
    widget.session.removeListener(_apply);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

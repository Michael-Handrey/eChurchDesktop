import 'package:echurch_desktop/routing/routes.dart';
import 'package:echurch_desktop/ui/core/window/app_window.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Ajusta a janela conforme a tela aberta: splash, login e troca de senha em
/// janela fixa e centralizada ([Routes.compactWindow]); as demais telas ocupam
/// a área útil do monitor. Seguir a rota (e não a sessão) faz a janela crescer
/// só quando o painel aparece, depois da splash.
class const RouteWindowSizer({
  super.key,
  required final GoRouter router,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<RouteWindowSizer> createState() => _RouteWindowSizerState();
}

class _RouteWindowSizerState extends State<RouteWindowSizer> {
  /// A janela começa no tamanho do login (`AppWindow.initialize`).
  var _fullScreen = false;

  GoRouterDelegate get _delegate => widget.router.routerDelegate;

  @override
  void initState() {
    super.initState();
    _delegate.addListener(_apply);
    _apply();
  }

  void _apply() {
    final path = _delegate.currentConfiguration.uri.path;
    if (path.isEmpty) return;

    final fullScreen = !Routes.compactWindow.contains(path);
    if (fullScreen == _fullScreen) return;

    _fullScreen = fullScreen;
    fullScreen ? AppWindow.showMain() : AppWindow.showLogin();
  }

  @override
  void dispose() {
    _delegate.removeListener(_apply);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

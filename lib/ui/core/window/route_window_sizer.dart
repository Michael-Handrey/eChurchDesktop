import 'dart:async';

import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/routing/routes.dart';
import 'package:echurch_desktop/ui/core/window/app_window.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nativeapi/nativeapi.dart' show DisplayManager;

/// Ajusta a janela conforme a tela aberta: splash, login e troca de senha em
/// janela fixa e centralizada ([Routes.compactWindow]); as demais telas ocupam
/// a área útil do monitor. Seguir a rota (e não a sessão) faz a janela crescer
/// só quando o painel aparece, depois da splash.
///
/// Com o painel aberto, mudanças no monitor (resolução, escala, barra de
/// tarefas, monitor conectado/desconectado) reaplicam a área útil.
class const RouteWindowSizer({
  super.key,
  required final GoRouter router,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<RouteWindowSizer> createState() => _RouteWindowSizerState();
}

class _RouteWindowSizerState extends State<RouteWindowSizer> {
  /// O Windows dispara vários eventos seguidos numa mesma mudança de monitor.
  static const _displayChangeDebounce = Duration(milliseconds: 300);

  final _log = AppLogger('RouteWindowSizer');

  /// A janela começa no tamanho do login (`AppWindow.initialize`).
  var _fullScreen = false;
  int? _displayListener;
  Timer? _displayChange;

  GoRouterDelegate get _delegate => widget.router.routerDelegate;

  @override
  void initState() {
    super.initState();
    _delegate.addListener(_apply);
    _listenDisplays();
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

  void _listenDisplays() {
    try {
      _displayListener = DisplayManager.instance.addListener((_) {
        _displayChange?.cancel();
        _displayChange = Timer(_displayChangeDebounce, () {
          // Splash/login/troca de senha ficam centralizados no tamanho fixo; só o painel acompanha o monitor.
          if (mounted && _fullScreen) AppWindow.refreshMain();
        });
      });
    } on Object catch (e, st) {
      // Sem os eventos do monitor o app funciona igual; só não reajusta sozinho.
      _log.warning('Não foi possível acompanhar mudanças do monitor', error: e, stackTrace: st);
    }
  }

  @override
  void dispose() {
    _delegate.removeListener(_apply);
    _displayChange?.cancel();
    if (_displayListener case final id?) {
      DisplayManager.instance.removeListener(id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

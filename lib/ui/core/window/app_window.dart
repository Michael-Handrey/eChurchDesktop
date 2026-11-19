import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Tamanho e posição da janela do Windows conforme a fase da sessão:
/// login (e troca de senha) em janela centralizada; o sistema, maximizado.
final class AppWindow._() {
  static const title = 'Minha Igreja - Gestão de Membros';
  /// Login, splash e troca de senha abrem no menor tamanho permitido.
  static const minimumSize = Size(960, 640);
  static const loginSize = minimumSize;

  static final _log = AppLogger('AppWindow');

  /// Chamar antes do `runApp`: o runner do Windows só mostra a janela no
  /// primeiro frame, então ela já aparece centralizada, sem pular de lugar.
  static void initialize() => _run('configurar', (window) {
    window.title = title;
    window.minimumSize = minimumSize.toNative();
    _centerAtLoginSize(window);
  });

  static void showLogin() => _run('voltar ao tamanho do login', (window) {
    if (window.isMaximized) window.unmaximize();
    _centerAtLoginSize(window);
  });

  static void showMain() => _run('maximizar', (window) {
    if (!window.isMaximized) window.maximize();
  });

  static void _centerAtLoginSize(Window window) {
    window.setSize(loginSize.toNative(), false);
    window.center();
  }

  /// Falha ao mexer na janela não pode derrubar o app: só registra.
  static void _run(String action, void Function(Window window) change) {
    try {
      final window = WindowManager.instance.getCurrent();
      if (window == null) {
        _log.warning('Janela atual indisponível ao $action');
        return;
      }
      change(window);
    } on Object catch (e, st) {
      _log.error('Falha ao $action a janela', error: e, stackTrace: st);
    }
  }
}

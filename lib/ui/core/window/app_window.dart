import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart' show Display, DisplayManager;
import 'package:window_manager/window_manager.dart';

/// Tamanho e posição da janela do Windows conforme a fase da sessão.
/// A janela é sempre fixa (sem redimensionar nem maximizar):
/// - splash, login e troca de senha: [loginSize], centralizada;
/// - sistema: ocupa a área útil do monitor (sem cobrir a barra de tarefas)
///   e não pode ser movida.
///
/// O sistema não usa o estado "maximizado" do Windows: uma janela maximizada
/// pode ser restaurada com duplo clique na barra de título.
final class AppWindow._() {
  static const title = 'Minha Igreja - Gestão de Membros';

  /// Splash, login e troca de senha: tamanho fixo (mínimo = máximo).
  static const loginSize = Size(960, 640);

  /// Usado só durante a troca de limites, para o mínimo nunca passar do máximo.
  static const _anySize = Size(1, 1);

  static final _log = AppLogger('AppWindow');

  /// Chamar antes do `runApp`: o runner do Windows só mostra a janela no
  /// primeiro frame, então ela já aparece centralizada, sem pular de lugar.
  static void initialize() => _run('configurar', (window) {
    window.title = title;
    _showLoginOn(window);
  });

  static void showLogin() => _run('voltar ao tamanho do login', _showLoginOn);

  static void showMain() => _run('ocupar a tela', (window) {
    final area = _workAreaOf(window);
    if (area == null) {
      _log.warning('Área útil do monitor indisponível; mantendo o tamanho atual');
      return;
    }

    _fix(window, area.size, () => window.bounds = area.toNative());
    window.isMovable = false;
  });

  /// Monitor mudou (resolução, escala, barra de tarefas, monitor ligado/desligado)
  /// com o painel aberto: reaplica a área útil, só se ela for diferente da atual.
  static void refreshMain() => _run('reajustar à nova área útil', (window) {
    final area = _workAreaOf(window);
    if (area == null || window.bounds.toRect() == area) return;

    _log.info('Janela fora da área útil do monitor (${window.bounds.toRect()} × $area); reajustando');
    _fix(window, area.size, () => window.bounds = area.toNative());
    window.isMovable = false;
  });

  static void _showLoginOn(Window window) {
    if (window.isMaximized) window.unmaximize();
    window.isMovable = true;
    _fix(window, loginSize, window.center);
  }

  /// Libera, aplica tamanho/posição e trava de novo (alguns sistemas ignoram
  /// mudança de tamanho em janela não redimensionável).
  static void _fix(Window window, Size size, VoidCallback place) {
    final native = size.toNative();
    window.isResizable = true;
    window.minimumSize = _anySize.toNative();
    window.maximumSize = native;
    window.minimumSize = native;
    window.setSize(native, false);
    place();
    window.isResizable = false;
    window.isMaximizable = false;
  }

  /// Área útil do monitor onde a janela está (ou do principal).
  static Rect? _workAreaOf(Window window) {
    final center = window.bounds.toRect().center;

    final current = DisplayManager.instance.getAll().cast<Display?>().firstWhere(
      (display) => display!.workArea.toRect().contains(center),
      orElse: DisplayManager.instance.getPrimary,
    );

    return current?.workArea.toRect();
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

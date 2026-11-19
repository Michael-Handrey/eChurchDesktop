import 'dart:async';

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/routing/routes.dart';
import 'package:echurch_desktop/ui/splash/widgets/splash_content.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Abertura do app e transição após o login/troca de senha.
///
/// Mostra o que está acontecendo ("Verificando sua sessão…" e depois o destino)
/// e só segue quando: a animação mínima terminou, a sessão foi restaurada e a
/// mensagem do destino ficou visível por [readDuration]. O redirect do router
/// continua decidindo o destino final.
class const SplashScreen({
  super.key,
  required final AuthSessionNotifier session,
  final Duration bootDuration = const Duration(milliseconds: 1500),
  final Duration readDuration = const Duration(milliseconds: 1200),
}) extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _boot = AnimationController(vsync: this, duration: widget.bootDuration);

  /// Conta o tempo de leitura a partir de quando a mensagem do destino aparece.
  Timer? _readTimer;
  var _read = false;
  var _leaving = false;

  AuthSessionNotifier get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _boot.forward().then((_) => _exitWhenReady());
    _onSessionChanged();
  }

  void _onSessionChanged() {
    if (_session.isRestored) {
      _readTimer ??= Timer(widget.readDuration, () {
        _read = true;
        _exitWhenReady();
      });
    }
    if (mounted) setState(() {});
  }

  String get _destination => switch (_session) {
    AuthSessionNotifier(isSignedIn: false) => Routes.login,
    AuthSessionNotifier(mustChangePassword: true) => Routes.firstAccess,
    _ => Routes.dashboard,
  };

  String get _message {
    if (!_session.isRestored) return 'Verificando sua sessão…';

    return switch (_destination) {
      Routes.login => 'Nenhuma sessão ativa. Abrindo o login…',
      Routes.firstAccess => 'Senha provisória detectada. Vamos cadastrar a sua nova senha…',
      _ => _firstName.isEmpty ? 'Bem-vindo! Preparando o painel…' : 'Olá, $_firstName! Preparando o painel…',
    };
  }

  String get _firstName => (_session.user?.name ?? '').trim().split(RegExp(r'\s+')).first;

  /// Segue quando a animação mínima e o tempo de leitura terminaram.
  void _exitWhenReady() {
    if (!mounted || _leaving || !_boot.isCompleted || !_read) return;

    _leaving = true;
    context.go(_destination);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _readTimer?.cancel();
    _boot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _boot,
        builder: (context, _) => SplashContentWidget(progress: _boot.value, message: _message),
      ),
    );
  }
}

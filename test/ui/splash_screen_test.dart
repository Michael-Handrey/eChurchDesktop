import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:echurch_desktop/routing/routes.dart';
import 'package:echurch_desktop/ui/splash/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/auth_fakes.dart';

const _boot = Duration(milliseconds: 1500);
const _read = Duration(milliseconds: 1200);

Future<AuthSessionNotifier> _sessionWith(AuthSession? stored) async {
  final sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
  if (stored != null) await sessions.save(stored, remember: true);
  final auth = FakeAuthRepository();
  return AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(authRepository: auth, authSessionRepository: sessions),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: sessions,
      authRefreshSessionUseCase: AuthRefreshSessionUseCase(authRepository: auth, authSessionRepository: sessions),
    ),
    sessionEnded: const Stream.empty(),
  );
}

/// Router mínimo: só a splash de verdade; destinos são marcadores.
GoRouter _router(AuthSessionNotifier session) => GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => SplashScreen(session: session)),
    for (final path in [Routes.login, Routes.dashboard, Routes.firstAccess]) GoRoute(path: path, builder: (_, _) => Text('tela $path')),
  ],
);

/// Avança a animação e o tempo de leitura (o pumpAndSettle não espera timers).
Future<void> _finishSplash(WidgetTester tester) async {
  await tester.pump(_boot);
  await tester.pump(_read);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem sessão: avisa e abre o login', (tester) async {
    final session = await _sessionWith(null);
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(session)));
    await tester.pump();

    expect(find.text('Nenhuma sessão ativa. Abrindo o login…'), findsOneWidget);

    await _finishSplash(tester);
    expect(find.text('tela ${Routes.login}'), findsOneWidget);
  });

  testWidgets('sessão lembrada: cumprimenta pelo nome e abre o painel', (tester) async {
    final session = await _sessionWith(sessionOf('1'));
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(session)));
    await tester.pump();

    expect(find.text('Olá, Maria! Preparando o painel…'), findsOneWidget);

    await _finishSplash(tester);
    expect(find.text('tela ${Routes.dashboard}'), findsOneWidget);
  });

  testWidgets('senha provisória: avisa e abre a troca de senha', (tester) async {
    final session = await _sessionWith(sessionOf('1', firstAccess: true));
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(session)));
    await tester.pump();

    expect(find.text('Senha provisória detectada. Vamos cadastrar a sua nova senha…'), findsOneWidget);

    await _finishSplash(tester);
    expect(find.text('tela ${Routes.firstAccess}'), findsOneWidget);
  });

  testWidgets('a splash fica no ar pelo menos a animação e o tempo de leitura', (tester) async {
    final session = await _sessionWith(sessionOf('1'));
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(session)));
    await tester.pump();

    await tester.pump(_read - const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);

    await _finishSplash(tester);
    expect(find.byType(SplashScreen), findsNothing);
  });
}

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:echurch_desktop/routing/router.dart';
import 'package:echurch_desktop/routing/routes.dart';
import 'package:echurch_desktop/ui/auth/first_access/first_access_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/auth_fakes.dart';

class _NoopAccountRepository implements AccountRepository {
  @override
  Future<Result<void>> changePassword({required String currentPassword, required String newPassword}) async => Result.done;
}

void main() {
  testWidgets('senha provisória só deixa abrir a troca de senha', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
    await sessions.save(sessionOf('1', firstAccess: true), remember: true);
    final auth = FakeAuthRepository();
    final refresh = AuthRefreshSessionUseCase(authRepository: auth, authSessionRepository: sessions);

    final session = AuthSessionNotifier(
      authLogoutUseCase: AuthLogoutUseCase(authRepository: auth, authSessionRepository: sessions),
      authRestoreSessionUseCase: AuthRestoreSessionUseCase(authSessionRepository: sessions, authRefreshSessionUseCase: refresh),
      sessionEnded: const Stream.empty(),
    );
    final appRouter = router(session);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AccountRepository>.value(value: _NoopAccountRepository()),
          Provider.value(value: refresh),
          ChangeNotifierProvider.value(value: session),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    // Passa pela splash: animação + tempo de leitura.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(session.mustChangePassword, isTrue);
    expect(find.byType(FirstAccessScreen), findsOneWidget);

    appRouter.go(Routes.dashboard);
    await tester.pumpAndSettle();

    expect(appRouter.routerDelegate.currentConfiguration.uri.path, Routes.firstAccess);
    expect(find.byType(FirstAccessScreen), findsOneWidget);
  });
}

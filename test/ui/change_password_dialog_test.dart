import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_change_password_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:echurch_desktop/ui/account/change_password/change_password_dialog.dart';
import 'package:echurch_desktop/ui/account/change_password/change_password_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/auth_fakes.dart';
import '../support/user_admin_fakes.dart';

class _FakeAccountRepository implements AccountRepository {
  Result<void> response = Result.done;
  final calls = <({String currentPassword, String newPassword})>[];

  @override
  Future<Result<void>> changePassword({required String currentPassword, required String newPassword}) async {
    calls.add((currentPassword: currentPassword, newPassword: newPassword));
    return response;
  }
}

void main() {
  late _FakeAccountRepository accounts;
  late FakeAuthRepository auth;
  late ChangePasswordViewModel viewModel;

  Future<void> openDialog(WidgetTester tester) async {
    accounts = _FakeAccountRepository();
    auth = FakeAuthRepository();
    final sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
    await sessions.save(sessionOf('1'), remember: true);
    viewModel = ChangePasswordViewModel(
      changePasswordUseCase: AuthChangePasswordUseCase(
        accountRepository: accounts,
        authRefreshSessionUseCase: AuthRefreshSessionUseCase(authRepository: auth, authSessionRepository: sessions),
      ),
      sessionNotifier: sessionSignedInAs(admin),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => ChangePasswordDialog(viewModel: viewModel),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.byType(TextField).at(['Senha atual', 'Nova senha', 'Confirme a nova senha'].indexOf(label));

  FilledButton submit(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Alterar senha'));

  testWidgets('só libera com senha atual, nova senha válida e confirmação igual', (tester) async {
    await openDialog(tester);
    expect(find.text('Alterar minha senha'), findsOneWidget);
    expect(submit(tester).onPressed, isNull);

    await tester.enterText(field('Senha atual'), 'Atual@2025');
    await tester.enterText(field('Nova senha'), 'Nova@2026x');
    await tester.enterText(field('Confirme a nova senha'), 'Nova@2026y');
    await tester.pumpAndSettle();
    expect(find.text('As senhas não conferem.'), findsOneWidget);
    expect(submit(tester).onPressed, isNull);

    await tester.enterText(field('Confirme a nova senha'), 'Nova@2026x');
    await tester.pumpAndSettle();
    expect(submit(tester).onPressed, isNotNull);
  });

  testWidgets('senha atual errada mostra o erro e mantém o diálogo aberto', (tester) async {
    await openDialog(tester);
    accounts.response = const Result.error(ValidationException('Senha atual incorreta.'));

    await tester.enterText(field('Senha atual'), 'Errada@2025');
    await tester.enterText(field('Nova senha'), 'Nova@2026x');
    await tester.enterText(field('Confirme a nova senha'), 'Nova@2026x');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Alterar senha'));
    await tester.pumpAndSettle();

    expect(find.text('Senha atual incorreta.'), findsOneWidget);
    expect(find.text('Alterar minha senha'), findsOneWidget);
  });

  testWidgets('senha alterada e sessão renovada: fecha o diálogo', (tester) async {
    await openDialog(tester);
    auth.nextRefresh().complete(Result.ok(sessionOf('2')));

    await tester.enterText(field('Senha atual'), 'Atual@2025');
    await tester.enterText(field('Nova senha'), 'Nova@2026x');
    await tester.enterText(field('Confirme a nova senha'), 'Nova@2026x');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Alterar senha'));
    await tester.pumpAndSettle();

    expect(accounts.calls.single, (currentPassword: 'Atual@2025', newPassword: 'Nova@2026x'));
    expect(find.text('Alterar minha senha'), findsNothing);
  });
}

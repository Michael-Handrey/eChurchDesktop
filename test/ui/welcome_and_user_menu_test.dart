import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/welcome_banner.dart';
import 'package:echurch_desktop/ui/main/widgets/user_menu.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

void main() {
  test('saudação conforme a hora do dia', () {
    expect(WelcomeBannerTextWidget.greetingAt(DateTime(2026, 1, 1, 8)), 'Bom dia');
    expect(WelcomeBannerTextWidget.greetingAt(DateTime(2026, 1, 1, 14)), 'Boa tarde');
    expect(WelcomeBannerTextWidget.greetingAt(DateTime(2026, 1, 1, 21)), 'Boa noite');
    expect(WelcomeBannerTextWidget.greetingAt(DateTime(2026, 1, 1, 2)), 'Boa noite');
  });

  test('primeiro nome, ou o login quando não há nome', () {
    expect(WelcomeBannerTextWidget.firstNameOf(secretary), 'Maria');
    expect(WelcomeBannerTextWidget.firstNameOf(const AuthSessionUser(login: 'joao', name: '  ', firstAccess: false)), 'joao');
  });

  test('mensagem e perfil conforme as permissões', () {
    expect(WelcomeBannerTextWidget.subtitleFor(admin), contains('gerencie quem acessa'));
    expect(WelcomeBannerTextWidget.subtitleFor(secretary), contains('membros, crianças'));
    expect(WelcomeBannerTextWidget.subtitleFor(const AuthSessionUser(login: 'x', name: 'X', firstAccess: false, roles: ['ROLE_USER'])), startsWith('Consulte'));

    expect(UserMenuWidget.profileOf(admin), 'Administrador');
    expect(UserMenuWidget.profileOf(secretary), 'Secretaria');
    expect(UserMenuWidget.profileOf(null), 'Usuário');
  });

  testWidgets('menu do usuário mostra nome e perfil, com "Alterar minha senha" e "Sair"', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthSessionNotifier>.value(
        value: sessionSignedInAs(secretary),
        child: const MaterialApp(
          home: Scaffold(body: Center(child: UserMenuWidget())),
        ),
      ),
    );

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Secretaria'), findsOneWidget);

    await tester.tap(find.byType(UserMenuWidget));
    await tester.pumpAndSettle();
    expect(find.text('Alterar minha senha'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });
}

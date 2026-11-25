import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_action_cards.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/welcome_banner.dart';
import 'package:echurch_desktop/ui/main/widgets/sidebar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

const _lider = AuthSessionUser(login: 'ana', name: 'Ana Souza', firstAccess: false, churchId: 1, roles: [AuthSessionUser.ministryLeaderRole]);
const _liderQueConsulta = AuthSessionUser(login: 'ana', name: 'Ana Souza', firstAccess: false, churchId: 1, roles: [AuthSessionUser.ministryLeaderRole, AuthSessionUser.userRole]);

/// FEAT-8: o Líder de ministério sozinho não vê Membros, Crianças, os números da tela inicial nem a busca rápida.
void main() {
  test('quem vê membros: Administrador, Secretaria ou Usuário (as permissões se somam)', () {
    expect(_lider.canSeeMembers, isFalse);
    expect(_lider.isMinistryLeader, isTrue);
    expect(_liderQueConsulta.canSeeMembers, isTrue);
    expect(secretary.canSeeMembers, isTrue);
    expect(admin.canSeeMembers, isTrue);
  });

  Future<void> pumpSidebar(WidgetTester tester, AuthSessionUser user) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthSessionNotifier>.value(value: sessionSignedInAs(user)),
          ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 300, height: 900, child: SidebarNavListWidget())),
        ),
      ),
    );
    await tester.tap(find.text('Secretaria'));
    await tester.pumpAndSettle();
  }

  testWidgets('menu: o líder vê Ministérios e Pedido de Oração, sem Membros nem Crianças', (tester) async {
    await pumpSidebar(tester, _lider);
    expect(find.text('Ministérios'), findsOneWidget);
    expect(find.text('Pedido de Oração'), findsOneWidget);
    expect(find.text('Membros'), findsNothing);
    expect(find.text('Crianças'), findsNothing);

    await pumpSidebar(tester, _liderQueConsulta);
    expect(find.text('Membros'), findsOneWidget, reason: 'com Usuário, vê como antes');
  });

  testWidgets('tela inicial do líder: só as boas-vindas, sem os cards e os painéis', (tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthSessionNotifier>.value(value: sessionSignedInAs(_lider)),
          ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen(showChurchData: false))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QuickActionCardsSectionWidget), findsNothing);
    expect(find.byType(DashboardLowerPanelsWidget), findsNothing);
    expect(find.text(WelcomeBannerTextWidget.subtitleFor(_lider)), findsOneWidget);
    expect(WelcomeBannerTextWidget.subtitleFor(_lider), 'Acompanhe os membros dos ministérios que você lidera.');
  });
}

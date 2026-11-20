import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/ui/main/widgets/top_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

const _adminOfBranch = AuthSessionUser(login: 'admin', name: 'Admin', firstAccess: false, churchId: 2, roles: [AuthSessionUser.adminRole]);
const _secretaryOfBranch = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 2, roles: ['ROLE_SECRETARIA']);

void main() {
  /// [reachable]: o que a API devolveria para [user] (todas, por padrão: admin ou sede).
  Future<ChurchContextNotifier> contextFor(AuthSessionUser user, [List<ChurchSummary> reachable = churches]) async {
    final notifier = ChurchContextNotifier(churchRepository: FakeChurchRepository(reachable), sessionNotifier: sessionSignedInAs(user));
    await pumpEventQueue();
    return notifier;
  }

  test('começa na igreja do usuário logado', () async {
    final notifier = await contextFor(_secretaryOfBranch);
    expect(notifier.selected?.name, 'Filial - Londrina');
  });

  test('administrador troca a igreja em uso', () async {
    final notifier = await contextFor(_adminOfBranch);
    expect(notifier.canSwitch, isTrue);

    notifier.select(3);
    expect(notifier.selected?.name, 'Filial - Maringá');
  });

  test('secretaria da sede troca entre sede e filiais', () async {
    const secretaryOfHeadquarters = AuthSessionUser(login: 'ana', name: 'Ana', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);
    final notifier = await contextFor(secretaryOfHeadquarters);
    expect(notifier.selected?.name, 'Sede - Rolândia');
    expect(notifier.canSwitch, isTrue);

    notifier.select(2);
    expect(notifier.selected?.name, 'Filial - Londrina');
  });

  test('secretaria de filial fica na própria igreja', () async {
    final notifier = await contextFor(_secretaryOfBranch, [churches[1]]);
    expect(notifier.canSwitch, isFalse);

    notifier.select(1);
    expect(notifier.selected?.name, 'Filial - Londrina');
  });

  test('logout limpa a igreja em uso', () async {
    final session = sessionSignedInAs(_adminOfBranch);
    final notifier = ChurchContextNotifier(churchRepository: FakeChurchRepository(), sessionNotifier: session);
    await pumpEventQueue();
    expect(notifier.selected, isNotNull);

    await session.logout();
    expect(notifier.selected, isNull);
    expect(notifier.churches, isEmpty);
  });

  testWidgets('seletor da barra superior: administrador escolhe a igreja no menu', (tester) async {
    // Fora do relógio simulado do testWidgets: a carga das igrejas é assíncrona de verdade.
    final notifier = (await tester.runAsync(() => contextFor(_adminOfBranch)))!;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ChurchSelectorWidget())),
        ),
      ),
    );

    expect(find.text('Filial - Londrina'), findsOneWidget);
    await tester.tap(find.byType(ChurchSelectorWidget));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckedPopupMenuItem<int>).first); // Sede - Rolândia
    await tester.pumpAndSettle();

    expect(notifier.selected?.id, 1);
    expect(find.text('Sede - Rolândia'), findsOneWidget);
  });
}

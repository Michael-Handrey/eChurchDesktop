import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/ui/main/widgets/top_header.dart';
import 'package:echurch_desktop/ui/main/widgets/user_menu.dart';
import 'package:echurch_desktop/ui/members/member_quick_search_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

/// A busca rápida só consulta ao digitar; aqui ninguém digita.
class _UnusedMemberRepository implements MemberRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _admin = AuthSessionUser(login: 'michael', name: 'Michael Handrey dos Santos Augusto', firstAccess: false, churchId: 1, roles: [AuthSessionUser.adminRole]);

void main() {
  Future<void> pumpHeader(WidgetTester tester, double width, {AuthSessionUser user = _admin}) async {
    tester.view.physicalSize = Size(width, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = sessionSignedInAs(user);
    final churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(), sessionNotifier: session);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthSessionNotifier>.value(value: session),
          ChangeNotifierProvider.value(value: churchContext),
          ChangeNotifierProvider(
            create: (_) => MemberQuickSearchViewModel(repository: _UnusedMemberRepository(), session: session),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [TopHeaderWidget()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('larga: nome e perfil do usuário ao lado do avatar', (tester) async {
    await pumpHeader(tester, 1600);
    expect(find.text('Michael Handrey dos Santos Augusto'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(tester.getTopRight(find.byType(UserMenuWidget)).dx, closeTo(1600 - 28, 1), reason: 'usuário encostado à direita');
  });

  testWidgets('estreita (janela 960 menos o menu lateral): só o avatar, sem estourar', (tester) async {
    await pumpHeader(tester, 660);
    expect(find.text('Michael Handrey dos Santos Augusto'), findsNothing);
    expect(find.text('MA'), findsOneWidget, reason: 'iniciais no avatar');
    expect(find.byKey(const ValueKey('busca-rapida')), findsOneWidget);
    expect(tester.getTopRight(find.byType(UserMenuWidget)).dx, closeTo(660 - 28, 1), reason: 'usuário encostado à direita');
  });

  testWidgets('líder de ministério sozinho: sem a busca rápida de membros, usuário à direita', (tester) async {
    await pumpHeader(
      tester,
      1600,
      user: const AuthSessionUser(login: 'ana', name: 'Ana Souza', firstAccess: false, churchId: 1, roles: [AuthSessionUser.ministryLeaderRole]),
    );
    expect(find.byKey(const ValueKey('busca-rapida')), findsNothing);
    expect(find.text('Líder de ministério'), findsOneWidget, reason: 'perfil sob o nome');
    expect(tester.getTopRight(find.byType(UserMenuWidget)).dx, closeTo(1600 - 28, 1));
  });
}

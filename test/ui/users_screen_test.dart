import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/main/widgets/sidebar.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/users/groups_viewmodel.dart';
import 'package:echurch_desktop/ui/users/users_screen.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

void main() {
  late FakeUserAdminRepository repository;
  late FakeGroupAdminRepository groupRepository;
  late UsersViewModel viewModel;
  late GroupsViewModel groupsViewModel;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeUserAdminRepository();
    groupRepository = FakeGroupAdminRepository();
    viewModel = UsersViewModel(
      userAdminRepository: repository,
      groupAdminRepository: groupRepository,
      churchRepository: FakeChurchRepository(),
      sessionNotifier: sessionSignedInAs(admin),
    );
    groupsViewModel = GroupsViewModel(groupAdminRepository: groupRepository);
    await viewModel.load.execute();
    await groupsViewModel.load.execute();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UsersScreen(viewModel: viewModel, groupsViewModel: groupsViewModel),
        ),
      ),
    );
  }

  /// "Redefinir senha" só nas linhas dos outros: Maria Silva, João Souza.
  Future<void> openResetFor(WidgetTester tester, String name) async {
    expect(find.text(name), findsOneWidget);
    final index = {'Maria Silva': 0, 'João Souza': 1}[name]!;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Redefinir senha').at(index));
    await tester.pumpAndSettle();
  }

  testWidgets('na própria linha, o administrador altera a senha em vez de redefinir', (tester) async {
    await pumpScreen(tester);
    expect(find.widgetWithText(OutlinedButton, 'Redefinir senha'), findsNWidgets(2), reason: 'só Maria e João');
    expect(find.widgetWithText(OutlinedButton, 'Alterar senha'), findsOneWidget);
  });

  testWidgets('desativar pede confirmação; reativar é direto', (tester) async {
    await pumpScreen(tester);
    final buttons = tester.widgetList<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Desativar')).toList();
    expect(buttons.first.onPressed, isNull, reason: 'o admin não desativa a si mesmo');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Desativar').at(1)); // Maria
    await tester.pumpAndSettle();
    expect(find.text('Desativar Maria Silva?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Desativar'));
    await tester.pumpAndSettle();

    expect(repository.activeCalls.single, (userId: 2, active: false));
    expect(find.text('Maria Silva foi desativado.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Reativar'), findsNWidgets(2), reason: 'Maria e João');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reativar').first);
    await tester.pumpAndSettle();
    expect(repository.activeCalls.last, (userId: 2, active: true));
  });

  testWidgets('acesso: troca a igreja do usuário', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Acesso').at(2)); // João, da sede
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sede - Rolândia').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filial - Maringá').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(repository.churchCalls.single, (userId: 3, churchId: 3));
    expect(repository.groupCalls, isEmpty);
    expect(find.text('Filial - Maringá'), findsOneWidget, reason: 'coluna Igreja da linha do João');
  });

  testWidgets('coluna e filtro por igreja', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Filial - Londrina'), findsOneWidget);

    await tester.tap(find.text('Todas as igrejas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filial - Londrina').last);
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('João Souza'), findsNothing);
  });

  testWidgets('filtro por grupo na lista de usuários', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Todos os grupos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Secretaria').last);
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('João Souza'), findsNothing);
  });

  testWidgets('grupos do usuário: marca, salva e atualiza a linha', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Acesso').at(2)); // João
    await tester.pumpAndSettle();

    expect(find.text('Acesso de João Souza'), findsOneWidget);
    FilledButton save() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'));
    expect(save().onPressed, isNull, reason: 'nada mudou ainda');

    await tester.tap(find.byType(CheckboxListTile).at(1)); // Secretaria (o nome também aparece como permissão)
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(repository.groupCalls.single.userId, 3);
    expect(repository.groupCalls.single.groupIds, {2, 3});
    expect(find.text('Acesso de João Souza'), findsNothing);
    expect(find.text('Acesso de João Souza atualizado.'), findsOneWidget);
  });

  testWidgets('grupos do usuário: erro do backend aparece no diálogo', (tester) async {
    await pumpScreen(tester);
    repository.groupsError = const ValidationException('Você não pode tirar o seu próprio acesso de administrador.');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Acesso').at(0)); // Administrador
    await tester.pumpAndSettle();

    // Troca Administrador por Secretaria (o backend recusa: tiraria o próprio acesso).
    await tester.tap(find.byType(CheckboxListTile).at(1)); // Secretaria
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Administrador'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Você não pode tirar o seu próprio acesso de administrador.'), findsOneWidget);
    expect(find.text('Acesso de Administrador'), findsOneWidget);
  });

  testWidgets('aba de grupos: cria grupo com nome e permissões', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Grupos e permissões'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Novo grupo'));
    await tester.pumpAndSettle();

    FilledButton create() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Criar grupo'));
    expect(create().onPressed, isNull, reason: 'sem nome');

    await tester.enterText(find.widgetWithText(TextField, 'Nome do grupo'), 'secretaria');
    await tester.pumpAndSettle();
    expect(find.text('Já existe um grupo com esse nome.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nome do grupo'), 'Tesouraria');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Usuário'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar grupo'));
    await tester.pumpAndSettle();

    final call = groupRepository.saveCalls.single;
    expect((call.id, call.name), (null, 'Tesouraria'));
    expect(call.permissions, {'ROLE_USER'});
    expect(find.text('Tesouraria'), findsOneWidget);
    expect(find.text('Grupo criado.'), findsOneWidget);
  });

  testWidgets('aba de grupos: só exclui grupo sem usuários', (tester) async {
    await pumpScreen(tester);
    groupRepository.stored = [...groupRepository.stored, const SecurityGroup(id: 9, name: 'Antigo')];
    await groupsViewModel.load.execute();
    await tester.tap(find.text('Grupos e permissões'));
    await tester.pumpAndSettle();

    final deletes = tester.widgetList<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Excluir')).toList();
    expect(deletes.where((button) => button.onPressed != null), hasLength(1), reason: 'só o grupo "Antigo" está vazio');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Excluir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(groupRepository.deleteCalls, [9]);
    expect(find.text('Antigo'), findsNothing);
  });

  testWidgets('gerar senha: confirma, mostra a senha uma vez e permite copiar', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });

    await pumpScreen(tester);
    await openResetFor(tester, 'Maria Silva');

    expect(find.text('Redefinir a senha de Maria Silva'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    expect(repository.resetCalls.single, (userId: 2, temporaryPassword: null));
    expect(find.text('Senha provisória definida'), findsOneWidget);
    expect(find.text('Gerada@1234'), findsOneWidget);

    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(copied, ['Gerada@1234']);
    expect(find.text('Copiada'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(find.text('Gerada@1234'), findsNothing, reason: 'a senha não fica visível depois de fechar');
    expect(find.text('Senha provisória'), findsOneWidget, reason: 'marca na linha da Maria');
  });

  testWidgets('definir senha: só libera quando atende às regras e envia a senha digitada', (tester) async {
    await pumpScreen(tester);
    await openResetFor(tester, 'João Souza');

    await tester.tap(find.text('Definir senha'));
    await tester.pumpAndSettle();

    FilledButton confirm() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Redefinir senha'));

    await tester.enterText(find.byType(TextField).last, 'fraca');
    await tester.pumpAndSettle();
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Prov1s@ria');
    await tester.pumpAndSettle();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Redefinir senha'));
    await tester.pumpAndSettle();
    expect(repository.resetCalls.single, (userId: 3, temporaryPassword: 'Prov1s@ria'));
    expect(find.text('Prov1s@ria'), findsOneWidget);
  });

  testWidgets('erro do backend aparece no diálogo, que continua aberto', (tester) async {
    await pumpScreen(tester);
    repository.resetError = const ValidationException('Para alterar a sua própria senha, use a troca de senha.');
    await openResetFor(tester, 'Maria Silva');

    await tester.tap(find.widgetWithText(FilledButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    expect(find.text('Para alterar a sua própria senha, use a troca de senha.'), findsOneWidget);
    expect(find.text('Redefinir a senha de Maria Silva'), findsOneWidget);
    expect(find.text('Senha provisória definida'), findsNothing);
  });

  testWidgets('"Usuários e acesso" fica dentro de Configurações, só para administrador', (tester) async {
    Future<void> pumpSidebar(AuthSessionNotifier session) async {
      await tester.pumpWidget(const SizedBox()); // estado do menu novo a cada sessão
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthSessionNotifier>.value(value: session),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SizedBox(width: 300, height: 900, child: SidebarNavListWidget())),
          ),
        ),
      );
    }

    await pumpSidebar(sessionSignedInAs(admin));
    expect(find.text('Usuários e acesso'), findsNothing, reason: 'Configurações começa fechado');
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Usuários e acesso'), findsOneWidget);

    await pumpSidebar(sessionSignedInAs(secretary));
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Usuários e acesso'), findsNothing);
  });

  testWidgets('falha ao carregar mostra a mensagem e permite tentar de novo', (tester) async {
    await pumpScreen(tester);
    repository.listError = const NetworkException();
    await viewModel.load.execute();
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);

    repository.listError = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Silva'), findsOneWidget);
  });

  testWidgets('acesso: sem nenhum grupo marcado não dá para salvar', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Acesso').at(2)); // João, só no grupo Usuário
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile).at(2)); // desmarca Usuário
    await tester.pumpAndSettle();

    expect(find.text('Escolha pelo menos um grupo.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar')).onPressed, isNull);
  });
}

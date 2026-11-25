import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/dashboard/dashboard_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/dashboard/birthday.dart';
import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/domain/models/dashboard/recent_activity.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/dashboard/home_viewmodel.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/birthdays.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_action_cards.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/recent_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// O que a API devolveria para a igreja em uso.
HomeData _data({List<Birthday>? today, List<Birthday>? next}) => HomeData(
  stats: const [
    QuickStat(label: 'membros ativos', count: 248, type: QuickStatType.members),
    QuickStat(label: 'até 10 anos', count: 72, type: QuickStatType.children),
    QuickStat(label: 'novos', count: 18, type: QuickStatType.prayers),
  ],
  birthdaysToday:
      today ??
      [
        Birthday(name: 'Maria Souza', date: _today, age: 34),
        Birthday(name: 'Pedro Lima', date: _today, age: 8, isChild: true),
        Birthday(name: 'Antônio Ferreira', date: _today, age: 61),
      ],
  birthdaysNext:
      next ??
      [
        Birthday(name: 'Carla Dias', date: _today.add(const Duration(days: 1)), age: 27),
        Birthday(name: 'Lucas Almeida', date: _today.add(const Duration(days: 3)), age: 9, isChild: true),
      ],
  activities: [
    RecentActivity(id: 1, title: 'João da Silva', type: ActivityType.member, at: DateTime.now().subtract(const Duration(minutes: 5))),
    RecentActivity(id: 2, title: 'Pedido de oração de Família Oliveira', type: ActivityType.prayer, at: DateTime.now().subtract(const Duration(days: 3))),
  ],
);

class _FakeDashboard implements DashboardRepository {
  _FakeDashboard(this.result);

  Result<HomeData> result;
  final churches = <int>[];

  @override
  Future<Result<HomeData>> load(int churchId) async {
    churches.add(churchId);
    return result;
  }
}

const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);

/// Tela inicial: cards com o número de cada área, aniversariantes ao lado dos últimos registros (dados da API).
void main() {
  late DashboardViewModel navigation;
  late _FakeDashboard repository;

  Future<HomeViewModel> pumpHome(WidgetTester tester, {Result<HomeData>? result, Size size = const Size(1600, 1100)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    navigation = DashboardViewModel();
    repository = _FakeDashboard(result ?? Result.ok(_data()));
    final session = sessionSignedInAs(_secretaria);
    final churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(), sessionNotifier: session);
    final home = HomeViewModel(repository: repository, churchContext: churchContext);
    await tester.runAsync(() async {
      await pumpEventQueue();
      home.init();
      await pumpEventQueue();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: navigation),
          ChangeNotifierProvider.value(value: home),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: Column(children: [QuickActionCardsSectionWidget(), DashboardLowerPanelsWidget()])),
          ),
        ),
      ),
    );
    return home;
  }

  testWidgets('busca os dados da igreja em uso e mostra os números nos cards', (tester) async {
    await pumpHome(tester);

    expect(repository.churches, [1]);
    expect(find.text('248'), findsOneWidget);
    expect(find.text('membros ativos'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('até 10 anos'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);

    for (final description in ['Cadastre e consulte os membros.', 'Crianças e seus responsáveis.', 'Registre e acompanhe os pedidos.']) {
      expect(tester.widget<Text>(find.text(description)).maxLines, 1);
    }
    final heights = tester.widgetList(find.byType(QuickActionCardWidget)).map((card) => tester.getSize(find.byWidget(card)).height).toSet();
    expect(heights, hasLength(1), reason: 'os três cards com a mesma altura');
  });

  testWidgets('falha na API: cards com "—" e aviso nos painéis', (tester) async {
    await pumpHome(tester, result: Result.error(const NetworkException()));

    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('Não foi possível carregar os aniversariantes.'), findsOneWidget);
    expect(find.text('Não foi possível carregar os últimos registros.'), findsOneWidget);
  });

  testWidgets('janela pequena: cards estreitos levam o número para baixo do título, sem estourar', (tester) async {
    await pumpHome(tester);
    expect(find.text('248'), findsOneWidget, reason: 'larga: número à direita');

    // Conteúdo de uma janela 960×640 (menos o menu lateral de 300).
    tester.view.physicalSize = const Size(660, 1100);
    await tester.pumpAndSettle();
    expect(find.text('248 membros ativos', findRichText: true), findsOneWidget);
    expect(find.text('Últimos Registros'), findsOneWidget);
  });

  testWidgets('aniversariantes e últimos registros lado a lado, com a mesma altura', (tester) async {
    await pumpHome(tester);

    final birthdays = tester.getRect(find.byType(BirthdaysSectionWidget));
    final recent = tester.getRect(find.byType(RecentActivitySectionWidget));
    expect(birthdays.height, recent.height);
    expect(birthdays.top, recent.top);
    expect(tester.getRect(find.text('Aniversariantes')).top, tester.getRect(find.text('Últimos Registros')).top, reason: 'títulos na mesma linha');
  });

  testWidgets('aniversariantes: hoje com a idade e os próximos 7 dias', (tester) async {
    await pumpHome(tester);

    expect(find.text('3 hoje'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('34 anos'), findsOneWidget);
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.text(BirthdaysSectionWidget.dayLabel(_today.add(const Duration(days: 1)))), findsOneWidget);
    expect(find.text('criança'), findsNWidgets(2), reason: 'Pedro (hoje) e Lucas (próximos dias)');
  });

  testWidgets('quem só consulta não recebe a idade: mostra "hoje"', (tester) async {
    await pumpHome(
      tester,
      result: Result.ok(
        _data(
          today: [Birthday(name: 'Maria Souza', date: _today)],
        ),
      ),
    );
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('hoje'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+ anos$')), findsNothing, reason: 'nenhuma idade');
  });

  testWidgets('últimos registros com o tipo e há quanto tempo', (tester) async {
    await pumpHome(tester);
    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('Há 5 minutos'), findsOneWidget, reason: 'em minutos: não muda de dia perto da meia-noite');
    expect(find.text('Pedido de oração de Família Oliveira'), findsOneWidget);
    expect(find.text('Há 3 dias'), findsOneWidget);
    expect(find.text('Oração'), findsOneWidget);
  });

  test('há quanto tempo', () {
    final now = DateTime(2026, 11, 22, 15);
    expect(RecentActivity.timeAgo(now.subtract(const Duration(seconds: 20)), now), 'Agora');
    expect(RecentActivity.timeAgo(now.subtract(const Duration(minutes: 5)), now), 'Há 5 minutos');
    expect(RecentActivity.timeAgo(DateTime(2026, 11, 21, 23), now), 'Ontem');
    expect(RecentActivity.timeAgo(DateTime(2026, 11, 10), now), '10/11/2026');
  });

  testWidgets('cards de membros e de pedido de oração levam às telas e abrem a Secretaria no menu', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Pedido de Oração'));
    expect(navigation.selectedNavItem, DashboardViewModel.prayerRequestsNavItem);
    expect(navigation.isSecretariaExpanded, isTrue);

    navigation.selectNavItem('inicio');
    await tester.tap(find.text('Membros'));
    expect(navigation.selectedNavItem, DashboardViewModel.membersNavItem);

    navigation.selectNavItem('inicio');
    await tester.tap(find.text('Crianças'));
    expect(navigation.selectedNavItem, 'inicio', reason: 'Crianças ainda sem tela');
  });

  testWidgets('ninguém na semana: um aviso só, centralizado, e os painéis com a mesma altura', (tester) async {
    await pumpHome(
      tester,
      result: Result.ok(_data(today: const [], next: const [])),
    );

    expect(find.text('Nenhum aniversário esta semana'), findsOneWidget);
    expect(find.text('HOJE'), findsNothing);
    expect(find.textContaining(' hoje'), findsNothing, reason: 'sem a etiqueta "N hoje"');

    final panel = tester.getRect(find.byType(BirthdaysSectionWidget));
    expect(panel.height, tester.getRect(find.byType(RecentActivitySectionWidget)).height);
    final message = tester.getRect(find.text('Nenhum aniversário esta semana'));
    expect(message.center.dx, closeTo(panel.center.dx, 1), reason: 'centralizado');
  });

  testWidgets('ninguém hoje, mas alguém nos próximos dias: mostra as duas partes', (tester) async {
    await pumpHome(
      tester,
      result: Result.ok(
        _data(
          today: const [],
          next: [Birthday(name: 'Carla Dias', date: _today.add(const Duration(days: 1)), age: 27)],
        ),
      ),
    );

    expect(find.text('Ninguém faz aniversário hoje.'), findsOneWidget);
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.text('Nenhum aniversário esta semana'), findsNothing);
  });
}

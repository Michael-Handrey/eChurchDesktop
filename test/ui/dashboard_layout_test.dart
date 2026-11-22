import 'package:echurch_desktop/domain/models/dashboard/birthday.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/birthdays.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_action_cards.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/recent_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Tela inicial: cards com o número de cada área, aniversariantes ao lado dos últimos registros.
void main() {
  late DashboardViewModel viewModel;

  Future<void> pumpHome(WidgetTester tester, [DashboardViewModel? custom]) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    viewModel = custom ?? DashboardViewModel();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: Column(children: [QuickActionCardsSectionWidget(), DashboardLowerPanelsWidget()])),
          ),
        ),
      ),
    );
  }

  testWidgets('cards de cima mostram o número de cada área e a descrição em uma linha', (tester) async {
    await pumpHome(tester);

    expect(find.text('248'), findsOneWidget);
    expect(find.text('membros ativos'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);

    for (final description in ['Cadastre e consulte os membros.', 'Crianças e seus responsáveis.', 'Registre e acompanhe os pedidos.']) {
      expect(tester.widget<Text>(find.text(description)).maxLines, 1);
    }
    final heights = tester.widgetList(find.byType(QuickActionCardWidget)).map((card) => tester.getSize(find.byWidget(card)).height).toSet();
    expect(heights, hasLength(1), reason: 'os três cards com a mesma altura');
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
    expect(find.text(BirthdaysSectionWidget.dayLabel(viewModel.birthdaysNext.first.date)), findsOneWidget);
    expect(find.text('criança'), findsNWidgets(2), reason: 'Pedro (hoje) e Lucas (próximos dias)');
  });

  testWidgets('cards de membros e de pedido de oração levam às telas e abrem a Secretaria no menu', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Pedido de Oração'));
    expect(viewModel.selectedNavItem, DashboardViewModel.prayerRequestsNavItem);
    expect(viewModel.isSecretariaExpanded, isTrue);

    viewModel.selectNavItem('inicio');
    await tester.tap(find.text('Membros'));
    expect(viewModel.selectedNavItem, DashboardViewModel.membersNavItem);

    viewModel.selectNavItem('inicio');
    await tester.tap(find.text('Crianças'));
    expect(viewModel.selectedNavItem, 'inicio', reason: 'Crianças ainda sem tela');
  });

  testWidgets('ninguém na semana: um aviso só, centralizado, e os painéis com a mesma altura', (tester) async {
    await pumpHome(tester, DashboardViewModel(birthdaysToday: const [], birthdaysNext: const []));

    expect(find.text('Nenhum aniversário esta semana'), findsOneWidget);
    expect(find.text('HOJE'), findsNothing);
    expect(find.textContaining('hoje'), findsNothing, reason: 'sem a etiqueta "N hoje"');

    final panel = tester.getRect(find.byType(BirthdaysSectionWidget));
    expect(panel.height, tester.getRect(find.byType(RecentActivitySectionWidget)).height);
    final message = tester.getRect(find.text('Nenhum aniversário esta semana'));
    expect(message.center.dx, closeTo(panel.center.dx, 1), reason: 'centralizado');
  });

  testWidgets('ninguém hoje, mas alguém nos próximos dias: mostra as duas partes', (tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await pumpHome(
      tester,
      DashboardViewModel(
        birthdaysToday: const [],
        birthdaysNext: [Birthday(name: 'Carla Dias', date: tomorrow, age: 27)],
      ),
    );

    expect(find.text('Ninguém faz aniversário hoje.'), findsOneWidget);
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.text('Nenhum aniversário esta semana'), findsNothing);
  });
}

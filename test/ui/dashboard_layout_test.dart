import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_stats.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/recent_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Alinhamento dos painéis "Estatísticas Rápidas" e "Últimos Registros" do painel inicial.
void main() {
  Future<void> pumpPanels(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DashboardViewModel(),
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: DashboardLowerPanelsWidget())),
        ),
      ),
    );
  }

  testWidgets('os dois painéis têm a mesma altura e os títulos começam na mesma linha', (tester) async {
    await pumpPanels(tester);

    final stats = tester.getRect(find.byType(QuickStatsSectionWidget));
    final recent = tester.getRect(find.byType(RecentActivitySectionWidget));
    expect(stats.height, recent.height);
    expect(stats.top, recent.top);

    expect(tester.getRect(find.byType(QuickStatsHeaderWidget)).top, tester.getRect(find.byType(RecentActivityHeaderWidget)).top);
    expect(tester.getSize(find.byType(QuickStatsHeaderWidget)).height, tester.getSize(find.byType(RecentActivityHeaderWidget)).height);
  });

  testWidgets('cards de estatística alinhados com as bordas do banner e com a mesma altura', (tester) async {
    await pumpPanels(tester);

    final cards = tester.widgetList(find.byType(StatCounterCardWidget)).map((card) => tester.getRect(find.byWidget(card))).toList();
    final banner = tester.getRect(find.byType(MissionBannerWidget));

    expect(cards.first.left, banner.left);
    expect(cards.last.right, closeTo(banner.right, 0.5));
    expect(cards.map((card) => card.height).toSet(), hasLength(1));
    expect(cards.map((card) => card.top).toSet(), hasLength(1));
  });

  testWidgets('estatísticas mostram os aniversariantes do dia, com o número alinhado aos outros', (tester) async {
    await pumpPanels(tester);

    expect(find.byType(StatCounterCardWidget), findsNWidgets(4));
    expect(find.text('Aniversariantes do Dia'), findsOneWidget);
    expect(find.byIcon(Icons.cake_outlined), findsOneWidget);

    final numbers = ['248', '3', '72', '18'].map((value) => tester.getRect(find.text(value)).top).toSet();
    expect(numbers, hasLength(1), reason: 'números na mesma linha, mesmo com rótulo de duas linhas');
  });
}

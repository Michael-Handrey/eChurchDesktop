import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/birthdays.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/mission_banner.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_action_cards.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/recent_activity.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/welcome_banner.dart';
import 'package:material_ui/material_ui.dart';

/// Tela inicial: boas-vindas, cards (atalho + número de cada área), aniversariantes e últimos
/// registros lado a lado, e a faixa "Juntos na missão".
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            WelcomeBannerWidget(),
            SizedBox(height: 24),
            QuickActionCardsSectionWidget(),
            SizedBox(height: 24),
            DashboardLowerPanelsWidget(),
            SizedBox(height: 20),
            MissionBannerWidget(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Aniversariantes e últimos registros lado a lado, com a mesma altura.
class DashboardLowerPanelsWidget extends StatelessWidget {
  const DashboardLowerPanelsWidget({super.key});

  /// Altura do cabeçalho dos dois painéis: títulos e conteúdos começam na mesma linha.
  static const headerHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight + stretch: o painel mais baixo cresce até a altura do outro.
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Expanded(child: BirthdaysSectionWidget()),
          Expanded(child: RecentActivitySectionWidget()),
        ],
      ),
    );
  }
}

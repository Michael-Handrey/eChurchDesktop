import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_action_cards.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/quick_stats.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/recent_activity.dart';
import 'package:echurch_desktop/ui/dashboard/widgets/welcome_banner.dart';
import 'package:material_ui/material_ui.dart';

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
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Estatísticas e últimos registros lado a lado, com a mesma altura.
class DashboardLowerPanelsWidget extends StatelessWidget {
  const DashboardLowerPanelsWidget({super.key});

  /// Altura do cabeçalho dos dois painéis: títulos e conteúdos começam na mesma linha.
  static const headerHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight + stretch: o painel mais baixo cresce até a altura do outro.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(
            flex: 7,
            child: QuickStatsSectionWidget(),
          ),
          SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: RecentActivitySectionWidget(),
          ),
        ],
      ),
    );
  }
}

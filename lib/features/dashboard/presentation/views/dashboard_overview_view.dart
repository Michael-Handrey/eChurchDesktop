import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/quick_action_cards_section_widget.dart';
import '../widgets/quick_stats_section_widget.dart';
import '../widgets/recent_activity_section_widget.dart';
import '../widgets/welcome_banner_widget.dart';

class DashboardOverviewView extends StatelessWidget {
  const DashboardOverviewView({super.key});

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

class DashboardLowerPanelsWidget extends StatelessWidget {
  const DashboardLowerPanelsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

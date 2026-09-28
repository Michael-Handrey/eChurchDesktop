import 'package:material_ui/material_ui.dart';
import '../widgets/app_sidebar_widget.dart';
import '../widgets/top_header_widget.dart';
import 'dashboard_overview_view.dart';

class DashboardMainLayout extends StatelessWidget {
  const DashboardMainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: const [
          AppSidebarWidget(),
          Expanded(
            child: Column(
              children: [
                TopHeaderWidget(),
                Expanded(
                  child: DashboardOverviewView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

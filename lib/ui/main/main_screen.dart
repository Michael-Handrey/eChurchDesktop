import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/main/widgets/sidebar.dart';
import 'package:echurch_desktop/ui/main/widgets/top_header.dart';
import 'package:material_ui/material_ui.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
                  child: DashboardScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/main/widgets/sidebar.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_bindings.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_screen.dart';
import 'package:echurch_desktop/ui/main/widgets/top_header.dart';
import 'package:echurch_desktop/ui/users/users_bindings.dart';
import 'package:echurch_desktop/ui/users/users_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSidebarWidget(),
          Expanded(
            child: Column(
              children: [
                const TopHeaderWidget(),
                Expanded(child: _content(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Conteúdo conforme o item da sidebar. A tela de usuários só abre para administrador
  /// (a API também recusa para os demais).
  Widget _content(BuildContext context) {
    final selected = context.watch<DashboardViewModel>().selectedNavItem;
    final isAdmin = context.watch<AuthSessionNotifier>().user?.isAdmin ?? false;

    if (selected == DashboardViewModel.usersNavItem && isAdmin) {
      return UsersBindings(
        screenBuilder: (context) => UsersScreen(viewModel: context.read(), groupsViewModel: context.read()),
      );
    }
    if (selected == DashboardViewModel.prayerRequestsNavItem) {
      return PrayerRequestsBindings(screenBuilder: (context) => PrayerRequestsScreen(viewModel: context.read()));
    }
    return const DashboardScreen();
  }
}

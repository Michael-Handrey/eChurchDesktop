import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/members/member_quick_search_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// O [DashboardViewModel] é compartilhado pelo shell (sidebar, cabeçalho)
/// e pelo conteúdo do dashboard, por isso vive no escopo do MainScreen.
class const MainBindings({
  super.key,
  required final WidgetBuilder screenBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DashboardViewModel()),
        // Busca rápida da barra superior (vale em qualquer tela).
        ChangeNotifierProvider(
          create: (context) => MemberQuickSearchViewModel(repository: context.read(), session: context.read()),
        ),
      ],
      builder: (context, child) => screenBuilder(context),
    );
  }
}

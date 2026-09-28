import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class EChurchApp extends StatelessWidget {
  const EChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Minha Igreja - Gestão de Membros',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

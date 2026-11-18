import 'package:echurch_desktop/config/application_bindings.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/logging/log_output.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  AppLogger.configure(level: kDebugMode ? Level.ALL : Level.INFO, outputs: const [ConsoleLogOutput()]);
  runApp(const ApplicationBindings(child: MainApp()));
}

class const MainApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Minha Igreja - Gestão de Membros',
      theme: AppTheme.light(),
      routerConfig: context.read<GoRouter>(),
      debugShowCheckedModeBanner: false,
    );
  }
}

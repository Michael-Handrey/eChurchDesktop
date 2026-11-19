import 'package:echurch_desktop/config/application_bindings.dart';
import 'package:echurch_desktop/config/environment.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/logging/log_output.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/core/window/app_window.dart';
import 'package:echurch_desktop/ui/core/window/session_window_sizer.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  Environment.ensureSecureTransport();
  AppLogger.configure(level: kDebugMode ? Level.ALL : Level.INFO, outputs: const [ConsoleLogOutput()]);
  WidgetsFlutterBinding.ensureInitialized();
  AppWindow.initialize();
  runApp(const ApplicationBindings(child: MainApp()));
}

class const MainApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppWindow.title,
      theme: AppTheme.light(),
      routerConfig: context.read<GoRouter>(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => SessionWindowSizer(session: context.read(), child: child ?? const SizedBox.shrink()),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'app/dependencies/app_dependencies.dart';

void main() {
  runApp(
    MultiProvider(
      providers: AppDependencies.providers,
      child: const EChurchApp(),
    ),
  );
}

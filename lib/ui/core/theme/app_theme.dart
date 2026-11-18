import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, surface: AppColors.surface);

    return ThemeData(colorScheme: colorScheme, scaffoldBackgroundColor: AppColors.background, fontFamily: 'Inter');
  }
}

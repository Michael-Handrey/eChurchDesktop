import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Raio dos botões. O padrão do Material 3 é a pílula (totalmente arredondado).
  static const buttonRadius = 8.0;

  static const _buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(buttonRadius))),
  );

  static const _buttonStyle = ButtonStyle(shape: _buttonShape);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, surface: AppColors.surface);

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      filledButtonTheme: const FilledButtonThemeData(style: _buttonStyle),
      // Botões das linhas de tabela: mais compactos que o padrão.
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: _buttonShape,
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(style: _buttonStyle),
      elevatedButtonTheme: const ElevatedButtonThemeData(style: _buttonStyle),
      segmentedButtonTheme: const SegmentedButtonThemeData(style: _buttonStyle),
    );
  }
}

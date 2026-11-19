import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Aviso de erro de formulário (anunciado por leitores de tela).
class const AppErrorBanner({super.key, required final String message}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: .35)),
        ),
        child: Row(
          crossAxisAlignment: .start,
          spacing: 10,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            Expanded(
              child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Etiqueta da situação: Novo (roxo), No vaso (azul), Rejeitado (vermelho); Excluído (cinza).
class const PrayerRequestStatusChip({super.key, required final PrayerRequest request}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (request.isExcluded) {
      return const PrayerRequestTag(label: 'Excluído', color: AppColors.textMuted, background: AppColors.surfaceSubtle);
    }
    final (color, background) = switch (request.status) {
      PrayerRequestStatus.newRequest => (AppColors.prayerIcon, AppColors.prayerBg),
      PrayerRequestStatus.inVase => (AppColors.info, AppColors.infoBg),
      PrayerRequestStatus.rejected => (AppColors.error, AppColors.errorBg),
    };
    return PrayerRequestTag(label: PrayerRequestsViewModel.statusLabel(request.status), color: color, background: background);
  }
}

/// Etiqueta pequena (situação, "Comunidade", "Sem igreja").
class const PrayerRequestTag({super.key, required final String label, required final Color color, required final Color background}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

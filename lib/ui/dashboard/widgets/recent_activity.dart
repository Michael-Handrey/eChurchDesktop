import 'package:echurch_desktop/domain/models/dashboard/recent_activity.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class RecentActivitySectionWidget extends StatelessWidget {
  const RecentActivitySectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RecentActivityHeaderWidget(),
          const SizedBox(height: 18),
          // Coluna (e não ListView): poucos itens, e o painel precisa informar a altura natural
          // para o IntrinsicHeight que iguala os dois painéis.
          for (final (index, activity) in viewModel.activities.indexed) ...[
            if (index > 0) const Divider(color: AppColors.borderSubtle, height: 14, thickness: 1),
            RecentActivityItemWidget(activity: activity),
          ],
        ],
      ),
    );
  }
}

class RecentActivityHeaderWidget extends StatelessWidget {
  const RecentActivityHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DashboardLowerPanelsWidget.headerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Últimos Registros',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Ver todos',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivityItemWidget extends StatelessWidget {
  final RecentActivity activity;

  const RecentActivityItemWidget({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final Color iconBgColor;

    switch (activity.type) {
      case ActivityType.member:
        icon = Icons.person;
        iconColor = AppColors.membersIcon;
        iconBgColor = AppColors.membersBg;
        break;
      case ActivityType.child:
        icon = Icons.face_outlined;
        iconColor = AppColors.childrenIcon;
        iconBgColor = AppColors.childrenBg;
        break;
      case ActivityType.prayer:
        icon = Icons.volunteer_activism_outlined;
        iconColor = AppColors.prayerIcon;
        iconBgColor = AppColors.prayerBg;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.typeLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            activity.timeAgo,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class QuickStatsSectionWidget extends StatelessWidget {
  const QuickStatsSectionWidget({super.key});

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
          const QuickStatsHeaderWidget(),
          const SizedBox(height: 18),
          // Cards nas mesmas bordas do banner abaixo; crescem para ocupar a altura do painel.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                for (final stat in viewModel.stats) Expanded(child: StatCounterCardWidget(stat: stat)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const MissionBannerWidget(),
        ],
      ),
    );
  }
}

class QuickStatsHeaderWidget extends StatelessWidget {
  const QuickStatsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DashboardLowerPanelsWidget.headerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Estatísticas Rápidas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Hoje',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCounterCardWidget extends StatelessWidget {
  final QuickStat stat;

  const StatCounterCardWidget({
    super.key,
    required this.stat,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final Color iconBgColor;
    final Color cardBgColor;

    switch (stat.type) {
      case QuickStatType.members:
        icon = Icons.person;
        iconColor = AppColors.membersIcon;
        iconBgColor = AppColors.membersBg;
        cardBgColor = AppColors.membersBg.withValues(alpha: 0.35);
        break;
      case QuickStatType.birthdays:
        icon = Icons.cake_outlined;
        iconColor = AppColors.birthdayIcon;
        iconBgColor = AppColors.birthdayBg;
        cardBgColor = AppColors.birthdayBg.withValues(alpha: 0.35);
        break;
      case QuickStatType.children:
        icon = Icons.face_outlined;
        iconColor = AppColors.childrenIcon;
        iconBgColor = AppColors.childrenBg;
        cardBgColor = AppColors.childrenBg.withValues(alpha: 0.35);
        break;
      case QuickStatType.prayers:
        icon = Icons.volunteer_activism_outlined;
        iconColor = AppColors.prayerIcon;
        iconBgColor = AppColors.prayerBg;
        cardBgColor = AppColors.prayerBg.withValues(alpha: 0.35);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      // Ícone no alto, número e rótulo embaixo: os três cards ficam alinhados mesmo esticados.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stat.count}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              // Espaço de duas linhas em todos os cards: rótulo longo ("Aniversariantes do Dia")
              // quebra sem desalinhar os números entre os cards.
              SizedBox(
                height: 32,
                child: Text(
                  stat.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionBannerWidget extends StatelessWidget {
  const MissionBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.membersBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.membersIcon,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Juntos na missão',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mais do que números, são vidas que precisam de Cristo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

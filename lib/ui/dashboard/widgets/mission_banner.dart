import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Faixa "Juntos na missão" no fim da tela inicial.
class MissionBannerWidget extends StatelessWidget {
  const MissionBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.groups_outlined, color: AppColors.membersIcon, size: 22),
          SizedBox(width: 12),
          Text(
            'Juntos na missão',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mais do que números, são vidas que precisam de Cristo.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

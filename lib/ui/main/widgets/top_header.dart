import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/main/widgets/member_quick_search.dart';
import 'package:echurch_desktop/ui/main/widgets/user_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class TopHeaderWidget extends StatelessWidget {
  const TopHeaderWidget({super.key});

  /// Abaixo desta largura, o usuário aparece só como avatar.
  static const compactWidth = 1000.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      // Tela estreita (notebook com zoom, janela pequena): o usuário vira só o avatar, para a busca caber.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < compactWidth;
          return Row(
            children: [
              const Expanded(child: MemberQuickSearchWidget()),
              SizedBox(width: compact ? 12 : 24),
              const NotificationBadgeWidget(),
              SizedBox(width: compact ? 8 : 20),
              // Largura máxima (o nome corta com "…"); sem Flexible, para não dividir a sobra com a busca
              // e o usuário continuar encostado à direita.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 180 : 280),
                child: const ChurchSelectorWidget(),
              ),
              SizedBox(width: compact ? 8 : 16),
              const SizedBox(height: 32, child: VerticalDivider(color: AppColors.searchBarBorder, width: 1, thickness: 1)),
              SizedBox(width: compact ? 8 : 16),
              UserMenuWidget(compact: compact),
            ],
          );
        },
      ),
    );
  }
}

class NotificationBadgeWidget extends StatelessWidget {
  const NotificationBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      tooltip: 'Notificações',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.textOnPrimary,
            size: 22,
          ),
          Positioned(
            right: 0,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Igreja em uso. Administrador e secretaria da sede escolhem entre sede e filiais; os demais veem a própria igreja.
class ChurchSelectorWidget extends StatelessWidget {
  const ChurchSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final churchContext = context.watch<ChurchContextNotifier>();
    final selected = churchContext.selected;

    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.church_outlined, color: AppColors.textOnPrimaryMuted, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              selected?.name ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (churchContext.canSwitch) ...[
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textOnPrimary, size: 18),
          ],
        ],
      ),
    );

    if (!churchContext.canSwitch) {
      return Tooltip(message: 'Sua igreja', child: label);
    }

    return PopupMenuButton<int>(
      tooltip: 'Trocar a igreja em uso',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: churchContext.select,
      itemBuilder: (context) => [
        for (final church in churchContext.churches)
          CheckedPopupMenuItem(
            value: church.id,
            checked: church.id == selected?.id,
            child: Text(church.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      child: label,
    );
  }
}

import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/main/widgets/user_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class TopHeaderWidget extends StatelessWidget {
  const TopHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: const [
          Expanded(child: SearchInputWidget()),
          SizedBox(width: 24),
          NotificationBadgeWidget(),
          SizedBox(width: 20),
          ChurchSelectorWidget(),
          SizedBox(width: 16),
          SizedBox(height: 32, child: VerticalDivider(color: AppColors.searchBarBorder, width: 1, thickness: 1)),
          SizedBox(width: 16),
          UserMenuWidget(),
        ],
      ),
    );
  }
}

class SearchInputWidget extends StatelessWidget {
  const SearchInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DashboardViewModel>();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.searchBarBackground,
            border: Border.all(color: AppColors.searchBarBorder, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            onChanged: viewModel.setSearchQuery,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 13.5,
            ),
            cursorColor: AppColors.textOnPrimary,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Buscar por nome, CPF, telefone...',
              hintStyle: TextStyle(
                color: AppColors.textOnPrimaryMuted,
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textOnPrimaryMuted,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
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
          Text(
            selected?.name ?? '—',
            style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 14, fontWeight: FontWeight.w500),
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

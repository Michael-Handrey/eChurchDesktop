import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/dashboard_viewmodel.dart';

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

class ChurchSelectorWidget extends StatelessWidget {
  const ChurchSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Sede Rolândia',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textOnPrimary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

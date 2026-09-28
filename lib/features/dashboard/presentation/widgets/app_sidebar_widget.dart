import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class AppSidebarWidget extends StatelessWidget {
  const AppSidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(
          right: BorderSide(
            color: Color(0x26FFFFFF),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SidebarBrandWidget(),
          SizedBox(height: 16),
          Expanded(child: SidebarNavListWidget()),
          SidebarUserProfileWidget(),
        ],
      ),
    );
  }
}

class SidebarBrandWidget extends StatelessWidget {
  const SidebarBrandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.sidebarHover, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.church_outlined,
              color: AppColors.textOnPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'eChurch - IMDF',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gestão Eclesiátisca',
                  style: TextStyle(
                    color: AppColors.textOnPrimaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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

class SidebarNavListWidget extends StatelessWidget {
  const SidebarNavListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        SidebarNavItemWidget(
          icon: Icons.home_outlined,
          label: 'Início',
          isSelected: viewModel.selectedNavItem == 'inicio',
          onTap: () => viewModel.selectNavItem('inicio'),
        ),
        const SizedBox(height: 4),
        SidebarAccordionHeaderWidget(
          icon: Icons.groups_outlined,
          label: 'Secretaria',
          isExpanded: viewModel.isSecretariaExpanded,
          onTap: viewModel.toggleSecretaria,
        ),
        if (viewModel.isSecretariaExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            child: Column(
              children: [
                SidebarSubmenuItemWidget(
                  icon: Icons.person_outline,
                  label: 'Membros',
                  isSelected: viewModel.selectedNavItem == 'membros',
                  onTap: () => viewModel.selectNavItem('membros'),
                ),
                SidebarSubmenuItemWidget(
                  icon: Icons.face_outlined,
                  label: 'Crianças',
                  isSelected: viewModel.selectedNavItem == 'criancas',
                  onTap: () => viewModel.selectNavItem('criancas'),
                ),
                SidebarSubmenuItemWidget(
                  icon: Icons.diversity_3_outlined,
                  label: 'Ministérios',
                  isSelected: viewModel.selectedNavItem == 'ministerios',
                  onTap: () => viewModel.selectNavItem('ministerios'),
                ),
                SidebarSubmenuItemWidget(
                  icon: Icons.calendar_today_outlined,
                  label: 'Eventos',
                  isSelected: viewModel.selectedNavItem == 'eventos',
                  onTap: () => viewModel.selectNavItem('eventos'),
                ),
                SidebarSubmenuItemWidget(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Pedido de Oração',
                  isSelected: viewModel.selectedNavItem == 'oracao',
                  onTap: () => viewModel.selectNavItem('oracao'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        // Módulos Futuros (Feature-first roadmap)
        SidebarNavItemWidget(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Financeiro',
          badgeText: 'Em breve',
          isDisabled: true,
          isSelected: false,
          onTap: () {},
        ),
        SidebarNavItemWidget(
          icon: Icons.menu_book_outlined,
          label: 'Pastoral',
          badgeText: 'Em breve',
          isDisabled: true,
          isSelected: false,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Divider(
            color: AppColors.sidebarHover,
            height: 1,
            thickness: 1,
          ),
        ),
        const SizedBox(height: 8),
        SidebarNavItemWidget(
          icon: Icons.bar_chart_outlined,
          label: 'Relatórios & Documentos',
          isSelected: viewModel.selectedNavItem == 'relatorios',
          onTap: () => viewModel.selectNavItem('relatorios'),
        ),
        SidebarNavItemWidget(
          icon: Icons.settings_outlined,
          label: 'Configurações',
          isSelected: viewModel.selectedNavItem == 'configuracoes',
          onTap: () => viewModel.selectNavItem('configuracoes'),
        ),
      ],
    );
  }
}

class SidebarNavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isDisabled;

  const SidebarNavItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDisabled ? AppColors.textOnPrimaryMuted.withValues(alpha: 0.6) : (isSelected ? AppColors.textOnPrimary : AppColors.textOnPrimaryMuted);

    final iconColor = isDisabled ? AppColors.textOnPrimaryMuted.withValues(alpha: 0.5) : (isSelected ? AppColors.textOnPrimary : AppColors.textOnPrimaryMuted);

    return Material(
      color: isSelected ? AppColors.sidebarActive : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: isDisabled ? Colors.transparent : AppColors.sidebarHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.sidebarHover,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.textOnPrimaryMuted.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      color: AppColors.textOnPrimaryMuted.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarAccordionHeaderWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;

  const SidebarAccordionHeaderWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.sidebarHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textOnPrimary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.textOnPrimaryMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarSubmenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarSubmenuItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.sidebarActive : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.sidebarHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textOnPrimaryMuted,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.textOnPrimary : AppColors.textOnPrimaryMuted,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarUserProfileWidget extends StatelessWidget {
  const SidebarUserProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.sidebarHover, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surface,
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Administrador',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Secretaria',
                  style: TextStyle(
                    color: AppColors.textOnPrimaryMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/login'),
            tooltip: 'Sair',
            icon: const Icon(
              Icons.logout_outlined,
              color: AppColors.textOnPrimaryMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

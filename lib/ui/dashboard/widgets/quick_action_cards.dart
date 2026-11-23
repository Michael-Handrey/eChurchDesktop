import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:echurch_desktop/ui/dashboard/home_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Cards da tela inicial: atalho para a área e o número principal dela (substituem as antigas
/// "Estatísticas Rápidas").
class QuickActionCardsSectionWidget extends StatelessWidget {
  const QuickActionCardsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DashboardViewModel>();
    final home = context.watch<HomeViewModel>();

    // Crianças ainda sem tela: sem ação (e sem cursor de clique).
    return Row(
      spacing: 20,
      children: [
        Expanded(
          child: QuickActionCardWidget(
            icon: Icons.person,
            iconColor: AppColors.membersIcon,
            iconBgColor: AppColors.membersBg,
            title: 'Membros',
            description: 'Cadastre e consulte os membros.',
            stat: home.statOf(QuickStatType.members) ?? const QuickStat(label: 'membros ativos', type: QuickStatType.members),
            onTap: () => viewModel.openFromHome(DashboardViewModel.membersNavItem),
          ),
        ),
        Expanded(
          child: QuickActionCardWidget(
            icon: Icons.face_outlined,
            iconColor: AppColors.childrenIcon,
            iconBgColor: AppColors.childrenBg,
            title: 'Crianças',
            description: 'Crianças e seus responsáveis.',
            stat: home.statOf(QuickStatType.children) ?? const QuickStat(label: 'até 10 anos', type: QuickStatType.children),
          ),
        ),
        Expanded(
          child: QuickActionCardWidget(
            icon: Icons.volunteer_activism_outlined,
            iconColor: AppColors.prayerIcon,
            iconBgColor: AppColors.prayerBg,
            title: 'Pedido de Oração',
            description: 'Registre e acompanhe os pedidos.',
            stat: home.statOf(QuickStatType.prayers) ?? const QuickStat(label: 'novos', type: QuickStatType.prayers),
            onTap: () => viewModel.openFromHome(DashboardViewModel.prayerRequestsNavItem),
          ),
        ),
      ],
    );
  }
}

class QuickActionCardWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;

  /// Uma linha só (cortada com "…" se faltar espaço).
  final String description;
  final QuickStat stat;
  final VoidCallback? onTap;

  const QuickActionCardWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.stat,
    this.onTap,
  });

  @override
  State<QuickActionCardWidget> createState() => _QuickActionCardWidgetState();
}

class _QuickActionCardWidgetState extends State<QuickActionCardWidget> {
  /// Abaixo desta largura (por dentro do card), o número sai da direita e vai para baixo do título.
  static const narrowWidth = 300.0;

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = clickable),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _isHovered ? widget.iconColor.withValues(alpha: 0.5) : AppColors.border, width: 1.2),
            boxShadow: _isHovered ? [BoxShadow(color: widget.iconColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))] : const [],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < narrowWidth ? _narrow() : _wide(),
          ),
        ),
      ),
    );
  }

  /// Card estreito: ícone menor e "248 membros ativos" no lugar da descrição.
  Widget _narrow() {
    final clickable = widget.onTap != null;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: widget.iconBgColor, shape: BoxShape.circle),
          child: Icon(widget.icon, color: widget.iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                spacing: 6,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (clickable) Icon(Icons.arrow_forward, color: _isHovered ? widget.iconColor : AppColors.textMuted, size: 16),
                ],
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.stat.count ?? '—'} ',
                      style: TextStyle(color: widget.iconColor, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: widget.stat.label),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wide() {
    final clickable = widget.onTap != null;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: widget.iconBgColor, shape: BoxShape.circle),
          child: Icon(widget.icon, color: widget.iconColor, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                spacing: 6,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (clickable) Icon(Icons.arrow_forward, color: _isHovered ? widget.iconColor : AppColors.textMuted, size: 16),
                ],
              ),
              Text(
                widget.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Número principal da área, à direita.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${widget.stat.count ?? '—'}',
              style: TextStyle(color: widget.iconColor, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
            ),
            Text(
              widget.stat.label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActionCardsSectionWidget extends StatelessWidget {
  const QuickActionCardsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: QuickActionCardWidget(
            icon: Icons.person,
            iconColor: AppColors.membersIcon,
            iconBgColor: AppColors.membersBg,
            title: 'Membros',
            description: 'Cadastre, edite e consulte\nos membros da igreja.',
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: QuickActionCardWidget(
            icon: Icons.face_outlined,
            iconColor: AppColors.childrenIcon,
            iconBgColor: AppColors.childrenBg,
            title: 'Crianças',
            description: 'Gerencie o cadastro de crianças\ne responsáveis.',
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: QuickActionCardWidget(
            icon: Icons.volunteer_activism_outlined,
            iconColor: AppColors.prayerIcon,
            iconBgColor: AppColors.prayerBg,
            title: 'Pedido de Oração',
            description: 'Registre e acompanhe os pedidos\nde oração da igreja.',
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
  final String description;
  final VoidCallback? onTap;

  const QuickActionCardWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  State<QuickActionCardWidget> createState() => _QuickActionCardWidgetState();
}

class _QuickActionCardWidgetState extends State<QuickActionCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? widget.iconColor.withValues(alpha: 0.5) : AppColors.border,
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: _isHovered ? widget.iconColor : AppColors.textPrimary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:echurch_desktop/domain/models/dashboard/birthday.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_screen.dart';
import 'package:echurch_desktop/ui/dashboard/dashboard_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Aniversariantes de hoje (com a idade que completam) e dos próximos 7 dias.
class BirthdaysSectionWidget extends StatelessWidget {
  const BirthdaysSectionWidget({super.key});

  static const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  static String dayLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${_weekdays[date.weekday - 1]}';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final today = viewModel.birthdaysToday;
    final next = viewModel.birthdaysNext;

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
          SizedBox(
            height: DashboardLowerPanelsWidget.headerHeight,
            child: Row(
              children: [
                const Text(
                  'Aniversariantes',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                if (today.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.birthdayBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      today.length == 1 ? '1 hoje' : '${today.length} hoje',
                      style: const TextStyle(color: AppColors.birthdayIcon, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Ninguém hoje nem nos próximos dias: um aviso só, centralizado (o painel tem a altura dos registros).
          if (today.isEmpty && next.isEmpty)
            const Expanded(child: _NoBirthdays())
          else ...[
            const _SectionLabel('Hoje'),
            if (today.isEmpty) const _Empty('Ninguém faz aniversário hoje.') else for (final birthday in today) _BirthdayItem(birthday: birthday, trailing: '${birthday.age} anos', highlight: true),
            const SizedBox(height: 14),
            const _SectionLabel('Próximos 7 dias'),
            if (next.isEmpty) const _Empty('Nenhum aniversário nos próximos dias.') else for (final birthday in next) _BirthdayItem(birthday: birthday, trailing: dayLabel(birthday.date)),
          ],
        ],
      ),
    );
  }
}

/// Estado vazio: ninguém faz aniversário hoje nem nos próximos 7 dias.
class _NoBirthdays extends StatelessWidget {
  const _NoBirthdays();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.birthdayBg, shape: BoxShape.circle),
            child: const Icon(Icons.cake_outlined, color: AppColors.birthdayIcon, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nenhum aniversário esta semana',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Os próximos aparecem aqui quando estiverem a 7 dias.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
    ),
  );
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
  );
}

class _BirthdayItem extends StatelessWidget {
  final Birthday birthday;
  final String trailing;
  final bool highlight;

  const _BirthdayItem({required this.birthday, required this.trailing, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: highlight ? AppColors.birthdayBg : AppColors.surfaceSubtle, shape: BoxShape.circle),
            child: Icon(
              highlight ? Icons.cake_outlined : (birthday.isChild ? Icons.face_outlined : Icons.person_outline),
              color: highlight ? AppColors.birthdayIcon : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              birthday.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500),
            ),
          ),
          if (birthday.isChild) ...[
            const Text(
              'criança',
              style: TextStyle(color: AppColors.childrenIcon, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
          ],
          Text(trailing, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

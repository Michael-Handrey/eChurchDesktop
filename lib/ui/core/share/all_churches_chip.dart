import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Liga/desliga "Todas as igrejas" nas listas: desligado, a lista é da igreja escolhida no seletor
/// da barra superior; ligado, de todas as igrejas que o usuário alcança. Só aparece para quem
/// alcança mais de uma igreja.
class const AllChurchesChip({super.key, required final bool selected, required final ValueChanged<bool> onChanged}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? 'Voltar para a igreja escolhida na barra superior' : 'Ver as igrejas que você alcança, juntas',
      child: FilterChip(
        avatar: Icon(Icons.church_outlined, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
        showCheckmark: false,
        label: const Text('Todas as igrejas'),
        selected: selected,
        onSelected: onChanged,
        selectedColor: AppColors.primarySubtle,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

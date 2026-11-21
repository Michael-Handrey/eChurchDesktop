import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Etiqueta da situação: Ativo (verde), Inativo (cinza, com o motivo no tooltip).
class const MemberStatusChip({super.key, required final MemberStatus status, final DeactivationReason? reason}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      MemberStatus.active => (AppColors.membersIcon, AppColors.membersBg),
      MemberStatus.inactive => (AppColors.textSecondary, AppColors.surfaceSubtle),
      MemberStatus.other => (AppColors.info, AppColors.infoBg),
    };
    final chip = Container(
      padding: const .symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        MembersViewModel.statusLabel(status),
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
    return switch (reason) {
      final reason? => Tooltip(message: reason.label, child: chip),
      null => chip,
    };
  }
}

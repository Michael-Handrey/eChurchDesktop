import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/ui/account/change_password/change_password_dialog.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

enum _UserAction { changePassword, logout }

/// Usuário logado no canto da barra superior: avatar, nome e perfil, com o menu
/// "Alterar minha senha" e "Sair".
class UserMenuWidget extends StatelessWidget {
  const UserMenuWidget({super.key});

  /// Perfil principal para mostrar sob o nome (o mais amplo que o usuário tiver).
  static String profileOf(AuthSessionUser? user) {
    final roles = user?.roles ?? const [];
    if (roles.contains(AuthSessionUser.adminRole)) return 'Administrador';
    if (roles.contains('ROLE_SECRETARIA')) return 'Secretaria';
    return 'Usuário';
  }

  Future<void> _onSelected(BuildContext context, _UserAction action) async {
    switch (action) {
      case _UserAction.changePassword:
        await ChangePasswordDialog.show(context);
      case _UserAction.logout:
        // O redirect do router leva ao login quando a sessão é encerrada.
        await context.read<AuthSessionNotifier>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSessionNotifier>();
    final user = session.user;

    return PopupMenuButton<_UserAction>(
      tooltip: 'Minha conta',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? '',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
              Text(user?.login ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _UserAction.changePassword,
          child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.key_outlined, size: 20), title: Text('Alterar minha senha')),
        ),
        const PopupMenuItem(
          value: _UserAction.logout,
          child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.logout_outlined, size: 20), title: Text('Sair')),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.surface,
              child: session.initials.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                  : Text(
                      session.initials,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(width: 10),
            // Nome inteiro: a largura acompanha o nome (a busca, à esquerda, é quem cede espaço).
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '',
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                Text(profileOf(user), style: const TextStyle(color: AppColors.textOnPrimaryMuted, fontSize: 11.5)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textOnPrimary, size: 18),
          ],
        ),
      ),
    );
  }
}

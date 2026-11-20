import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/account/change_password/change_password_dialog.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/users/groups_viewmodel.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:echurch_desktop/ui/users/widgets/deactivate_user_dialog.dart';
import 'package:echurch_desktop/ui/users/widgets/delete_group_dialog.dart';
import 'package:echurch_desktop/ui/users/widgets/group_form_dialog.dart';
import 'package:echurch_desktop/ui/users/widgets/groups_table.dart';
import 'package:echurch_desktop/ui/users/widgets/reset_password_dialog.dart';
import 'package:echurch_desktop/ui/users/widgets/temporary_password_dialog.dart';
import 'package:echurch_desktop/ui/users/widgets/user_access_dialog.dart';
import 'package:echurch_desktop/ui/users/widgets/users_table.dart';
import 'package:material_ui/material_ui.dart';

/// Administração de acesso (só administrador), em duas abas:
/// - Usuários: grupos de cada usuário e redefinição de senha provisória;
/// - Grupos e permissões: criar, alterar e excluir grupos.
///
/// Ao trocar de aba, a outra é recarregada: uma mexe nos dados que a outra mostra
/// (nomes de grupo, contagem de usuários).
class const UsersScreen({
  super.key,
  required final UsersViewModel viewModel,
  required final GroupsViewModel groupsViewModel,
}) extends StatefulWidget {
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    _tabs.index == 0 ? widget.viewModel.load.execute() : widget.groupsViewModel.load.execute();
  }

  void _showSaved(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resetPassword(ManagedUser user) async {
    final reset = await ResetPasswordDialog.show(context, viewModel: widget.viewModel, user: user);
    if (reset != null && mounted) {
      await TemporaryPasswordDialog.show(context, userName: user.name, reset: reset);
    }
  }

  Future<void> _editAccess(ManagedUser user) async {
    final saved = await UserAccessDialog.show(context, viewModel: widget.viewModel, user: user);
    if (saved ?? false) _showSaved('Acesso de ${user.name} atualizado.');
  }

  /// Desativar pede confirmação; reativar é direto.
  Future<void> _toggleActive(ManagedUser user) async {
    if (user.active) {
      final deactivated = await DeactivateUserDialog.show(context, viewModel: widget.viewModel, user: user);
      if (deactivated ?? false) _showSaved('${user.name} foi desativado.');
      return;
    }

    final command = widget.viewModel.setActive;
    await command.execute((user: user, active: true));
    final result = command.result;
    command.clearResult();
    switch (result) {
      case Ok<void>():
        _showSaved('${user.name} foi reativado.');
      case Error<void>(:final error):
        _showSaved(ErrorMessages.of(error));
      case null:
        break;
    }
  }

  Future<void> _editGroup([SecurityGroup? group]) async {
    final saved = await GroupFormDialog.show(context, viewModel: widget.groupsViewModel, group: group);
    if (saved ?? false) _showSaved(group == null ? 'Grupo criado.' : 'Grupo atualizado.');
  }

  Future<void> _deleteGroup(SecurityGroup group) async {
    final deleted = await DeleteGroupDialog.show(context, viewModel: widget.groupsViewModel, group: group);
    if (deleted ?? false) _showSaved('Grupo excluído.');
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const .symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 16,
        children: [
          const Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              Text(
                'Usuários',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              Text(
                'Quem acessa o sistema e o que cada um pode fazer.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: .start,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Usuários', iconMargin: .only(bottom: 2)),
              Tab(icon: Icon(Icons.admin_panel_settings_outlined, size: 20), text: 'Grupos e permissões', iconMargin: .only(bottom: 2)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _UsersTab(
                  viewModel: widget.viewModel,
                  onEditAccess: _editAccess,
                  onResetPassword: _resetPassword,
                  onChangeOwnPassword: () => ChangePasswordDialog.show(context),
                  onToggleActive: _toggleActive,
                ),
                _GroupsTab(viewModel: widget.groupsViewModel, onCreate: _editGroup, onEdit: _editGroup, onDelete: _deleteGroup),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const _UsersTab({
  required final UsersViewModel viewModel,
  required final ValueChanged<ManagedUser> onEditAccess,
  required final ValueChanged<ManagedUser> onResetPassword,
  required final VoidCallback onChangeOwnPassword,
  required final ValueChanged<ManagedUser> onToggleActive,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        Row(
          spacing: 8,
          children: [
            const Expanded(
              child: Text(
                '"Acesso" define a igreja e os grupos (permissões); "Desativar" bloqueia o acesso sem apagar o usuário.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: viewModel.setSearch,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar por nome ou login',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => Row(
                mainAxisSize: .min,
                spacing: 8,
                children: [
                  _FilterField<int?>(
                    icon: Icons.church_outlined,
                    options: [for (final option in viewModel.churchFilterOptions) (value: option.churchId, label: option.label)],
                    selected: viewModel.churchFilter,
                    onSelected: viewModel.setChurchFilter,
                  ),
                  _FilterField<GroupFilter>(
                    icon: Icons.filter_list,
                    options: [for (final option in viewModel.groupFilterOptions) (value: option.filter, label: option.label)],
                    selected: viewModel.groupFilter,
                    onSelected: viewModel.setGroupFilter,
                  ),
                ],
              ),
            ),
            _RefreshButton(command: viewModel.load, tooltip: 'Atualizar lista'),
          ],
        ),
        Expanded(
          child: _Loaded(
            command: viewModel.load,
            listenable: viewModel,
            isEmpty: () => viewModel.rows.isEmpty && !viewModel.isFiltering,
            builder: () => UsersTableWidget(
              rows: viewModel.rows,
              onEditAccess: onEditAccess,
              onResetPassword: onResetPassword,
              onChangeOwnPassword: onChangeOwnPassword,
              onToggleActive: onToggleActive,
            ),
          ),
        ),
      ],
    );
  }
}

class const _GroupsTab({
  required final GroupsViewModel viewModel,
  required final VoidCallback onCreate,
  required final ValueChanged<SecurityGroup> onEdit,
  required final ValueChanged<SecurityGroup> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        Row(
          spacing: 8,
          children: [
            const Expanded(
              child: Text(
                'Cada grupo junta permissões. O usuário recebe as permissões de todos os grupos dele.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            _RefreshButton(command: viewModel.load, tooltip: 'Atualizar lista'),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add, size: 18), label: const Text('Novo grupo')),
          ],
        ),
        Expanded(
          child: _Loaded(
            command: viewModel.load,
            listenable: viewModel,
            isEmpty: () => viewModel.rows.isEmpty,
            builder: () => GroupsTableWidget(rows: viewModel.rows, onEdit: onEdit, onDelete: onDelete),
          ),
        ),
      ],
    );
  }
}

/// Lista de opções de filtro, no mesmo visual da busca.
class const _FilterField<T>({
  required final IconData icon,
  required final List<({T value, String label})> options,
  required final T selected,
  required final ValueChanged<T> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const .symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: options.any((option) => option.value == selected) ? selected : options.first.value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(Icons.expand_more, size: 20),
          padding: const .symmetric(vertical: 10),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.value,
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(icon, size: 18, color: AppColors.textSecondary),
                    Flexible(child: Text(option.label, overflow: .ellipsis)),
                  ],
                ),
              ),
          ],
          // Com o tipo anulável (igreja: nulo = todas), o nulo também é uma opção válida.
          onChanged: (value) => onSelected(value as T),
        ),
      ),
    );
  }
}

/// Carregando (primeira vez), erro com "Tentar de novo", ou o conteúdo.
class const _Loaded({
  required final Command0<void> command,
  required final Listenable listenable,
  required final bool Function() isEmpty,
  required final Widget Function() builder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([listenable, command]),
      builder: (context, _) {
        if (command.running && isEmpty()) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (command.result case Error(:final error)) {
          return _LoadError(message: ErrorMessages.of(error), onRetry: command.execute);
        }
        return builder();
      },
    );
  }
}

class const _RefreshButton({required final Command0<void> command, required final String tooltip}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: command,
      builder: (context, _) => IconButton(
        tooltip: tooltip,
        onPressed: command.running ? null : command.execute,
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}

class const _LoadError({required final String message, required final VoidCallback onRetry}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        spacing: 12,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textMuted),
          Text(
            message,
            textAlign: .center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}

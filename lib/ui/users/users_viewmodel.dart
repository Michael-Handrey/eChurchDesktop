import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/church/church_repository.dart';
import 'package:echurch_desktop/data/repositories/group_admin/group_admin_repository.dart';
import 'package:echurch_desktop/data/repositories/user_admin/user_admin_repository.dart';
import 'package:echurch_desktop/domain/models/auth/password_policy.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/users/access_labels.dart';
import 'package:flutter/foundation.dart';

/// Pedido de redefinição: [password] nulo = o sistema gera a senha provisória.
typedef PasswordResetRequestArgs = ({ManagedUser user, String? password});

/// Novos grupos de um usuário.
/// Novo acesso de um usuário: igreja e grupos (só o que mudou é enviado).
typedef UserAccessChange = ({ManagedUser user, int? churchId, Set<int> groupIds});

/// Ativar ou desativar um usuário.
typedef UserActiveChange = ({ManagedUser user, bool active});

/// Filtro por grupo da lista de usuários.
sealed class const GroupFilter() {}

/// Todos os usuários (sem filtro).
final class const AllGroups() extends GroupFilter;

/// Só quem não está em nenhum grupo.
final class const WithoutGroup() extends GroupFilter;

/// Só quem está no grupo [groupId].
final class const InGroup(final int groupId) extends GroupFilter {
  @override
  bool operator ==(Object other) => other is InGroup && other.groupId == groupId;

  @override
  int get hashCode => groupId.hashCode;
}

/// Opção do filtro por grupo, com o texto para a tela.
typedef GroupFilterOption = ({GroupFilter filter, String label});

/// Opção do filtro por igreja: [churchId] nulo = todas.
typedef ChurchFilterOption = ({int? churchId, String label});

/// Linha da tabela de usuários, já pronta para a tela.
typedef UserRowView = ({ManagedUser user, String churchLabel, String groupsLabel, bool isCurrentUser});

/// Opção de grupo no diálogo de grupos do usuário.
typedef GroupOptionView = ({SecurityGroup group, String label, String permissionsLabel});

class UsersViewModel({
  required final UserAdminRepository _userAdminRepository,
  required final GroupAdminRepository _groupAdminRepository,
  required final ChurchRepository _churchRepository,
  required final AuthSessionNotifier _sessionNotifier,
}) extends ChangeNotifier implements ViewModelInitializable {
  final _log = AppLogger('UsersViewModel');

  late final load = Command0<void>(_load);
  late final resetPassword = Command1<PasswordReset, PasswordResetRequestArgs>(_resetPassword);
  late final updateAccess = Command1<void, UserAccessChange>(_updateAccess);
  late final setActive = Command1<void, UserActiveChange>(_setActive);

  List<ManagedUser> _users = const [];
  List<SecurityGroup> _groups = const [];
  List<ChurchSummary> _churches = const [];
  var _search = '';
  GroupFilter _groupFilter = const AllGroups();
  int? _churchFilter;

  String get search => _search;
  GroupFilter get groupFilter => _groupFilter;
  int? get churchFilter => _churchFilter;

  /// Busca ou filtro em uso: a lista vazia significa "nada encontrado", não "sem usuários".
  bool get isFiltering => _search.trim().isNotEmpty || _groupFilter is! AllGroups || _churchFilter != null;

  @override
  void init() => load.execute();

  /// Usuários filtrados pela busca (nome ou login), pelo grupo e pela igreja, em ordem de nome.
  List<UserRowView> get rows {
    final term = _search.trim().toLowerCase();
    final currentLogin = _sessionNotifier.user?.login.toLowerCase();

    bool matchesSearch(ManagedUser user) => term.isEmpty || user.name.toLowerCase().contains(term) || user.login.toLowerCase().contains(term);

    bool matchesGroup(ManagedUser user) => switch (_groupFilter) {
      AllGroups() => true,
      WithoutGroup() => user.groupIds.isEmpty,
      InGroup(:final groupId) => user.groupIds.contains(groupId),
    };

    return [
      for (final user in _users)
        if (matchesSearch(user) && matchesGroup(user) && (_churchFilter == null || user.churchId == _churchFilter))
          (
            user: user,
            churchLabel: user.churchName ?? '—',
            groupsLabel: user.groups.map(AccessLabels.group).join(', '),
            isCurrentUser: user.login.toLowerCase() == currentLogin,
          ),
    ];
  }

  /// Igrejas para escolher no diálogo de acesso (sede primeiro).
  List<ChurchSummary> get churches => _churches;

  /// Grupos disponíveis para dar a um usuário, com as permissões de cada um.
  List<GroupOptionView> get groupOptions => [
    for (final group in _groups)
      (
        group: group,
        label: AccessLabels.group(group.name),
        permissionsLabel: group.permissions.isEmpty ? 'Sem permissões' : group.permissions.map(AccessLabels.permission).join(', '),
      ),
  ];

  /// Opções do filtro: todos, cada grupo e "sem grupo".
  List<GroupFilterOption> get groupFilterOptions => [
    (filter: const AllGroups(), label: 'Todos os grupos'),
    for (final group in _groups) (filter: InGroup(group.id), label: AccessLabels.group(group.name)),
    (filter: const WithoutGroup(), label: 'Sem grupo'),
  ];

  /// Igrejas dos usuários carregados (sede primeiro, depois as filiais em ordem alfabética).
  List<ChurchFilterOption> get churchFilterOptions {
    final churches = <int, String>{
      for (final user in _users) ?user.churchId: user.churchName ?? 'Igreja ${user.churchId}',
    };
    final sorted = churches.entries.toList()
      ..sort((a, b) {
        final aIsHeadquarters = a.value.startsWith('Sede');
        final bIsHeadquarters = b.value.startsWith('Sede');
        if (aIsHeadquarters != bIsHeadquarters) return aIsHeadquarters ? -1 : 1;
        return a.value.toLowerCase().compareTo(b.value.toLowerCase());
      });

    return [
      (churchId: null, label: 'Todas as igrejas'),
      for (final church in sorted) (churchId: church.key, label: church.value),
    ];
  }

  void setChurchFilter(int? churchId) {
    if (churchId == _churchFilter) return;
    _churchFilter = churchId;
    notifyListeners();
  }

  void setGroupFilter(GroupFilter filter) {
    if (filter == _groupFilter) return;
    _groupFilter = filter;
    notifyListeners();
  }

  void setSearch(String value) {
    if (value == _search) return;
    _search = value;
    notifyListeners();
  }

  /// Regras da senha digitada pelo administrador (o login é o do usuário que vai receber a senha).
  List<PasswordRuleCheck> rulesFor(String password, ManagedUser user) => PasswordPolicy.check(password, user.login);

  bool acceptsPassword(String password, ManagedUser user) => PasswordPolicy.accepts(password, user.login);

  /// Usuários, grupos e igrejas juntos: o diálogo de acesso precisa das listas atuais.
  Future<Result<void>> _load() async {
    try {
      final (users, groups, churches) = await (_userAdminRepository.list(), _groupAdminRepository.list(), _churchRepository.list()).wait;

      switch ((users, groups, churches)) {
        case (Ok<List<ManagedUser>>(value: final userList), Ok<List<SecurityGroup>>(value: final groupList), Ok<List<ChurchSummary>>(value: final churchList)):
          _users = userList;
          _groups = groupList;
          _churches = churchList;
          // O grupo do filtro pode ter sido excluído na outra aba.
          if (_groupFilter case InGroup(:final groupId) when !groupList.any((group) => group.id == groupId)) {
            _groupFilter = const AllGroups();
          }
          if (_churchFilter case final churchId? when !userList.any((user) => user.churchId == churchId)) {
            _churchFilter = null;
          }
          return Result.done;
        case (Error<List<ManagedUser>>(:final error), _, _) || (_, Error<List<SecurityGroup>>(:final error), _) || (_, _, Error<List<ChurchSummary>>(:final error)):
          _log.error('Falha ao carregar os usuários', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<PasswordReset>> _resetPassword(PasswordResetRequestArgs args) async {
    final result = await _userAdminRepository.resetPassword(userId: args.user.id, temporaryPassword: args.password);

    switch (result) {
      case Ok<PasswordReset>():
        _log.info('Senha provisória definida para ${args.user.login}');
        // Atualiza a marca de "senha provisória" na tabela sem recarregar tudo.
        _replace(args.user.copyWith(firstAccess: true));
      case Error<PasswordReset>(:final error):
        _log.error('Falha ao redefinir a senha de ${args.user.login}', error: error, stackTrace: error.stackTrace);
    }
    return result;
  }

  /// Envia só o que mudou: primeiro a igreja, depois os grupos. Se a segunda parte falhar,
  /// a primeira já fica valendo (e aparece na lista).
  Future<Result<void>> _updateAccess(UserAccessChange change) async {
    final user = change.user;

    if (change.churchId case final churchId? when churchId != user.churchId) {
      switch (await _userAdminRepository.setChurch(userId: user.id, churchId: churchId)) {
        case Ok<ManagedUser>(:final value):
          _log.info('Igreja de ${user.login} alterada: ${value.churchName}');
          _replace(value);
        case Error<ManagedUser>(:final error):
          _log.error('Falha ao alterar a igreja de ${user.login}', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    }

    final groupsChanged = change.groupIds.length != user.groupIds.length || !change.groupIds.containsAll(user.groupIds);
    if (groupsChanged) {
      switch (await _userAdminRepository.updateGroups(userId: user.id, groupIds: change.groupIds)) {
        case Ok<ManagedUser>(:final value):
          _log.info('Grupos de ${user.login} alterados: ${value.groups}');
          _replace(value);
        case Error<ManagedUser>(:final error):
          _log.error('Falha ao alterar os grupos de ${user.login}', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    }
    return Result.done;
  }

  Future<Result<void>> _setActive(UserActiveChange change) async {
    final result = await _userAdminRepository.setActive(userId: change.user.id, active: change.active);

    switch (result) {
      case Ok<ManagedUser>(:final value):
        _log.info('Usuário ${change.user.login} ${change.active ? 'ativado' : 'desativado'}');
        _replace(value);
        return Result.done;
      case Error<ManagedUser>(:final error):
        _log.error('Falha ao ${change.active ? 'ativar' : 'desativar'} ${change.user.login}', error: error, stackTrace: error.stackTrace);
        return Result.error(error);
    }
  }

  void _replace(ManagedUser updated) {
    _users = [for (final user in _users) user.id == updated.id ? updated : user];
    notifyListeners();
  }

  @override
  void dispose() {
    load.dispose();
    resetPassword.dispose();
    updateAccess.dispose();
    setActive.dispose();
    super.dispose();
  }
}

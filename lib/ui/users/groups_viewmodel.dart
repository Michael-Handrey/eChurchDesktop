import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/group_admin/group_admin_repository.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/ui/users/access_labels.dart';
import 'package:flutter/foundation.dart';

/// Grupo criado ou alterado: [id] nulo cria.
typedef GroupDraft = ({int? id, String name, Set<String> permissions});

/// Linha da tabela de grupos, já pronta para a tela.
typedef GroupRowView = ({SecurityGroup group, String label, List<String> permissionLabels, bool canDelete});

/// Permissão do catálogo, com nome e descrição para a tela.
typedef PermissionOptionView = ({String name, String label, String description});

/// Grupos de acesso e as permissões de cada um (aba "Grupos e permissões").
class GroupsViewModel({required final GroupAdminRepository _groupAdminRepository}) extends ChangeNotifier implements ViewModelInitializable {
  final _log = AppLogger('GroupsViewModel');

  late final load = Command0<void>(_load);
  late final save = Command1<SecurityGroup, GroupDraft>(_save);
  late final delete = Command1<void, SecurityGroup>(_delete);

  List<SecurityGroup> _groups = const [];
  List<String> _permissions = const [];

  @override
  void init() => load.execute();

  List<GroupRowView> get rows => [
    for (final group in _groups)
      (
        group: group,
        label: AccessLabels.group(group.name),
        permissionLabels: group.permissions.map(AccessLabels.permission).toList(),
        // O backend também recusa: tirar os usuários antes deixa claro quem perde acesso.
        canDelete: group.userCount == 0,
      ),
  ];

  List<PermissionOptionView> get permissionOptions => [
    for (final name in _permissions) (name: name, label: AccessLabels.permission(name), description: AccessLabels.permissionDescription(name)),
  ];

  /// O nome não pode ficar vazio nem repetir o de outro grupo (sem diferenciar maiúsculas).
  String? nameProblem(String name, {int? id}) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return 'Informe o nome do grupo.';
    final repeated = _groups.any((group) => group.id != id && group.name.toLowerCase() == clean);
    return repeated ? 'Já existe um grupo com esse nome.' : null;
  }

  Future<Result<void>> _load() async {
    try {
      final (groups, permissions) = await (_groupAdminRepository.list(), _groupAdminRepository.permissions()).wait;

      switch ((groups, permissions)) {
        case (Ok<List<SecurityGroup>>(value: final groupList), Ok<List<String>>(value: final permissionList)):
          _groups = groupList;
          _permissions = permissionList;
          return Result.done;
        case (Error<List<SecurityGroup>>(:final error), _) || (_, Error<List<String>>(:final error)):
          _log.error('Falha ao carregar os grupos', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<SecurityGroup>> _save(GroupDraft draft) async {
    final result = await _groupAdminRepository.save(id: draft.id, name: draft.name.trim(), permissions: draft.permissions);

    switch (result) {
      case Ok<SecurityGroup>(:final value):
        _log.info('Grupo ${draft.id == null ? 'criado' : 'alterado'}: ${value.name} ${value.permissions}');
        final exists = _groups.any((group) => group.id == value.id);
        _groups = exists ? [for (final group in _groups) group.id == value.id ? value : group] : [..._groups, value];
        _groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        notifyListeners();
      case Error<SecurityGroup>(:final error):
        _log.error('Falha ao salvar o grupo ${draft.name}', error: error, stackTrace: error.stackTrace);
    }
    return result;
  }

  Future<Result<void>> _delete(SecurityGroup group) async {
    final result = await _groupAdminRepository.delete(group.id);

    switch (result) {
      case Ok<void>():
        _log.info('Grupo excluído: ${group.name}');
        _groups = [
          for (final other in _groups)
            if (other.id != group.id) other,
        ];
        notifyListeners();
      case Error<void>(:final error):
        _log.error('Falha ao excluir o grupo ${group.name}', error: error, stackTrace: error.stackTrace);
    }
    return result;
  }

  @override
  void dispose() {
    load.dispose();
    save.dispose();
    delete.dispose();
    super.dispose();
  }
}

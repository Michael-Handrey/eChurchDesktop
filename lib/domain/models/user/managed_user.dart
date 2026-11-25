import 'package:equatable/equatable.dart';

/// Usuário do sistema visto pela administração (tela de usuários).
class const ManagedUser({
  required final int id,
  required final String login,
  required final String name,
  required final bool active,

  /// Está com senha provisória: precisa trocar no próximo acesso.
  required final bool firstAccess,

  /// Nomes dos grupos, na mesma ordem de [groupIds].
  final List<String> groups = const [],
  final List<int> groupIds = const [],

  /// Igreja (sede ou filial) do usuário; [churchName] já vem pronto para a tela ("Sede - Rolândia").
  final int? churchId,
  final String? churchName,

  /// Cadastro de membro ligado ao usuário (nulo = sem vínculo): diz de quais ministérios ele é líder.
  final int? personId,
  final String? personName,
}) extends Equatable {
  ManagedUser copyWith({bool? active, bool? firstAccess, List<String>? groups, List<int>? groupIds}) => ManagedUser(
    id: id,
    login: login,
    name: name,
    churchId: churchId,
    churchName: churchName,
    personId: personId,
    personName: personName,
    active: active ?? this.active,
    firstAccess: firstAccess ?? this.firstAccess,
    groups: groups ?? this.groups,
    groupIds: groupIds ?? this.groupIds,
  );

  @override
  List<Object?> get props => [id, login, name, active, firstAccess, groups, groupIds, churchId, churchName, personId, personName];
}

/// Resultado da redefinição: a senha provisória só existe aqui (mostrar uma vez e descartar).
class const PasswordReset({required final String login, required final String temporaryPassword}) extends Equatable {
  @override
  List<Object?> get props => [login, temporaryPassword];

  @override
  bool? get stringify => false;
}

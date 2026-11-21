import 'package:equatable/equatable.dart';

/// Situação do membro. Na lista só existem Ativo e Inativo; as demais vêm dos apelos
/// (ACCEPTED_JESUS...) e aparecem como [other].
enum MemberStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  other('');

  const MemberStatus(this.apiValue);

  /// Valor do enum na API (PersonStatus do backend).
  final String apiValue;

  static MemberStatus fromApi(String? value) => switch (value) {
    'ACTIVE' => active,
    'INACTIVE' => inactive,
    _ => other,
  };
}

/// Motivo da desativação (DeactivationReason do backend). Membros não são excluídos:
/// desativar exige um motivo e uma descrição.
enum DeactivationReason {
  leftChurch('LEFT_CHURCH', 'Saiu da igreja'),
  transferred('TRANSFERRED', 'Transferido para outra igreja'),
  movedAway('MOVED_AWAY', 'Mudou de cidade'),
  deceased('DECEASED', 'Falecimento'),
  duplicate('DUPLICATE', 'Cadastro duplicado'),
  other('OTHER', 'Outro');

  const DeactivationReason(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DeactivationReason? fromApi(String? value) => values.where((reason) => reason.apiValue == value).firstOrNull;
}

/// Linha da lista de membros: só o que qualquer perfil pode ver.
class const MemberRow({
  required final int id,
  required final String name,
  required final MemberStatus status,
  final String? ecclesiasticalRoleName,
  final int? churchId,
  final String? churchName,
  final String? phone,
  final int? birthDay,
  final int? birthMonth,
  final bool credentialPrinted = false,
  final DeactivationReason? deactivationReason,
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, status, ecclesiasticalRoleName, churchId, churchName, phone, birthDay, birthMonth, credentialPrinted, deactivationReason];
}

/// Uma página da lista de membros.
class const MemberPage({required final List<MemberRow> items, required final int total, required final int page, required final int size}) extends Equatable {
  int get pageCount => size == 0 ? 0 : (total / size).ceil();

  @override
  List<Object?> get props => [items, total, page, size];
}

/// Cargo eclesiástico (filtro da lista).
class const EcclesiasticalRoleOption({required final int id, required final String name}) extends Equatable {
  @override
  List<Object?> get props => [id, name];
}

/// Membro completo (`GET /people/{id}`). Para quem só consulta a API manda a versão reduzida:
/// sem documentos, endereço, filiação e histórico; do nascimento, só dia e mês.
class const MemberDetails({
  required final int id,
  required final String name,
  required final MemberStatus status,
  final String? ecclesiasticalRoleName,
  final List<String> ministryNames = const [],
  final String? churchName,
  final DateTime? birthDate,
  final int? birthDay,
  final int? birthMonth,
  final String? gender,
  final String? maritalStatus,
  final String? spouseName,
  final String? fatherName,
  final String? motherName,
  final String? cpf,
  final String? rg,
  final String? phone,
  final String? secondaryPhone,
  final String? email,
  final String? address,
  final DateTime? baptismDate,
  final DateTime? acceptedJesusDate,
  final String? notes,
  final DeactivationReason? deactivationReason,
  final String? deactivationDescription,
  final DateTime? deactivatedAt,
  final String? deactivatedByName,
}) extends Equatable {
  @override
  List<Object?> get props => [
    id,
    name,
    status,
    ecclesiasticalRoleName,
    ministryNames,
    churchName,
    birthDate,
    birthDay,
    birthMonth,
    gender,
    maritalStatus,
    spouseName,
    fatherName,
    motherName,
    cpf,
    rg,
    phone,
    secondaryPhone,
    email,
    address,
    baptismDate,
    acceptedJesusDate,
    notes,
    deactivationReason,
    deactivationDescription,
    deactivatedAt,
    deactivatedByName,
  ];
}

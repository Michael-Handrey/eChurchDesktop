import 'package:equatable/equatable.dart';

/// Ministério da igreja. [type] é o tipo ("Ministério de Jovens"); [name], o nome próprio ("Filhos da Promessa").
/// Desativado ([active] falso): some do formulário do membro; nada é apagado.
/// [canEditMembers]: quem está logado pode incluir e tirar membros (Secretaria/Administrador, ou o líder dele).
class const Ministry({
  required final int id,
  required final String type,
  required final String name,
  final int? churchId,
  final String? churchName,
  final int? leaderId,
  final String? leaderName,
  final int? viceLeaderId,
  final String? viceLeaderName,
  final int memberCount = 0,
  final bool active = true,
  final bool canEditMembers = false,

  /// Faixa de idade (anos completos) do cadastro de Crianças e Adolescentes; nulas = sem faixa.
  final int? minAge,
  final int? maxAge,
}) extends Equatable {
  /// "3 a 10 anos" (nulo sem faixa).
  String? get ageRangeLabel => minAge == null || maxAge == null ? null : '$minAge a $maxAge anos';

  @override
  List<Object?> get props => [id, type, name, churchId, churchName, leaderId, leaderName, viceLeaderId, viceLeaderName, memberCount, active, canEditMembers, minAge, maxAge];
}

/// Membro para incluir no ministério: nome, cargo e igreja.
class const MinistryCandidate({required final int id, required final String name, final String? role, final String? church}) extends Equatable {
  /// "Cargo · Igreja" (o que tiver).
  String? get details => switch ([?role, ?church]) {
    [] => null,
    final parts => parts.join(' · '),
  };

  @override
  List<Object?> get props => [id, name, role, church];
}

/// Dados para cadastrar ou editar. Faixa de idade: as duas ou nenhuma (0 a 17).
typedef MinistryDraft = ({String type, String name, int churchId, int? leaderId, int? viceLeaderId, int? minAge, int? maxAge});

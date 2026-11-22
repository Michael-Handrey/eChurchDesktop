import 'package:equatable/equatable.dart';

/// Ministério da igreja. [type] é o tipo ("Ministério de Jovens"); [name], o nome próprio ("Filhos da Promessa").
/// Desativado ([active] falso): some do formulário do membro; nada é apagado.
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
}) extends Equatable {
  @override
  List<Object?> get props => [id, type, name, churchId, churchName, leaderId, leaderName, viceLeaderId, viceLeaderName, memberCount, active];
}

/// Dados para cadastrar ou editar.
typedef MinistryDraft = ({String type, String name, int churchId, int? leaderId, int? viceLeaderId});

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ministry_api_model.g.dart';

/// Ministério (MinistryDTO): `defaultName` é o tipo ("Ministério de Jovens"); `name`, o nome próprio.
@JsonSerializable(createToJson: false)
class const MinistryApiModel({
  required final int id,
  final String? defaultName,
  final String? name,
  final int? churchId,
  final String? churchName,
  final int? leaderId,
  final String? leaderName,
  final int? viceLeaderId,
  final String? viceLeaderName,
  final int? memberCount,
  final bool? active,
  final bool? canEditMembers,
  final int? minAge,
  final int? maxAge,
}) extends Equatable {
  factory MinistryApiModel.fromJson(Map<String, dynamic> json) => _$MinistryApiModelFromJson(json);

  @override
  List<Object?> get props => [id, defaultName, name, churchId, churchName, leaderId, leaderName, viceLeaderId, viceLeaderName, memberCount, active, canEditMembers, minAge, maxAge];
}

/// Membro para incluir no ministério (MinistryCandidateDTO).
@JsonSerializable(createToJson: false)
class const MinistryCandidateApiModel({required final int id, final String? name, final String? ecclesiasticalRoleName, final String? churchName}) extends Equatable {
  factory MinistryCandidateApiModel.fromJson(Map<String, dynamic> json) => _$MinistryCandidateApiModelFromJson(json);

  @override
  List<Object?> get props => [id, name, ecclesiasticalRoleName, churchName];
}

/// Cadastrar ou editar (MinistryInputDTO).
@JsonSerializable(createFactory: false)
class const MinistryInput({
  required final String defaultName,
  required final String name,
  required final int churchId,
  final int? leaderId,
  final int? viceLeaderId,
  final int? minAge,
  final int? maxAge,
}) extends Equatable {
  Map<String, dynamic> toJson() => _$MinistryInputToJson(this);

  @override
  List<Object?> get props => [defaultName, name, churchId, leaderId, viceLeaderId, minAge, maxAge];
}

@JsonSerializable(createFactory: false)
class const MinistryActiveInput({required final bool active}) extends Equatable {
  Map<String, dynamic> toJson() => _$MinistryActiveInputToJson(this);

  @override
  List<Object?> get props => [active];
}

@JsonSerializable(createFactory: false)
class const MinistryMembersInput({required final List<int> personIds}) extends Equatable {
  Map<String, dynamic> toJson() => _$MinistryMembersInputToJson(this);

  @override
  List<Object?> get props => [personIds];
}

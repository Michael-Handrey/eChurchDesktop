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
}) extends Equatable {
  factory MinistryApiModel.fromJson(Map<String, dynamic> json) => _$MinistryApiModelFromJson(json);

  @override
  List<Object?> get props => [id, defaultName, name, churchId, churchName, leaderId, leaderName, viceLeaderId, viceLeaderName, memberCount, active];
}

/// Cadastrar ou editar (MinistryInputDTO).
@JsonSerializable(createFactory: false)
class const MinistryInput({required final String defaultName, required final String name, required final int churchId, final int? leaderId, final int? viceLeaderId}) extends Equatable {
  Map<String, dynamic> toJson() => _$MinistryInputToJson(this);

  @override
  List<Object?> get props => [defaultName, name, churchId, leaderId, viceLeaderId];
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

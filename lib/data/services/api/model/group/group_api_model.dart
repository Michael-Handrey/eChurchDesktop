import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_api_model.g.dart';

/// Item de `GET /api/v1/groups` (GroupDTO).
@JsonSerializable()
class const GroupApiModel({
  required final int id,
  required final String name,
  final List<String>? permissions,
  final int? userCount,
}) extends Equatable {
  factory GroupApiModel.fromJson(Map<String, dynamic> json) => _$GroupApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupApiModelToJson(this);

  @override
  List<Object?> get props => [id, name, permissions, userCount];
}

/// Corpo de `POST /api/v1/groups` e `PUT /api/v1/groups/{id}` (GroupRequestDTO).
/// [permissions] substitui as permissões atuais do grupo.
@JsonSerializable()
class const GroupRequest({required final String name, required final List<String> permissions}) extends Equatable {
  factory GroupRequest.fromJson(Map<String, dynamic> json) => _$GroupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GroupRequestToJson(this);

  @override
  List<Object?> get props => [name, permissions];
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_person_request.g.dart';

/// Corpo de `PUT /api/v1/users/{id}/person` (UserPersonRequestDTO): [personId] nulo desfaz o vínculo.
@JsonSerializable(includeIfNull: true)
class const UserPersonRequest({final int? personId}) extends Equatable {
  factory UserPersonRequest.fromJson(Map<String, dynamic> json) => _$UserPersonRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserPersonRequestToJson(this);

  @override
  List<Object?> get props => [personId];
}

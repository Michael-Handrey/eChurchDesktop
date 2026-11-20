import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_church_request.g.dart';

/// Corpo de `PUT /api/v1/users/{id}/church` (UserChurchRequestDTO).
@JsonSerializable()
class const UserChurchRequest({required final int churchId}) extends Equatable {
  factory UserChurchRequest.fromJson(Map<String, dynamic> json) => _$UserChurchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserChurchRequestToJson(this);

  @override
  List<Object?> get props => [churchId];
}

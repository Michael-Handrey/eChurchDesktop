import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_active_request.g.dart';

/// Corpo de `PUT /api/v1/users/{id}/active` (UserActiveRequestDTO).
@JsonSerializable()
class const UserActiveRequest({required final bool active}) extends Equatable {
  factory UserActiveRequest.fromJson(Map<String, dynamic> json) => _$UserActiveRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserActiveRequestToJson(this);

  @override
  List<Object?> get props => [active];
}

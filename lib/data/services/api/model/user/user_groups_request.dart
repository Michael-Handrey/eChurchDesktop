import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_groups_request.g.dart';

/// Corpo de `PUT /api/v1/users/{id}/groups` (UserGroupsRequestDTO): substitui os grupos do usuário.
@JsonSerializable()
class const UserGroupsRequest({required final List<int> groupIds}) extends Equatable {
  factory UserGroupsRequest.fromJson(Map<String, dynamic> json) => _$UserGroupsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserGroupsRequestToJson(this);

  @override
  List<Object?> get props => [groupIds];
}

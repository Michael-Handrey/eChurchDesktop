import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_summary_api_model.g.dart';

/// Item de `GET /api/v1/users` (UserSummaryDTO).
@JsonSerializable()
class const UserSummaryApiModel({
  required final int id,
  required final String login,
  final String? name,
  final bool? active,
  final bool? firstAccess,
  final int? churchId,
  final String? churchName,
  final List<String>? groups,
  final List<int>? groupIds,
}) extends Equatable {
  factory UserSummaryApiModel.fromJson(Map<String, dynamic> json) => _$UserSummaryApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserSummaryApiModelToJson(this);

  @override
  List<Object?> get props => [id, login, name, active, firstAccess, churchId, churchName, groups, groupIds];
}

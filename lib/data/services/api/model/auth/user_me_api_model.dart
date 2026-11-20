import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_me_api_model.g.dart';

/// Resposta de `GET /api/v1/auth/me` (UserMeResponseDTO).
@JsonSerializable()
class const UserMeApiModel({
  required final String login,
  required final String name,
  final bool? firstAccess,
  final bool? active,
  final int? churchId,
  final List<String>? roles,
}) extends Equatable {
  factory UserMeApiModel.fromJson(Map<String, dynamic> json) => _$UserMeApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserMeApiModelToJson(this);

  @override
  List<Object?> get props => [login, name, firstAccess, active, churchId, roles];
}

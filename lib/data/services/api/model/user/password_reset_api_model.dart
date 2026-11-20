import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'password_reset_api_model.g.dart';

/// Corpo de `POST /api/v1/users/{id}/reset-password` (PasswordResetRequestDTO).
/// `temporaryPassword` nulo = o backend gera a senha.
@JsonSerializable(includeIfNull: false)
class const PasswordResetRequest({final String? temporaryPassword}) extends Equatable {
  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) => _$PasswordResetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetRequestToJson(this);

  @override
  List<Object?> get props => [temporaryPassword];

  @override
  bool? get stringify => false;
}

/// Resposta da redefinição (PasswordResetResponseDTO).
@JsonSerializable()
class const PasswordResetApiModel({required final String login, required final String temporaryPassword}) extends Equatable {
  factory PasswordResetApiModel.fromJson(Map<String, dynamic> json) => _$PasswordResetApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetApiModelToJson(this);

  @override
  List<Object?> get props => [login, temporaryPassword];

  @override
  bool? get stringify => false;
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_password_request.g.dart';

/// Corpo de `POST /api/v1/auth/change-password` (ChangePasswordRequestDTO: `senhaAtual`, `senhaNova`).
@JsonSerializable()
class const ChangePasswordRequest({
  @JsonKey(name: 'senhaAtual') required final String currentPassword,
  @JsonKey(name: 'senhaNova') required final String newPassword,
}) extends Equatable {
  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) => _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);

  @override
  List<Object?> get props => [currentPassword, newPassword];

  @override
  bool? get stringify => false;
}

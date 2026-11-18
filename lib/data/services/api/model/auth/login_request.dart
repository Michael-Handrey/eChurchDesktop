import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

/// Corpo de `POST /api/v1/auth/login` (LoginRequestDTO: `login`, `senha`).
@JsonSerializable()
class const LoginRequest({
  required final String login,
  @JsonKey(name: 'senha') required final String password,
}) extends Equatable {
  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [login, password];

  @override
  bool? get stringify => false;
}

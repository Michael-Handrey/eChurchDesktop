import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refresh_token_request.g.dart';

/// Corpo de `POST /api/v1/auth/refresh` e `/logout` (RefreshTokenRequestDTO / LogoutRequestDTO).
@JsonSerializable()
class const RefreshTokenRequest({required final String refreshToken}) extends Equatable {
  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);

  @override
  List<Object?> get props => [refreshToken];

  @override
  bool? get stringify => false;
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_api_model.g.dart';

/// Resposta de login/refresh (TokenResponseDTO). Datas de expiração em epoch millis.
@JsonSerializable()
class const TokenApiModel({
  required final String tokenType,
  required final String accessToken,
  required final int accessTokenExpiresAt,
  required final String refreshToken,
  required final int refreshTokenExpiresAt,
  final bool? firstAccess,
}) extends Equatable {
  factory TokenApiModel.fromJson(Map<String, dynamic> json) => _$TokenApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenApiModelToJson(this);

  @override
  List<Object?> get props => [tokenType, accessToken, accessTokenExpiresAt, refreshToken, refreshTokenExpiresAt, firstAccess];

  @override
  bool? get stringify => false;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenApiModel _$TokenApiModelFromJson(Map<String, dynamic> json) =>
    TokenApiModel(
      tokenType: json['tokenType'] as String,
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: (json['accessTokenExpiresAt'] as num).toInt(),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: (json['refreshTokenExpiresAt'] as num).toInt(),
      firstAccess: json['firstAccess'] as bool?,
    );

Map<String, dynamic> _$TokenApiModelToJson(TokenApiModel instance) =>
    <String, dynamic>{
      'tokenType': instance.tokenType,
      'accessToken': instance.accessToken,
      'accessTokenExpiresAt': instance.accessTokenExpiresAt,
      'refreshToken': instance.refreshToken,
      'refreshTokenExpiresAt': instance.refreshTokenExpiresAt,
      'firstAccess': instance.firstAccess,
    };

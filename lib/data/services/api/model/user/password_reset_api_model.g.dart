// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordResetRequest _$PasswordResetRequestFromJson(
  Map<String, dynamic> json,
) => PasswordResetRequest(
  temporaryPassword: json['temporaryPassword'] as String?,
);

Map<String, dynamic> _$PasswordResetRequestToJson(
  PasswordResetRequest instance,
) => <String, dynamic>{'temporaryPassword': ?instance.temporaryPassword};

PasswordResetApiModel _$PasswordResetApiModelFromJson(
  Map<String, dynamic> json,
) => PasswordResetApiModel(
  login: json['login'] as String,
  temporaryPassword: json['temporaryPassword'] as String,
);

Map<String, dynamic> _$PasswordResetApiModelToJson(
  PasswordResetApiModel instance,
) => <String, dynamic>{
  'login': instance.login,
  'temporaryPassword': instance.temporaryPassword,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_local_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessionLocalModel _$AuthSessionLocalModelFromJson(
  Map<String, dynamic> json,
) => AuthSessionLocalModel(
  accessTokenExpiresAt: (json['accessTokenExpiresAt'] as num).toInt(),
  refreshTokenExpiresAt: (json['refreshTokenExpiresAt'] as num).toInt(),
  remember: json['remember'] as bool,
  login: json['login'] as String,
  name: json['name'] as String,
  firstAccess: json['firstAccess'] as bool,
  churchId: (json['churchId'] as num?)?.toInt(),
);

Map<String, dynamic> _$AuthSessionLocalModelToJson(
  AuthSessionLocalModel instance,
) => <String, dynamic>{
  'accessTokenExpiresAt': instance.accessTokenExpiresAt,
  'refreshTokenExpiresAt': instance.refreshTokenExpiresAt,
  'remember': instance.remember,
  'login': instance.login,
  'name': instance.name,
  'firstAccess': instance.firstAccess,
  'churchId': instance.churchId,
};

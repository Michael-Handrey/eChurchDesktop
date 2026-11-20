// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_local_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessionLocalModel _$AuthSessionLocalModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AuthSessionLocalModel', json, ($checkedConvert) {
  final val = AuthSessionLocalModel(
    accessTokenExpiresAt: $checkedConvert(
      'accessTokenExpiresAt',
      (v) => (v as num).toInt(),
    ),
    refreshTokenExpiresAt: $checkedConvert(
      'refreshTokenExpiresAt',
      (v) => (v as num).toInt(),
    ),
    remember: $checkedConvert('remember', (v) => v as bool),
    login: $checkedConvert('login', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    firstAccess: $checkedConvert('firstAccess', (v) => v as bool),
    churchId: $checkedConvert('churchId', (v) => (v as num?)?.toInt()),
    roles: $checkedConvert(
      'roles',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
});

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
  'roles': instance.roles,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_me_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMeApiModel _$UserMeApiModelFromJson(Map<String, dynamic> json) =>
    UserMeApiModel(
      login: json['login'] as String,
      name: json['name'] as String,
      firstAccess: json['firstAccess'] as bool?,
      active: json['active'] as bool?,
      churchId: (json['churchId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserMeApiModelToJson(UserMeApiModel instance) =>
    <String, dynamic>{
      'login': instance.login,
      'name': instance.name,
      'firstAccess': instance.firstAccess,
      'active': instance.active,
      'churchId': instance.churchId,
    };

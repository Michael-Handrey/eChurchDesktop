// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_summary_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSummaryApiModel _$UserSummaryApiModelFromJson(Map<String, dynamic> json) => UserSummaryApiModel(
  id: (json['id'] as num).toInt(),
  login: json['login'] as String,
  name: json['name'] as String?,
  active: json['active'] as bool?,
  firstAccess: json['firstAccess'] as bool?,
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  groups: (json['groups'] as List<dynamic>?)?.map((e) => e as String).toList(),
  groupIds: (json['groupIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  personId: (json['personId'] as num?)?.toInt(),
  personName: json['personName'] as String?,
);

Map<String, dynamic> _$UserSummaryApiModelToJson(
  UserSummaryApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'login': instance.login,
  'name': instance.name,
  'active': instance.active,
  'firstAccess': instance.firstAccess,
  'churchId': instance.churchId,
  'churchName': instance.churchName,
  'groups': instance.groups,
  'groupIds': instance.groupIds,
  'personId': instance.personId,
  'personName': instance.personName,
};

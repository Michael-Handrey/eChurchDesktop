// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupApiModel _$GroupApiModelFromJson(Map<String, dynamic> json) => GroupApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e as String).toList(),
  userCount: (json['userCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$GroupApiModelToJson(GroupApiModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'permissions': instance.permissions,
  'userCount': instance.userCount,
};

GroupRequest _$GroupRequestFromJson(Map<String, dynamic> json) => GroupRequest(
  name: json['name'] as String,
  permissions: (json['permissions'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$GroupRequestToJson(GroupRequest instance) => <String, dynamic>{
  'name': instance.name,
  'permissions': instance.permissions,
};

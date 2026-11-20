// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_groups_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserGroupsRequest _$UserGroupsRequestFromJson(Map<String, dynamic> json) => UserGroupsRequest(
  groupIds: (json['groupIds'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
);

Map<String, dynamic> _$UserGroupsRequestToJson(UserGroupsRequest instance) => <String, dynamic>{'groupIds': instance.groupIds};

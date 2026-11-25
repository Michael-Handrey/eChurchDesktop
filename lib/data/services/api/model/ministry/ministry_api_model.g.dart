// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ministry_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MinistryApiModel _$MinistryApiModelFromJson(Map<String, dynamic> json) => MinistryApiModel(
  id: (json['id'] as num).toInt(),
  defaultName: json['defaultName'] as String?,
  name: json['name'] as String?,
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  leaderId: (json['leaderId'] as num?)?.toInt(),
  leaderName: json['leaderName'] as String?,
  viceLeaderId: (json['viceLeaderId'] as num?)?.toInt(),
  viceLeaderName: json['viceLeaderName'] as String?,
  memberCount: (json['memberCount'] as num?)?.toInt(),
  active: json['active'] as bool?,
  canEditMembers: json['canEditMembers'] as bool?,
);

MinistryCandidateApiModel _$MinistryCandidateApiModelFromJson(
  Map<String, dynamic> json,
) => MinistryCandidateApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  ecclesiasticalRoleName: json['ecclesiasticalRoleName'] as String?,
  churchName: json['churchName'] as String?,
);

Map<String, dynamic> _$MinistryInputToJson(MinistryInput instance) => <String, dynamic>{
  'stringify': instance.stringify,
  'defaultName': instance.defaultName,
  'name': instance.name,
  'churchId': instance.churchId,
  'leaderId': instance.leaderId,
  'viceLeaderId': instance.viceLeaderId,
  'props': instance.props,
};

Map<String, dynamic> _$MinistryActiveInputToJson(
  MinistryActiveInput instance,
) => <String, dynamic>{
  'stringify': instance.stringify,
  'active': instance.active,
  'props': instance.props,
};

Map<String, dynamic> _$MinistryMembersInputToJson(
  MinistryMembersInput instance,
) => <String, dynamic>{
  'stringify': instance.stringify,
  'personIds': instance.personIds,
  'props': instance.props,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_request_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrayerRequestApiModel _$PrayerRequestApiModelFromJson(
  Map<String, dynamic> json,
) => PrayerRequestApiModel(
  id: (json['id'] as num).toInt(),
  requesterName: json['requesterName'] as String?,
  description: json['description'] as String?,
  requestDate: json['requestDate'] as String?,
  status: json['status'] as String?,
  fromCommunity: json['fromCommunity'] as bool?,
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  createdByName: json['createdByName'] as String?,
  createdAt: json['createdAt'] as String?,
  printedAt: json['printedAt'] as String?,
  rejectedAt: json['rejectedAt'] as String?,
  rejectedByName: json['rejectedByName'] as String?,
  rejectionReason: json['rejectionReason'] as String?,
  excludedAt: json['excludedAt'] as String?,
  excludedByName: json['excludedByName'] as String?,
  actions: (json['actions'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$PrayerRequestApiModelToJson(
  PrayerRequestApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'requesterName': instance.requesterName,
  'description': instance.description,
  'requestDate': instance.requestDate,
  'status': instance.status,
  'fromCommunity': instance.fromCommunity,
  'churchId': instance.churchId,
  'churchName': instance.churchName,
  'createdByName': instance.createdByName,
  'createdAt': instance.createdAt,
  'printedAt': instance.printedAt,
  'rejectedAt': instance.rejectedAt,
  'rejectedByName': instance.rejectedByName,
  'rejectionReason': instance.rejectionReason,
  'excludedAt': instance.excludedAt,
  'excludedByName': instance.excludedByName,
  'actions': instance.actions,
};

PrayerRequestPageApiModel _$PrayerRequestPageApiModelFromJson(
  Map<String, dynamic> json,
) => PrayerRequestPageApiModel(
  items: (json['items'] as List<dynamic>).map((e) => PrayerRequestApiModel.fromJson(e as Map<String, dynamic>)).toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  size: (json['size'] as num).toInt(),
);

Map<String, dynamic> _$PrayerRequestPageApiModelToJson(
  PrayerRequestPageApiModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'page': instance.page,
  'size': instance.size,
};

PrayerRequestInput _$PrayerRequestInputFromJson(Map<String, dynamic> json) => PrayerRequestInput(
  requesterName: json['requesterName'] as String,
  description: json['description'] as String,
  requestDate: json['requestDate'] as String?,
  churchId: (json['churchId'] as num?)?.toInt(),
);

Map<String, dynamic> _$PrayerRequestInputToJson(PrayerRequestInput instance) => <String, dynamic>{
  'requesterName': instance.requesterName,
  'description': instance.description,
  'requestDate': ?instance.requestDate,
  'churchId': ?instance.churchId,
};

PrayerRequestIds _$PrayerRequestIdsFromJson(Map<String, dynamic> json) => PrayerRequestIds(
  ids: (json['ids'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
);

Map<String, dynamic> _$PrayerRequestIdsToJson(PrayerRequestIds instance) => <String, dynamic>{'ids': instance.ids};

PrayerRequestChurch _$PrayerRequestChurchFromJson(Map<String, dynamic> json) => PrayerRequestChurch(churchId: (json['churchId'] as num?)?.toInt());

Map<String, dynamic> _$PrayerRequestChurchToJson(
  PrayerRequestChurch instance,
) => <String, dynamic>{'churchId': ?instance.churchId};

PrayerRequestReject _$PrayerRequestRejectFromJson(Map<String, dynamic> json) => PrayerRequestReject(reason: json['reason'] as String?);

Map<String, dynamic> _$PrayerRequestRejectToJson(
  PrayerRequestReject instance,
) => <String, dynamic>{'reason': ?instance.reason};

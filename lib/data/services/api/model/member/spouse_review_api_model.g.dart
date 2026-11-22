// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spouse_review_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpousePersonApiModel _$SpousePersonApiModelFromJson(
  Map<String, dynamic> json,
) => SpousePersonApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  writtenSpouse: json['writtenSpouse'] as String?,
  maritalStatus: json['maritalStatus'] as String?,
  status: json['status'] as String?,
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  address: json['address'] as String?,
);

SpouseSuggestionApiModel _$SpouseSuggestionApiModelFromJson(
  Map<String, dynamic> json,
) => SpouseSuggestionApiModel(
  confidence: json['confidence'] as String,
  kind: json['kind'] as String,
  person: SpousePersonApiModel.fromJson(json['person'] as Map<String, dynamic>),
  candidate: SpousePersonApiModel.fromJson(
    json['candidate'] as Map<String, dynamic>,
  ),
  sameAddress: json['sameAddress'] as bool?,
  notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

SpouseReviewApiModel _$SpouseReviewApiModelFromJson(
  Map<String, dynamic> json,
) => SpouseReviewApiModel(
  suggestions: (json['suggestions'] as List<dynamic>?)?.map((e) => SpouseSuggestionApiModel.fromJson(e as Map<String, dynamic>)).toList(),
  withoutSuggestion: (json['withoutSuggestion'] as List<dynamic>?)?.map((e) => SpousePersonApiModel.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$SpouseLinkInputToJson(SpouseLinkInput instance) => <String, dynamic>{
  'stringify': ?instance.stringify,
  'personId': instance.personId,
  'spouseId': instance.spouseId,
  'addressFrom': ?instance.addressFrom,
  'props': instance.props,
};

Map<String, dynamic> _$SpouseLinkBatchInputToJson(
  SpouseLinkBatchInput instance,
) => <String, dynamic>{
  'stringify': instance.stringify,
  'links': instance.links.map((e) => e.toJson()).toList(),
  'props': instance.props,
};

Map<String, dynamic> _$SpouseDismissInputToJson(SpouseDismissInput instance) => <String, dynamic>{
  'stringify': instance.stringify,
  'personId': instance.personId,
  'candidateId': instance.candidateId,
  'props': instance.props,
};

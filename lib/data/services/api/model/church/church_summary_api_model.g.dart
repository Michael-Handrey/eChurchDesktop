// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church_summary_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChurchSummaryApiModel _$ChurchSummaryApiModelFromJson(
  Map<String, dynamic> json,
) => ChurchSummaryApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  headquarters: json['headquarters'] as bool?,
);

Map<String, dynamic> _$ChurchSummaryApiModelToJson(
  ChurchSummaryApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'headquarters': instance.headquarters,
};

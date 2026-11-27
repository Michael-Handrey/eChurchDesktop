// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChildRowApiModel _$ChildRowApiModelFromJson(Map<String, dynamic> json) => ChildRowApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  birthDate: json['birthDate'] as String?,
  age: (json['age'] as num?)?.toInt(),
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  ministryId: (json['ministryId'] as num?)?.toInt(),
  ministryName: json['ministryName'] as String?,
  guardians: json['guardians'] as String?,
  active: json['active'] as bool?,
);

ChildPageApiModel _$ChildPageApiModelFromJson(Map<String, dynamic> json) => ChildPageApiModel(
  items: (json['items'] as List<dynamic>?)?.map((e) => ChildRowApiModel.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
  total: (json['total'] as num?)?.toInt() ?? 0,
  page: (json['page'] as num?)?.toInt() ?? 0,
  size: (json['size'] as num?)?.toInt() ?? 20,
);

GuardianApiModel _$GuardianApiModelFromJson(Map<String, dynamic> json) => GuardianApiModel(
  personId: (json['personId'] as num).toInt(),
  name: json['name'] as String?,
  kinship: json['kinship'] as String?,
  phone: json['phone'] as String?,
  churchName: json['churchName'] as String?,
);

ChildApiModel _$ChildApiModelFromJson(Map<String, dynamic> json) => ChildApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  birthDate: json['birthDate'] as String?,
  age: (json['age'] as num?)?.toInt(),
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  ministryId: (json['ministryId'] as num?)?.toInt(),
  ministryName: json['ministryName'] as String?,
  notes: json['notes'] as String?,
  active: json['active'] as bool?,
  guardians: (json['guardians'] as List<dynamic>?)?.map((e) => GuardianApiModel.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
);

Map<String, dynamic> _$GuardianInputToJson(GuardianInput instance) => <String, dynamic>{
  'stringify': instance.stringify,
  'personId': instance.personId,
  'kinship': instance.kinship,
  'props': instance.props,
};

Map<String, dynamic> _$ChildInputToJson(ChildInput instance) => <String, dynamic>{
  'stringify': instance.stringify,
  'name': instance.name,
  'birthDate': instance.birthDate,
  'churchId': instance.churchId,
  'ministryId': instance.ministryId,
  'notes': instance.notes,
  'guardians': instance.guardians.map((e) => e.toJson()).toList(),
  'props': instance.props,
};

Map<String, dynamic> _$ChildActiveInputToJson(ChildActiveInput instance) => <String, dynamic>{
  'stringify': instance.stringify,
  'active': instance.active,
  'props': instance.props,
};

GuardianOptionApiModel _$GuardianOptionApiModelFromJson(
  Map<String, dynamic> json,
) => GuardianOptionApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  churchName: json['churchName'] as String?,
  gender: json['gender'] as String?,
  spouseId: (json['spouseId'] as num?)?.toInt(),
  spouseName: json['spouseName'] as String?,
  spouseGender: json['spouseGender'] as String?,
);

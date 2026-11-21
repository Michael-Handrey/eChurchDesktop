// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberRowApiModel _$MemberRowApiModelFromJson(Map<String, dynamic> json) => MemberRowApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  status: json['status'] as String?,
  ecclesiasticalRoleName: json['ecclesiasticalRoleName'] as String?,
  churchId: (json['churchId'] as num?)?.toInt(),
  churchName: json['churchName'] as String?,
  phone: json['phone'] as String?,
  birthDay: (json['birthDay'] as num?)?.toInt(),
  birthMonth: (json['birthMonth'] as num?)?.toInt(),
  credentialPrinted: json['credentialPrinted'] as bool?,
  deactivationReason: json['deactivationReason'] as String?,
);

Map<String, dynamic> _$MemberRowApiModelToJson(MemberRowApiModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'status': instance.status,
  'ecclesiasticalRoleName': instance.ecclesiasticalRoleName,
  'churchId': instance.churchId,
  'churchName': instance.churchName,
  'phone': instance.phone,
  'birthDay': instance.birthDay,
  'birthMonth': instance.birthMonth,
  'credentialPrinted': instance.credentialPrinted,
  'deactivationReason': instance.deactivationReason,
};

MemberPageApiModel _$MemberPageApiModelFromJson(Map<String, dynamic> json) => MemberPageApiModel(
  items: (json['items'] as List<dynamic>).map((e) => MemberRowApiModel.fromJson(e as Map<String, dynamic>)).toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  size: (json['size'] as num).toInt(),
);

Map<String, dynamic> _$MemberPageApiModelToJson(MemberPageApiModel instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'page': instance.page,
  'size': instance.size,
};

MemberAddressApiModel _$MemberAddressApiModelFromJson(
  Map<String, dynamic> json,
) => MemberAddressApiModel(
  streetType: json['streetType'] as String?,
  streetName: json['streetName'] as String?,
  streetNumber: json['streetNumber'] as String?,
  complement: json['complement'] as String?,
  postalCode: json['postalCode'] as String?,
  districtName: json['districtName'] as String?,
  cityName: json['cityName'] as String?,
  stateAbbreviation: json['stateAbbreviation'] as String?,
);

Map<String, dynamic> _$MemberAddressApiModelToJson(
  MemberAddressApiModel instance,
) => <String, dynamic>{
  'streetType': instance.streetType,
  'streetName': instance.streetName,
  'streetNumber': instance.streetNumber,
  'complement': instance.complement,
  'postalCode': instance.postalCode,
  'districtName': instance.districtName,
  'cityName': instance.cityName,
  'stateAbbreviation': instance.stateAbbreviation,
};

MemberContactApiModel _$MemberContactApiModelFromJson(
  Map<String, dynamic> json,
) => MemberContactApiModel(
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  secondaryPhone: json['secondaryPhone'] as String?,
);

Map<String, dynamic> _$MemberContactApiModelToJson(
  MemberContactApiModel instance,
) => <String, dynamic>{
  'email': instance.email,
  'phone': instance.phone,
  'secondaryPhone': instance.secondaryPhone,
};

MemberDetailsApiModel _$MemberDetailsApiModelFromJson(
  Map<String, dynamic> json,
) => MemberDetailsApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  status: json['status'] as String?,
  ecclesiasticalRoleName: json['ecclesiasticalRoleName'] as String?,
  ministryNames: (json['ministryNames'] as List<dynamic>?)?.map((e) => e as String).toList(),
  churchName: json['churchName'] as String?,
  birthDate: json['birthDate'] as String?,
  birthDay: (json['birthDay'] as num?)?.toInt(),
  birthMonth: (json['birthMonth'] as num?)?.toInt(),
  gender: json['gender'] as String?,
  maritalStatus: json['maritalStatus'] as String?,
  spouseName: json['spouseName'] as String?,
  fatherName: json['fatherName'] as String?,
  motherName: json['motherName'] as String?,
  cpf: json['cpf'] as String?,
  rg: json['rg'] as String?,
  contact: json['contact'] == null ? null : MemberContactApiModel.fromJson(json['contact'] as Map<String, dynamic>),
  address: json['address'] == null ? null : MemberAddressApiModel.fromJson(json['address'] as Map<String, dynamic>),
  phone: json['phone'] as String?,
  secondaryPhone: json['secondaryPhone'] as String?,
  email: json['email'] as String?,
  baptismDate: json['baptismDate'] as String?,
  acceptedJesusDate: json['acceptedJesusDate'] as String?,
  notes: json['notes'] as String?,
  deactivationReason: json['deactivationReason'] as String?,
  deactivationDescription: json['deactivationDescription'] as String?,
  deactivatedAt: json['deactivatedAt'] as String?,
  deactivatedByName: json['deactivatedByName'] as String?,
);

Map<String, dynamic> _$MemberDetailsApiModelToJson(
  MemberDetailsApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'status': instance.status,
  'ecclesiasticalRoleName': instance.ecclesiasticalRoleName,
  'ministryNames': instance.ministryNames,
  'churchName': instance.churchName,
  'birthDate': instance.birthDate,
  'birthDay': instance.birthDay,
  'birthMonth': instance.birthMonth,
  'gender': instance.gender,
  'maritalStatus': instance.maritalStatus,
  'spouseName': instance.spouseName,
  'fatherName': instance.fatherName,
  'motherName': instance.motherName,
  'cpf': instance.cpf,
  'rg': instance.rg,
  'contact': instance.contact?.toJson(),
  'address': instance.address?.toJson(),
  'phone': instance.phone,
  'secondaryPhone': instance.secondaryPhone,
  'email': instance.email,
  'baptismDate': instance.baptismDate,
  'acceptedJesusDate': instance.acceptedJesusDate,
  'notes': instance.notes,
  'deactivationReason': instance.deactivationReason,
  'deactivationDescription': instance.deactivationDescription,
  'deactivatedAt': instance.deactivatedAt,
  'deactivatedByName': instance.deactivatedByName,
};

MemberOptionApiModel _$MemberOptionApiModelFromJson(
  Map<String, dynamic> json,
) => MemberOptionApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$MemberOptionApiModelToJson(
  MemberOptionApiModel instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

MemberOptionsApiModel _$MemberOptionsApiModelFromJson(
  Map<String, dynamic> json,
) => MemberOptionsApiModel(
  ecclesiasticalRoles: (json['cargosEclesiasticos'] as List<dynamic>?)?.map((e) => MemberOptionApiModel.fromJson(e as Map<String, dynamic>)).toList(),
);

MemberDeactivationInput _$MemberDeactivationInputFromJson(
  Map<String, dynamic> json,
) => MemberDeactivationInput(
  reason: json['reason'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$MemberDeactivationInputToJson(
  MemberDeactivationInput instance,
) => <String, dynamic>{
  'reason': instance.reason,
  'description': instance.description,
};

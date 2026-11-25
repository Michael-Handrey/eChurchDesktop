// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_form_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberEditAddressApiModel _$MemberEditAddressApiModelFromJson(
  Map<String, dynamic> json,
) => MemberEditAddressApiModel(
  id: (json['id'] as num?)?.toInt(),
  streetType: json['streetType'] as String?,
  streetName: json['streetName'] as String?,
  streetNumber: json['streetNumber'] as String?,
  complement: json['complement'] as String?,
  postalCode: json['postalCode'] as String?,
  district: (json['district'] as num?)?.toInt(),
  districtName: json['districtName'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  cityName: json['cityName'] as String?,
  stateAbbreviation: json['stateAbbreviation'] as String?,
);

Map<String, dynamic> _$MemberEditAddressApiModelToJson(
  MemberEditAddressApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'streetType': instance.streetType,
  'streetName': instance.streetName,
  'streetNumber': instance.streetNumber,
  'complement': instance.complement,
  'postalCode': instance.postalCode,
  'district': instance.district,
  'districtName': instance.districtName,
  'cityId': instance.cityId,
  'cityName': instance.cityName,
  'stateAbbreviation': instance.stateAbbreviation,
};

MemberContactInput _$MemberContactInputFromJson(Map<String, dynamic> json) => MemberContactInput(
  id: (json['id'] as num?)?.toInt(),
  email: json['email'] as String?,
  facebook: json['facebook'] as String?,
  twitter: json['twitter'] as String?,
  instagram: json['instagram'] as String?,
  phone: json['phone'] as String?,
  secondaryPhone: json['secondaryPhone'] as String?,
);

Map<String, dynamic> _$MemberContactInputToJson(MemberContactInput instance) => <String, dynamic>{
  'id': ?instance.id,
  'email': ?instance.email,
  'facebook': ?instance.facebook,
  'twitter': ?instance.twitter,
  'instagram': ?instance.instagram,
  'phone': ?instance.phone,
  'secondaryPhone': ?instance.secondaryPhone,
};

MemberEditApiModel _$MemberEditApiModelFromJson(Map<String, dynamic> json) => MemberEditApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  birthDate: json['birthDate'] as String?,
  cpf: json['cpf'] as String?,
  rg: json['rg'] as String?,
  gender: json['gender'] as String?,
  fatherName: json['fatherName'] as String?,
  motherName: json['motherName'] as String?,
  maritalStatus: json['maritalStatus'] as String?,
  spouseName: json['spouseName'] as String?,
  spouseId: (json['spouseId'] as num?)?.toInt(),
  birthCityId: (json['birthCityId'] as num?)?.toInt(),
  birthCityName: json['birthCityName'] as String?,
  birthCityState: json['birthCityState'] as String?,
  nationality: json['nationality'] as String?,
  professionId: (json['professionId'] as num?)?.toInt(),
  professionName: json['professionName'] as String?,
  address: json['address'] == null
      ? null
      : MemberEditAddressApiModel.fromJson(
          json['address'] as Map<String, dynamic>,
        ),
  contact: json['contact'] == null
      ? null
      : MemberContactInput.fromJson(
          json['contact'] as Map<String, dynamic>,
        ),
  notes: json['notes'] as String?,
  status: json['status'] as String?,
  ecclesiasticalRoleId: (json['ecclesiasticalRoleId'] as num?)?.toInt(),
  ministryIds: (json['ministryIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  ministerialRoleIds: (json['ministerialRoleIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  leaderships: (json['leaderships'] as List<dynamic>?)?.map((e) => e as String).toList(),
  churchId: (json['churchId'] as num?)?.toInt(),
  deathDate: json['deathDate'] as String?,
  acceptedJesusDate: json['acceptedJesusDate'] as String?,
  baptismDate: json['baptismDate'] as String?,
  individualType: json['individualType'] as String?,
  ecclesiasticalRoleName: json['ecclesiasticalRoleName'] as String?,
  churchName: json['churchName'] as String?,
  ministryNames: (json['ministryNames'] as List<dynamic>?)?.map((e) => e as String).toList(),
  credentialPrinted: json['credentialPrinted'] as bool?,
);

Map<String, dynamic> _$MemberEditApiModelToJson(MemberEditApiModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'birthDate': instance.birthDate,
  'cpf': instance.cpf,
  'rg': instance.rg,
  'gender': instance.gender,
  'fatherName': instance.fatherName,
  'motherName': instance.motherName,
  'maritalStatus': instance.maritalStatus,
  'spouseName': instance.spouseName,
  'spouseId': instance.spouseId,
  'birthCityId': instance.birthCityId,
  'birthCityName': instance.birthCityName,
  'birthCityState': instance.birthCityState,
  'nationality': instance.nationality,
  'professionId': instance.professionId,
  'professionName': instance.professionName,
  'address': instance.address?.toJson(),
  'contact': instance.contact?.toJson(),
  'notes': instance.notes,
  'status': instance.status,
  'ecclesiasticalRoleId': instance.ecclesiasticalRoleId,
  'ministryIds': instance.ministryIds,
  'ministerialRoleIds': instance.ministerialRoleIds,
  'leaderships': instance.leaderships,
  'churchId': instance.churchId,
  'deathDate': instance.deathDate,
  'acceptedJesusDate': instance.acceptedJesusDate,
  'baptismDate': instance.baptismDate,
  'individualType': instance.individualType,
  'ecclesiasticalRoleName': instance.ecclesiasticalRoleName,
  'churchName': instance.churchName,
  'ministryNames': instance.ministryNames,
  'credentialPrinted': instance.credentialPrinted,
};

MemberAddressInput _$MemberAddressInputFromJson(Map<String, dynamic> json) => MemberAddressInput(
  id: (json['id'] as num?)?.toInt(),
  streetType: json['streetType'] as String?,
  streetName: json['streetName'] as String?,
  streetNumber: json['streetNumber'] as String?,
  complement: json['complement'] as String?,
  postalCode: json['postalCode'] as String?,
  district: (json['district'] as num?)?.toInt(),
);

Map<String, dynamic> _$MemberAddressInputToJson(MemberAddressInput instance) => <String, dynamic>{
  'id': ?instance.id,
  'streetType': ?instance.streetType,
  'streetName': ?instance.streetName,
  'streetNumber': ?instance.streetNumber,
  'complement': ?instance.complement,
  'postalCode': ?instance.postalCode,
  'district': ?instance.district,
};

MemberInput _$MemberInputFromJson(Map<String, dynamic> json) => MemberInput(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  birthDate: json['birthDate'] as String?,
  cpf: json['cpf'] as String?,
  rg: json['rg'] as String?,
  gender: json['gender'] as String?,
  fatherName: json['fatherName'] as String?,
  motherName: json['motherName'] as String?,
  maritalStatus: json['maritalStatus'] as String?,
  spouseName: json['spouseName'] as String?,
  spouseId: (json['spouseId'] as num?)?.toInt(),
  birthCityId: (json['birthCityId'] as num?)?.toInt(),
  nationality: json['nationality'] as String?,
  professionId: (json['professionId'] as num?)?.toInt(),
  address: json['address'] == null ? null : MemberAddressInput.fromJson(json['address'] as Map<String, dynamic>),
  contact: json['contact'] == null ? null : MemberContactInput.fromJson(json['contact'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  status: json['status'] as String?,
  ecclesiasticalRoleId: (json['ecclesiasticalRoleId'] as num?)?.toInt(),
  ministryIds: (json['ministryIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  ministerialRoleIds: (json['ministerialRoleIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  churchId: (json['churchId'] as num?)?.toInt(),
  deathDate: json['deathDate'] as String?,
  acceptedJesusDate: json['acceptedJesusDate'] as String?,
  baptismDate: json['baptismDate'] as String?,
  individualType: json['individualType'] as String?,
);

Map<String, dynamic> _$MemberInputToJson(MemberInput instance) => <String, dynamic>{
  'id': ?instance.id,
  'name': ?instance.name,
  'birthDate': ?instance.birthDate,
  'cpf': ?instance.cpf,
  'rg': ?instance.rg,
  'gender': ?instance.gender,
  'fatherName': ?instance.fatherName,
  'motherName': ?instance.motherName,
  'maritalStatus': ?instance.maritalStatus,
  'spouseName': ?instance.spouseName,
  'spouseId': ?instance.spouseId,
  'birthCityId': ?instance.birthCityId,
  'nationality': ?instance.nationality,
  'professionId': ?instance.professionId,
  'address': ?instance.address?.toJson(),
  'contact': ?instance.contact?.toJson(),
  'notes': ?instance.notes,
  'status': ?instance.status,
  'ecclesiasticalRoleId': ?instance.ecclesiasticalRoleId,
  'ministryIds': ?instance.ministryIds,
  'ministerialRoleIds': ?instance.ministerialRoleIds,
  'churchId': ?instance.churchId,
  'deathDate': ?instance.deathDate,
  'acceptedJesusDate': ?instance.acceptedJesusDate,
  'baptismDate': ?instance.baptismDate,
  'individualType': ?instance.individualType,
};

NationalityApiModel _$NationalityApiModelFromJson(Map<String, dynamic> json) => NationalityApiModel(
  value: json['value'] as String,
  label: json['label'] as String?,
);

Map<String, dynamic> _$NationalityApiModelToJson(
  NationalityApiModel instance,
) => <String, dynamic>{'value': instance.value, 'label': instance.label};

CityApiModel _$CityApiModelFromJson(Map<String, dynamic> json) => CityApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  stateName: json['stateName'] as String?,
);

Map<String, dynamic> _$CityApiModelToJson(CityApiModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'stateName': instance.stateName,
};

NamedApiModel _$NamedApiModelFromJson(Map<String, dynamic> json) => NamedApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$NamedApiModelToJson(NamedApiModel instance) => <String, dynamic>{'id': instance.id, 'name': instance.name};

CreatedIdApiModel _$CreatedIdApiModelFromJson(Map<String, dynamic> json) => CreatedIdApiModel(id: (json['id'] as num).toInt());

Map<String, dynamic> _$CreatedIdApiModelToJson(CreatedIdApiModel instance) => <String, dynamic>{'id': instance.id};

CepApiModel _$CepApiModelFromJson(Map<String, dynamic> json) => CepApiModel(
  cep: json['cep'] as String?,
  logradouro: json['logradouro'] as String?,
  complemento: json['complemento'] as String?,
  bairro: json['bairro'] as String?,
  localidade: json['localidade'] as String?,
  uf: json['uf'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  districtId: (json['districtId'] as num?)?.toInt(),
);

Map<String, dynamic> _$CepApiModelToJson(CepApiModel instance) => <String, dynamic>{
  'cep': instance.cep,
  'logradouro': instance.logradouro,
  'complemento': instance.complemento,
  'bairro': instance.bairro,
  'localidade': instance.localidade,
  'uf': instance.uf,
  'cityId': instance.cityId,
  'districtId': instance.districtId,
};

DuplicateMemberApiModel _$DuplicateMemberApiModelFromJson(
  Map<String, dynamic> json,
) => DuplicateMemberApiModel(
  person: MemberEditApiModel.fromJson(json['person'] as Map<String, dynamic>),
  createdAt: json['createdAt'] as String?,
  positions: (json['positions'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

DuplicateGroupApiModel _$DuplicateGroupApiModelFromJson(
  Map<String, dynamic> json,
) => DuplicateGroupApiModel(
  kind: json['kind'] as String,
  members: (json['members'] as List<dynamic>).map((e) => DuplicateMemberApiModel.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$DuplicateMergeInputToJson(
  DuplicateMergeInput instance,
) => <String, dynamic>{
  'stringify': instance.stringify,
  'keepId': instance.keepId,
  'removeId': instance.removeId,
  'takeFromRemoved': instance.takeFromRemoved,
  'props': instance.props,
};

Map<String, dynamic> _$DuplicateDismissInputToJson(
  DuplicateDismissInput instance,
) => <String, dynamic>{
  'stringify': instance.stringify,
  'personId': instance.personId,
  'otherPersonId': instance.otherPersonId,
  'props': instance.props,
};

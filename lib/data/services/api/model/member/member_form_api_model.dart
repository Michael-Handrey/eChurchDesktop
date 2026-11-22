import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'member_form_api_model.g.dart';

/// Endereço para editar (AddressDTO): ids e nomes do bairro e da cidade.
@JsonSerializable()
class const MemberEditAddressApiModel({
  final int? id,
  final String? streetType,
  final String? streetName,
  final String? streetNumber,
  final String? complement,
  final String? postalCode,
  final int? district,
  final String? districtName,
  final int? cityId,
  final String? cityName,
  final String? stateAbbreviation,
}) extends Equatable {
  factory MemberEditAddressApiModel.fromJson(Map<String, dynamic> json) => _$MemberEditAddressApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberEditAddressApiModelToJson(this);

  @override
  List<Object?> get props => [id, streetType, streetName, streetNumber, complement, postalCode, district, districtName, cityId, cityName, stateAbbreviation];
}

/// Contato (ContactDTO), com as redes sociais (o formulário não mostra, mas preserva).
@JsonSerializable(includeIfNull: false)
class const MemberContactInput({final int? id, final String? email, final String? facebook, final String? twitter, final String? instagram, final String? phone, final String? secondaryPhone}) extends Equatable {
  factory MemberContactInput.fromJson(Map<String, dynamic> json) => _$MemberContactInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemberContactInputToJson(this);

  @override
  List<Object?> get props => [id, email, facebook, twitter, instagram, phone, secondaryPhone];
}

/// Membro completo para editar (NaturalPersonResponseDTO, só Secretaria/Administrador). Datas "aaaa-mm-dd".
@JsonSerializable()
class const MemberEditApiModel({
  required final int id,
  final String? name,
  final String? birthDate,
  final String? cpf,
  final String? rg,
  final String? gender,
  final String? fatherName,
  final String? motherName,
  final String? maritalStatus,
  final String? spouseName,
  final int? spouseId,
  final int? birthCityId,
  final String? birthCityName,
  final String? birthCityState,
  final String? nationality,
  final int? professionId,
  final String? professionName,
  final MemberEditAddressApiModel? address,
  final MemberContactInput? contact,
  final String? notes,
  final String? status,
  final int? ecclesiasticalRoleId,
  final List<int>? ministryIds,
  final int? churchId,
  final String? deathDate,
  final String? acceptedJesusDate,
  final String? baptismDate,
  final String? individualType,
  final String? ecclesiasticalRoleName,
  final String? churchName,
  final List<String>? ministryNames,
  final bool? credentialPrinted,
}) extends Equatable {
  factory MemberEditApiModel.fromJson(Map<String, dynamic> json) => _$MemberEditApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberEditApiModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    birthDate,
    cpf,
    rg,
    gender,
    fatherName,
    motherName,
    maritalStatus,
    spouseName,
    spouseId,
    birthCityId,
    birthCityName,
    birthCityState,
    nationality,
    professionId,
    professionName,
    address,
    contact,
    notes,
    status,
    ecclesiasticalRoleId,
    ministryIds,
    churchId,
    deathDate,
    acceptedJesusDate,
    baptismDate,
    individualType,
    ecclesiasticalRoleName,
    churchName,
    ministryNames,
    credentialPrinted,
  ];
}

/// Endereço para salvar (AddressDTO do pedido: o bairro vai pelo id).
@JsonSerializable(includeIfNull: false)
class const MemberAddressInput({
  final int? id,
  final String? streetType,
  final String? streetName,
  final String? streetNumber,
  final String? complement,
  final String? postalCode,
  final int? district,
}) extends Equatable {
  factory MemberAddressInput.fromJson(Map<String, dynamic> json) => _$MemberAddressInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemberAddressInputToJson(this);

  @override
  List<Object?> get props => [id, streetType, streetName, streetNumber, complement, postalCode, district];
}

/// Corpo de salvar (NaturalPersonRequestDTO): sem [id] cadastra, com [id] altera.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class const MemberInput({
  final int? id,
  final String? name,
  final String? birthDate,
  final String? cpf,
  final String? rg,
  final String? gender,
  final String? fatherName,
  final String? motherName,
  final String? maritalStatus,
  final String? spouseName,
  final int? spouseId,
  final int? birthCityId,
  final String? nationality,
  final int? professionId,
  final MemberAddressInput? address,
  final MemberContactInput? contact,
  final String? notes,
  final String? status,
  final int? ecclesiasticalRoleId,
  final List<int>? ministryIds,
  final int? churchId,
  final String? deathDate,
  final String? acceptedJesusDate,
  final String? baptismDate,
  final String? individualType,
}) extends Equatable {
  factory MemberInput.fromJson(Map<String, dynamic> json) => _$MemberInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemberInputToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    birthDate,
    cpf,
    rg,
    gender,
    fatherName,
    motherName,
    maritalStatus,
    spouseName,
    spouseId,
    birthCityId,
    nationality,
    professionId,
    address,
    contact,
    notes,
    status,
    ecclesiasticalRoleId,
    ministryIds,
    churchId,
    deathDate,
    acceptedJesusDate,
    baptismDate,
    individualType,
  ];
}

/// Nacionalidade nas opções (`nationalityOptions`).
@JsonSerializable()
class const NationalityApiModel({required final String value, final String? label}) extends Equatable {
  factory NationalityApiModel.fromJson(Map<String, dynamic> json) => _$NationalityApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$NationalityApiModelToJson(this);

  @override
  List<Object?> get props => [value, label];
}

/// Cidade no autocompletar (CityDTO; `stateName` é a UF).
@JsonSerializable()
class const CityApiModel({required final int id, final String? name, final String? stateName}) extends Equatable {
  factory CityApiModel.fromJson(Map<String, dynamic> json) => _$CityApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$CityApiModelToJson(this);

  @override
  List<Object?> get props => [id, name, stateName];
}

/// Id + nome (DistrictDTO, Profession).
@JsonSerializable()
class const NamedApiModel({required final int id, final String? name}) extends Equatable {
  factory NamedApiModel.fromJson(Map<String, dynamic> json) => _$NamedApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$NamedApiModelToJson(this);

  @override
  List<Object?> get props => [id, name];
}

/// Resposta de criar bairro ou profissão: `{"id": 10}`.
@JsonSerializable()
class const CreatedIdApiModel({required final int id}) extends Equatable {
  factory CreatedIdApiModel.fromJson(Map<String, dynamic> json) => _$CreatedIdApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedIdApiModelToJson(this);

  @override
  List<Object?> get props => [id];
}

/// CEP (ResponseCEPDTO, do ViaCEP) com a cidade e o bairro do cadastro, quando existem.
@JsonSerializable()
class const CepApiModel({
  final String? cep,
  final String? logradouro,
  final String? complemento,
  final String? bairro,
  final String? localidade,
  final String? uf,
  final int? cityId,
  final int? districtId,
}) extends Equatable {
  factory CepApiModel.fromJson(Map<String, dynamic> json) => _$CepApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$CepApiModelToJson(this);

  @override
  List<Object?> get props => [cep, logradouro, complemento, bairro, localidade, uf, cityId, districtId];
}

/// Um cadastro de um grupo de duplicados (DuplicateMemberDTO).
@JsonSerializable(createToJson: false)
class const DuplicateMemberApiModel({required final MemberEditApiModel person, final String? createdAt, final List<String>? positions}) extends Equatable {
  factory DuplicateMemberApiModel.fromJson(Map<String, dynamic> json) => _$DuplicateMemberApiModelFromJson(json);

  @override
  List<Object?> get props => [person, createdAt, positions];
}

/// Grupo de cadastros da mesma pessoa (DuplicateGroupDTO): `kind` = "CPF" ou "NAME_BIRTH".
@JsonSerializable(createToJson: false)
class const DuplicateGroupApiModel({required final String kind, required final List<DuplicateMemberApiModel> members}) extends Equatable {
  factory DuplicateGroupApiModel.fromJson(Map<String, dynamic> json) => _$DuplicateGroupApiModelFromJson(json);

  @override
  List<Object?> get props => [kind, members];
}

/// Juntar (DuplicateMergeDTO): `takeFromRemoved` = campos cujo valor vem do cadastro desativado.
@JsonSerializable(createFactory: false)
class const DuplicateMergeInput({required final int keepId, required final int removeId, required final List<String> takeFromRemoved}) extends Equatable {
  Map<String, dynamic> toJson() => _$DuplicateMergeInputToJson(this);

  @override
  List<Object?> get props => [keepId, removeId, takeFromRemoved];
}

/// "Não são a mesma pessoa" (DuplicateDismissDTO).
@JsonSerializable(createFactory: false)
class const DuplicateDismissInput({required final int personId, required final int otherPersonId}) extends Equatable {
  Map<String, dynamic> toJson() => _$DuplicateDismissInputToJson(this);

  @override
  List<Object?> get props => [personId, otherPersonId];
}

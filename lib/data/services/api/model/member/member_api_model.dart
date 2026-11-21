import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'member_api_model.g.dart';

/// Linha da lista (MemberRowDTO).
@JsonSerializable()
class const MemberRowApiModel({
  required final int id,
  final String? name,
  final String? status,
  final String? ecclesiasticalRoleName,
  final int? churchId,
  final String? churchName,
  final String? phone,
  final int? birthDay,
  final int? birthMonth,
  final bool? credentialPrinted,
  final String? deactivationReason,
}) extends Equatable {
  factory MemberRowApiModel.fromJson(Map<String, dynamic> json) => _$MemberRowApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberRowApiModelToJson(this);

  @override
  List<Object?> get props => [id, name, status, ecclesiasticalRoleName, churchId, churchName, phone, birthDay, birthMonth, credentialPrinted, deactivationReason];
}

/// Página da lista (MemberPageDTO).
@JsonSerializable()
class const MemberPageApiModel({required final List<MemberRowApiModel> items, required final int total, required final int page, required final int size}) extends Equatable {
  factory MemberPageApiModel.fromJson(Map<String, dynamic> json) => _$MemberPageApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberPageApiModelToJson(this);

  @override
  List<Object?> get props => [items, total, page, size];
}

/// Endereço do detalhe (AddressDTO), com bairro, cidade e UF por extenso.
@JsonSerializable()
class const MemberAddressApiModel({
  final String? streetType,
  final String? streetName,
  final String? streetNumber,
  final String? complement,
  final String? postalCode,
  final String? districtName,
  final String? cityName,
  final String? stateAbbreviation,
}) extends Equatable {
  factory MemberAddressApiModel.fromJson(Map<String, dynamic> json) => _$MemberAddressApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberAddressApiModelToJson(this);

  @override
  List<Object?> get props => [streetType, streetName, streetNumber, complement, postalCode, districtName, cityName, stateAbbreviation];
}

/// Contato do detalhe (ContactDTO).
@JsonSerializable()
class const MemberContactApiModel({final String? email, final String? phone, final String? secondaryPhone}) extends Equatable {
  factory MemberContactApiModel.fromJson(Map<String, dynamic> json) => _$MemberContactApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberContactApiModelToJson(this);

  @override
  List<Object?> get props => [email, phone, secondaryPhone];
}

/// Detalhe do membro: NaturalPersonResponseDTO (Secretaria/Administrador) ou
/// NaturalPersonSummaryDTO (quem só consulta: contato no topo, nascimento só dia e mês).
/// Datas como texto ISO ("1980-03-15"; `deactivatedAt` com hora).
@JsonSerializable()
class const MemberDetailsApiModel({
  required final int id,
  final String? name,
  final String? status,
  final String? ecclesiasticalRoleName,
  final List<String>? ministryNames,
  final String? churchName,
  final String? birthDate,
  final int? birthDay,
  final int? birthMonth,
  final String? gender,
  final String? maritalStatus,
  final String? spouseName,
  final String? fatherName,
  final String? motherName,
  final String? cpf,
  final String? rg,
  final MemberContactApiModel? contact,
  final MemberAddressApiModel? address,
  final String? phone,
  final String? secondaryPhone,
  final String? email,
  final String? baptismDate,
  final String? acceptedJesusDate,
  final String? notes,
  final String? deactivationReason,
  final String? deactivationDescription,
  final String? deactivatedAt,
  final String? deactivatedByName,
}) extends Equatable {
  factory MemberDetailsApiModel.fromJson(Map<String, dynamic> json) => _$MemberDetailsApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberDetailsApiModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    ecclesiasticalRoleName,
    ministryNames,
    churchName,
    birthDate,
    birthDay,
    birthMonth,
    gender,
    maritalStatus,
    spouseName,
    fatherName,
    motherName,
    cpf,
    rg,
    contact,
    address,
    phone,
    secondaryPhone,
    email,
    baptismDate,
    acceptedJesusDate,
    notes,
    deactivationReason,
    deactivationDescription,
    deactivatedAt,
    deactivatedByName,
  ];
}

/// Opção id + nome (OptionDTO).
@JsonSerializable()
class const MemberOptionApiModel({required final int id, final String? name}) extends Equatable {
  factory MemberOptionApiModel.fromJson(Map<String, dynamic> json) => _$MemberOptionApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberOptionApiModelToJson(this);

  @override
  List<Object?> get props => [id, name];
}

/// `GET /people/options`: aqui só os cargos (o resto é para o formulário de cadastro).
@JsonSerializable(createToJson: false)
class const MemberOptionsApiModel({@JsonKey(name: 'cargosEclesiasticos') final List<MemberOptionApiModel>? ecclesiasticalRoles}) extends Equatable {
  factory MemberOptionsApiModel.fromJson(Map<String, dynamic> json) => _$MemberOptionsApiModelFromJson(json);

  @override
  List<Object?> get props => [ecclesiasticalRoles];
}

/// Corpo de "desativar" (MemberDeactivationRequestDTO).
@JsonSerializable()
class const MemberDeactivationInput({required final String reason, required final String description}) extends Equatable {
  factory MemberDeactivationInput.fromJson(Map<String, dynamic> json) => _$MemberDeactivationInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemberDeactivationInputToJson(this);

  @override
  List<Object?> get props => [reason, description];
}

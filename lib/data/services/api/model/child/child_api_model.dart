import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'child_api_model.g.dart';

/// Linha da lista (ChildRowDTO). Datas "aaaa-mm-dd".
@JsonSerializable(createToJson: false)
class const ChildRowApiModel({
  required final int id,
  final String? name,
  final String? birthDate,
  final int? age,
  final int? churchId,
  final String? churchName,
  final int? ministryId,
  final String? ministryName,
  final String? guardians,
  final bool? active,
}) extends Equatable {
  factory ChildRowApiModel.fromJson(Map<String, dynamic> json) => _$ChildRowApiModelFromJson(json);

  @override
  List<Object?> get props => [id, name, birthDate, age, churchId, churchName, ministryId, ministryName, guardians, active];
}

@JsonSerializable(createToJson: false)
class const ChildPageApiModel({final List<ChildRowApiModel> items = const [], final int total = 0, final int page = 0, final int size = 20}) extends Equatable {
  factory ChildPageApiModel.fromJson(Map<String, dynamic> json) => _$ChildPageApiModelFromJson(json);

  @override
  List<Object?> get props => [items, total, page, size];
}

@JsonSerializable(createToJson: false)
class const GuardianApiModel({required final int personId, final String? name, final String? kinship, final String? phone, final String? churchName}) extends Equatable {
  factory GuardianApiModel.fromJson(Map<String, dynamic> json) => _$GuardianApiModelFromJson(json);

  @override
  List<Object?> get props => [personId, name, kinship, phone, churchName];
}

/// A criança completa (ChildDTO).
@JsonSerializable(createToJson: false)
class const ChildApiModel({
  required final int id,
  final String? name,
  final String? birthDate,
  final int? age,
  final int? churchId,
  final String? churchName,
  final int? ministryId,
  final String? ministryName,
  final String? notes,
  final bool? active,
  final List<GuardianApiModel> guardians = const [],
}) extends Equatable {
  factory ChildApiModel.fromJson(Map<String, dynamic> json) => _$ChildApiModelFromJson(json);

  @override
  List<Object?> get props => [id, name, birthDate, age, churchId, churchName, ministryId, ministryName, notes, active, guardians];
}

@JsonSerializable(createFactory: false)
class const GuardianInput({required final int personId, required final String kinship}) extends Equatable {
  Map<String, dynamic> toJson() => _$GuardianInputToJson(this);

  @override
  List<Object?> get props => [personId, kinship];
}

/// Cadastrar ou editar (ChildInputDTO).
@JsonSerializable(createFactory: false, explicitToJson: true)
class const ChildInput({
  required final String name,
  required final String birthDate,
  required final int churchId,
  final int? ministryId,
  final String? notes,
  required final List<GuardianInput> guardians,
}) extends Equatable {
  Map<String, dynamic> toJson() => _$ChildInputToJson(this);

  @override
  List<Object?> get props => [name, birthDate, churchId, ministryId, notes, guardians];
}

@JsonSerializable(createFactory: false)
class const ChildActiveInput({required final bool active}) extends Equatable {
  Map<String, dynamic> toJson() => _$ChildActiveInputToJson(this);

  @override
  List<Object?> get props => [active];
}

/// Membro para responsável (GuardianOptionDTO).
@JsonSerializable(createToJson: false)
class const GuardianOptionApiModel({
  required final int id,
  final String? name,
  final String? churchName,
  final String? gender,
  final int? spouseId,
  final String? spouseName,
  final String? spouseGender,
}) extends Equatable {
  factory GuardianOptionApiModel.fromJson(Map<String, dynamic> json) => _$GuardianOptionApiModelFromJson(json);

  @override
  List<Object?> get props => [id, name, churchName, gender, spouseId, spouseName, spouseGender];
}

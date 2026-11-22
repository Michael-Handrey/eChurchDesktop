import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spouse_review_api_model.g.dart';

/// Um lado do par na revisão de cônjuges (SpousePersonDTO).
@JsonSerializable(createToJson: false)
class const SpousePersonApiModel({
  required final int id,
  final String? name,
  final String? writtenSpouse,
  final String? maritalStatus,
  final String? status,
  final int? churchId,
  final String? churchName,
  final String? address,
}) extends Equatable {
  factory SpousePersonApiModel.fromJson(Map<String, dynamic> json) => _$SpousePersonApiModelFromJson(json);

  @override
  List<Object?> get props => [id, name, writtenSpouse, maritalStatus, status, churchId, churchName, address];
}

/// Sugestão de casal (SpouseSuggestionDTO): confidence HIGH/MEDIUM/LOW; kind MUTUAL/ONE_SIDE/SIMILAR.
@JsonSerializable(createToJson: false)
class const SpouseSuggestionApiModel({
  required final String confidence,
  required final String kind,
  required final SpousePersonApiModel person,
  required final SpousePersonApiModel candidate,
  final bool? sameAddress,
  final List<String>? notes,
}) extends Equatable {
  factory SpouseSuggestionApiModel.fromJson(Map<String, dynamic> json) => _$SpouseSuggestionApiModelFromJson(json);

  @override
  List<Object?> get props => [confidence, kind, person, candidate, sameAddress, notes];
}

/// O que falta revisar (SpouseReviewDTO).
@JsonSerializable(createToJson: false)
class const SpouseReviewApiModel({final List<SpouseSuggestionApiModel>? suggestions, final List<SpousePersonApiModel>? withoutSuggestion}) extends Equatable {
  factory SpouseReviewApiModel.fromJson(Map<String, dynamic> json) => _$SpouseReviewApiModelFromJson(json);

  @override
  List<Object?> get props => [suggestions, withoutSuggestion];
}

/// Ligar um casal (SpouseLinkDTO). `addressFrom`: id de quem tem o endereço certo; nulo = não mexe.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const SpouseLinkInput({required final int personId, required final int spouseId, final int? addressFrom}) extends Equatable {
  Map<String, dynamic> toJson() => _$SpouseLinkInputToJson(this);

  @override
  List<Object?> get props => [personId, spouseId, addressFrom];
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class const SpouseLinkBatchInput({required final List<SpouseLinkInput> links}) extends Equatable {
  Map<String, dynamic> toJson() => _$SpouseLinkBatchInputToJson(this);

  @override
  List<Object?> get props => [links];
}

/// "Não é este" (candidateId) ou "não é membro" (candidateId nulo).
@JsonSerializable(createFactory: false)
class const SpouseDismissInput({required final int personId, final int? candidateId}) extends Equatable {
  Map<String, dynamic> toJson() => _$SpouseDismissInputToJson(this);

  @override
  List<Object?> get props => [personId, candidateId];
}

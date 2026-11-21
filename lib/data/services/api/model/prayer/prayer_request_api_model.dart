import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'prayer_request_api_model.g.dart';

/// Pedido de oração (PrayerRequestDTO). Datas como texto ISO: `requestDate` só a data
/// ("2026-11-20"); as demais com hora, sem fuso ("2026-11-20T17:00:00").
@JsonSerializable()
class const PrayerRequestApiModel({
  required final int id,
  final String? requesterName,
  final String? description,
  final String? requestDate,
  final String? status,
  final bool? fromCommunity,
  final int? churchId,
  final String? churchName,
  final String? createdByName,
  final String? createdAt,
  final String? printedAt,
  final String? rejectedAt,
  final String? rejectedByName,
  final String? rejectionReason,
  final String? excludedAt,
  final String? excludedByName,
  final List<String>? actions,
}) extends Equatable {
  factory PrayerRequestApiModel.fromJson(Map<String, dynamic> json) => _$PrayerRequestApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$PrayerRequestApiModelToJson(this);

  @override
  List<Object?> get props => [id, requesterName, description, requestDate, status, fromCommunity, churchId, churchName, createdByName, createdAt, printedAt, rejectedAt, rejectedByName, rejectionReason, excludedAt, excludedByName, actions];
}

/// Página da lista (PrayerRequestPageDTO).
@JsonSerializable()
class const PrayerRequestPageApiModel({required final List<PrayerRequestApiModel> items, required final int total, required final int page, required final int size}) extends Equatable {
  factory PrayerRequestPageApiModel.fromJson(Map<String, dynamic> json) => _$PrayerRequestPageApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$PrayerRequestPageApiModelToJson(this);

  @override
  List<Object?> get props => [items, total, page, size];
}

/// Corpo para registrar ou alterar (PrayerRequestInputDTO). `requestDate` como "aaaa-mm-dd".
@JsonSerializable(includeIfNull: false)
class const PrayerRequestInput({required final String requesterName, required final String description, final String? requestDate, final int? churchId}) extends Equatable {
  factory PrayerRequestInput.fromJson(Map<String, dynamic> json) => _$PrayerRequestInputFromJson(json);

  Map<String, dynamic> toJson() => _$PrayerRequestInputToJson(this);

  @override
  List<Object?> get props => [requesterName, description, requestDate, churchId];
}

/// Corpo de "no vaso" (PrayerRequestIdsDTO).
@JsonSerializable()
class const PrayerRequestIds({required final List<int> ids}) extends Equatable {
  factory PrayerRequestIds.fromJson(Map<String, dynamic> json) => _$PrayerRequestIdsFromJson(json);

  Map<String, dynamic> toJson() => _$PrayerRequestIdsToJson(this);

  @override
  List<Object?> get props => [ids];
}

/// Corpo de "todos os novos no vaso" (PrayerRequestChurchDTO).
@JsonSerializable(includeIfNull: false)
class const PrayerRequestChurch({final int? churchId}) extends Equatable {
  factory PrayerRequestChurch.fromJson(Map<String, dynamic> json) => _$PrayerRequestChurchFromJson(json);

  Map<String, dynamic> toJson() => _$PrayerRequestChurchToJson(this);

  @override
  List<Object?> get props => [churchId];
}

/// Corpo de "rejeitar" (PrayerRequestRejectDTO).
@JsonSerializable(includeIfNull: false)
class const PrayerRequestReject({final String? reason}) extends Equatable {
  factory PrayerRequestReject.fromJson(Map<String, dynamic> json) => _$PrayerRequestRejectFromJson(json);

  Map<String, dynamic> toJson() => _$PrayerRequestRejectToJson(this);

  @override
  List<Object?> get props => [reason];
}

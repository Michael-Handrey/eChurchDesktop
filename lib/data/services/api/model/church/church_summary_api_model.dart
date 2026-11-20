import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'church_summary_api_model.g.dart';

/// Item de `GET /api/v1/churches` (ChurchSummaryDTO).
@JsonSerializable()
class const ChurchSummaryApiModel({required final int id, final String? name, final bool? headquarters}) extends Equatable {
  factory ChurchSummaryApiModel.fromJson(Map<String, dynamic> json) => _$ChurchSummaryApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChurchSummaryApiModelToJson(this);

  @override
  List<Object?> get props => [id, name, headquarters];
}

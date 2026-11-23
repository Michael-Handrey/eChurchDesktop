import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dashboard_api_model.g.dart';

/// Números dos cards (DashboardStatsDTO).
@JsonSerializable(createToJson: false)
class const DashboardStatsApiModel({final int? activeMembers, final int? children, final int? newPrayers}) extends Equatable {
  factory DashboardStatsApiModel.fromJson(Map<String, dynamic> json) => _$DashboardStatsApiModelFromJson(json);

  @override
  List<Object?> get props => [activeMembers, children, newPrayers];
}

/// Aniversariante (DashboardBirthdayDTO): `date` = aniversário deste ano ("aaaa-mm-dd"); `age` nula para quem só consulta.
@JsonSerializable(createToJson: false)
class const DashboardBirthdayApiModel({required final int id, final String? name, final String? date, final int? age, final bool? child}) extends Equatable {
  factory DashboardBirthdayApiModel.fromJson(Map<String, dynamic> json) => _$DashboardBirthdayApiModelFromJson(json);

  @override
  List<Object?> get props => [id, name, date, age, child];
}

/// Último registro (DashboardRecentDTO): `type` MEMBER ou PRAYER; `at` com hora, sem fuso.
@JsonSerializable(createToJson: false)
class const DashboardRecentApiModel({required final String type, required final int id, final String? title, final String? at}) extends Equatable {
  factory DashboardRecentApiModel.fromJson(Map<String, dynamic> json) => _$DashboardRecentApiModelFromJson(json);

  @override
  List<Object?> get props => [type, id, title, at];
}

/// Painel inicial (DashboardDTO).
@JsonSerializable(createToJson: false)
class const DashboardApiModel({
  final DashboardStatsApiModel? stats,
  final List<DashboardBirthdayApiModel>? birthdaysToday,
  final List<DashboardBirthdayApiModel>? birthdaysNext,
  final List<DashboardRecentApiModel>? recent,
}) extends Equatable {
  factory DashboardApiModel.fromJson(Map<String, dynamic> json) => _$DashboardApiModelFromJson(json);

  @override
  List<Object?> get props => [stats, birthdaysToday, birthdaysNext, recent];
}

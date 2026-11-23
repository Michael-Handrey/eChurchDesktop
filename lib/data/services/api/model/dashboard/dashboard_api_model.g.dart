// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStatsApiModel _$DashboardStatsApiModelFromJson(
  Map<String, dynamic> json,
) => DashboardStatsApiModel(
  activeMembers: (json['activeMembers'] as num?)?.toInt(),
  children: (json['children'] as num?)?.toInt(),
  newPrayers: (json['newPrayers'] as num?)?.toInt(),
);

DashboardBirthdayApiModel _$DashboardBirthdayApiModelFromJson(
  Map<String, dynamic> json,
) => DashboardBirthdayApiModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  date: json['date'] as String?,
  age: (json['age'] as num?)?.toInt(),
  child: json['child'] as bool?,
);

DashboardRecentApiModel _$DashboardRecentApiModelFromJson(
  Map<String, dynamic> json,
) => DashboardRecentApiModel(
  type: json['type'] as String,
  id: (json['id'] as num).toInt(),
  title: json['title'] as String?,
  at: json['at'] as String?,
);

DashboardApiModel _$DashboardApiModelFromJson(
  Map<String, dynamic> json,
) => DashboardApiModel(
  stats: json['stats'] == null ? null : DashboardStatsApiModel.fromJson(json['stats'] as Map<String, dynamic>),
  birthdaysToday: (json['birthdaysToday'] as List<dynamic>?)
      ?.map(
        (e) => DashboardBirthdayApiModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  birthdaysNext: (json['birthdaysNext'] as List<dynamic>?)
      ?.map(
        (e) => DashboardBirthdayApiModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  recent: (json['recent'] as List<dynamic>?)?.map((e) => DashboardRecentApiModel.fromJson(e as Map<String, dynamic>)).toList(),
);

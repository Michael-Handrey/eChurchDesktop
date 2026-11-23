import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/services/api/dashboard_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/dashboard/dashboard_api_model.dart';
import 'package:echurch_desktop/domain/models/dashboard/birthday.dart';
import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/domain/models/dashboard/recent_activity.dart';
import 'package:equatable/equatable.dart';

/// O painel inicial de uma igreja: números dos cards, aniversariantes e últimos registros.
class const HomeData({
  final List<QuickStat> stats = const [],
  final List<Birthday> birthdaysToday = const [],
  final List<Birthday> birthdaysNext = const [],
  final List<RecentActivity> activities = const [],
}) extends Equatable {
  @override
  List<Object?> get props => [stats, birthdaysToday, birthdaysNext, activities];
}

abstract interface class DashboardRepository {
  Future<Result<HomeData>> load(int churchId);
}

class DashboardRepositoryRemote({required final DashboardApi _api}) implements DashboardRepository {
  @override
  Future<Result<HomeData>> load(int churchId) async {
    try {
      final data = await _api.dashboard(churchId);
      Birthday birthday(DashboardBirthdayApiModel item) => Birthday(name: (item.name ?? '').trim(), date: DateTime.tryParse(item.date ?? '') ?? DateTime.now(), age: item.age, isChild: item.child ?? false);
      return Result.ok(
        HomeData(
          stats: [
            QuickStat(label: 'membros ativos', count: data.stats?.activeMembers ?? 0, type: QuickStatType.members),
            QuickStat(label: 'até 10 anos', count: data.stats?.children ?? 0, type: QuickStatType.children),
            QuickStat(label: 'novos', count: data.stats?.newPrayers ?? 0, type: QuickStatType.prayers),
          ],
          birthdaysToday: [for (final item in data.birthdaysToday ?? const []) birthday(item)],
          birthdaysNext: [for (final item in data.birthdaysNext ?? const []) birthday(item)],
          activities: [
            for (final item in data.recent ?? const [])
              if (DateTime.tryParse(item.at ?? '') case final at?) RecentActivity(id: item.id, title: (item.title ?? '').trim(), type: item.type == 'PRAYER' ? ActivityType.prayer : ActivityType.member, at: at),
          ],
        ),
      );
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

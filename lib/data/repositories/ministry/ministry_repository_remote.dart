import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/member_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/ministry_api.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/ministry/ministry_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';

class MinistryRepositoryRemote({required final MinistryApi _api}) implements MinistryRepository {
  @override
  Future<Result<List<Ministry>>> list({int? churchId, bool includeInactive = false}) => _guard(() async => [for (final item in await _api.list(churchId: churchId, inactive: includeInactive ? true : null)) _toDomain(item)]);

  @override
  Future<Result<Ministry>> save(int? id, MinistryDraft draft) => _guard(() async {
    final input = MinistryInput(defaultName: draft.type.trim(), name: draft.name.trim(), churchId: draft.churchId, leaderId: draft.leaderId, viceLeaderId: draft.viceLeaderId);
    return _toDomain(id == null ? await _api.create(input) : await _api.update(id, input));
  });

  @override
  Future<Result<Ministry>> setActive(int id, bool active) => _guard(() async => _toDomain(await _api.setActive(id, MinistryActiveInput(active: active))));

  @override
  Future<Result<List<MemberRow>>> members(int id) => _guard(() async => _rows(await _api.members(id)));

  @override
  Future<Result<List<MemberRow>>> addMembers(int id, List<int> personIds) => _guard(() async => _rows(await _api.addMembers(id, MinistryMembersInput(personIds: personIds))));

  @override
  Future<Result<List<MemberRow>>> removeMembers(int id, List<int> personIds) => _guard(() async => _rows(await _api.removeMembers(id, MinistryMembersInput(personIds: personIds))));

  static List<MemberRow> _rows(List<MemberRowApiModel> items) => [for (final item in items) item.toDomain()];

  static Ministry _toDomain(MinistryApiModel model) => Ministry(
    id: model.id,
    type: (model.defaultName ?? '').trim(),
    name: (model.name ?? '').trim(),
    churchId: model.churchId,
    churchName: model.churchName,
    leaderId: model.leaderId,
    leaderName: model.leaderName?.trim(),
    viceLeaderId: model.viceLeaderId,
    viceLeaderName: model.viceLeaderName?.trim(),
    memberCount: model.memberCount ?? 0,
    active: model.active ?? true,
  );

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

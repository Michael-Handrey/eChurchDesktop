import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/prayer_request/prayer_request_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/prayer_request_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/prayer/prayer_request_api_model.dart';
import 'package:echurch_desktop/data/services/api/prayer_request_api.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';

class PrayerRequestRepositoryRemote({required final PrayerRequestApi _api}) implements PrayerRequestRepository {
  @override
  Future<Result<PrayerRequestPage>> search({int? churchId, PrayerRequestStatus? status, String? text, bool excluded = false, int page = 0, int size = 20}) => _guard(() async {
    final term = text?.trim();
    final result = await _api.search(churchId: churchId, status: status?.apiValue, text: term == null || term.isEmpty ? null : term, excluded: excluded ? true : null, page: page, size: size);
    return result.toDomain();
  });

  @override
  Future<Result<PrayerRequest>> create(PrayerRequestDraft draft) => _guard(() async => (await _api.create(draft.toInput())).toDomain());

  @override
  Future<Result<PrayerRequest>> update(int id, PrayerRequestDraft draft) => _guard(() async => (await _api.update(id, draft.toInput())).toDomain());

  @override
  Future<Result<List<PrayerRequest>>> markInVase(Set<int> ids) => _guard(() async => _list(await _api.markInVase(PrayerRequestIds(ids: ids.toList()))));

  @override
  Future<Result<List<PrayerRequest>>> markAllNewInVase(int churchId) => _guard(() async => _list(await _api.markAllNewInVase(PrayerRequestChurch(churchId: churchId))));

  @override
  Future<Result<PrayerRequest>> reject(int id, {String? reason}) => _guard(() async {
    final text = reason?.trim();
    return (await _api.reject(id, PrayerRequestReject(reason: text == null || text.isEmpty ? null : text))).toDomain();
  });

  @override
  Future<Result<PrayerRequest>> backToNew(int id) => _guard(() async => (await _api.backToNew(id)).toDomain());

  @override
  Future<Result<PrayerRequest>> exclude(int id) => _guard(() async => (await _api.exclude(id)).toDomain());

  @override
  Future<Result<PrayerRequest>> restore(int id) => _guard(() async => (await _api.restore(id)).toDomain());

  static List<PrayerRequest> _list(List<PrayerRequestApiModel> items) => [for (final item in items) item.toDomain()];

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

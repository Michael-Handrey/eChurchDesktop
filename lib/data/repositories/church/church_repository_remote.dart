import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/church/church_repository.dart';
import 'package:echurch_desktop/data/services/api/church_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/church_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';

class ChurchRepositoryRemote({required final ChurchApi _churchApi}) implements ChurchRepository {
  @override
  Future<Result<List<ChurchSummary>>> list() async {
    try {
      final churches = await _churchApi.list();
      return Result.ok([for (final church in churches) church.toDomain()]);
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

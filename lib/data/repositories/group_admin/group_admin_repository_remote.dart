import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/group_admin/group_admin_repository.dart';
import 'package:echurch_desktop/data/services/api/group_admin_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/group_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/group/group_api_model.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';

/// 400 do backend (nome repetido, grupo com usuários, admin perdendo o próprio acesso)
/// vira `ValidationException` com a mensagem dele.
class GroupAdminRepositoryRemote({required final GroupAdminApi _groupAdminApi}) implements GroupAdminRepository {
  @override
  Future<Result<List<SecurityGroup>>> list() async {
    try {
      final groups = await _groupAdminApi.list();
      return Result.ok([for (final group in groups) group.toDomain()]);
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<List<String>>> permissions() async {
    try {
      return Result.ok(await _groupAdminApi.permissions());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<SecurityGroup>> save({int? id, required String name, required Set<String> permissions}) async {
    try {
      final request = GroupRequest(name: name, permissions: permissions.toList()..sort());
      final saved = id == null ? await _groupAdminApi.create(request) : await _groupAdminApi.update(id, request);
      return Result.ok(saved.toDomain());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _groupAdminApi.delete(id);
      return Result.done;
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

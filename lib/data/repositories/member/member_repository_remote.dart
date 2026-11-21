import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/member_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/member_api.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';

class MemberRepositoryRemote({required final MemberApi _api}) implements MemberRepository {
  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) => _guard(() async {
    final term = text?.trim();
    final result = await _api.search(
      churchId: churchId,
      status: status == null || status == MemberStatus.other ? null : status.apiValue,
      text: term == null || term.isEmpty ? null : term,
      ecclesiasticalRoleId: ecclesiasticalRoleId,
      page: page,
      size: size,
    );
    return result.toDomain();
  });

  @override
  Future<Result<List<EcclesiasticalRoleOption>>> roles() => _guard(() async {
    final options = await _api.options();
    return [
      for (final role in options.ecclesiasticalRoles ?? const <MemberOptionApiModel>[])
        if ((role.name ?? '').trim().isNotEmpty) EcclesiasticalRoleOption(id: role.id, name: role.name!.trim()),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });

  @override
  Future<Result<MemberDetails>> details(int id) => _guard(() async => (await _api.findById(id)).toDomain());

  @override
  Future<Result<MemberDetails>> deactivate(int id, {required DeactivationReason reason, required String description}) => _guard(() async => (await _api.deactivate(id, MemberDeactivationInput(reason: reason.apiValue, description: description.trim()))).toDomain());

  @override
  Future<Result<MemberDetails>> reactivate(int id) => _guard(() async => (await _api.reactivate(id)).toDomain());

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/user_admin/user_admin_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/user_admin_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_person_request.dart';
import 'package:echurch_desktop/data/services/api/model/user/password_reset_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_active_request.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_church_request.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_groups_request.dart';
import 'package:echurch_desktop/data/services/api/user_admin_api.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';

class UserAdminRepositoryRemote({required final UserAdminApi _userAdminApi}) implements UserAdminRepository {
  @override
  Future<Result<List<ManagedUser>>> list() async {
    try {
      final users = await _userAdminApi.list();
      return Result.ok([for (final user in users) user.toDomain()]);
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<PasswordReset>> resetPassword({required int userId, String? temporaryPassword}) async {
    try {
      final chosen = temporaryPassword?.isEmpty ?? true ? null : temporaryPassword;
      final reset = await _userAdminApi.resetPassword(userId, PasswordResetRequest(temporaryPassword: chosen));
      return Result.ok(reset.toDomain());
    } on DioException catch (e, st) {
      // 400: senha escolhida fora da regra / admin redefinindo a própria (mensagem do backend).
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<ManagedUser>> setActive({required int userId, required bool active}) async {
    try {
      final user = await _userAdminApi.setActive(userId, UserActiveRequest(active: active));
      return Result.ok(user.toDomain());
    } on DioException catch (e, st) {
      // 400: admin desativando a si mesmo (mensagem do backend).
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<ManagedUser>> setChurch({required int userId, required int churchId}) async {
    try {
      final user = await _userAdminApi.setChurch(userId, UserChurchRequest(churchId: churchId));
      return Result.ok(user.toDomain());
    } on DioException catch (e, st) {
      // 400: igreja inexistente (mensagem do backend).
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<ManagedUser>> updateGroups({required int userId, required Set<int> groupIds}) async {
    try {
      final user = await _userAdminApi.updateGroups(userId, UserGroupsRequest(groupIds: groupIds.toList()));
      return Result.ok(user.toDomain());
    } on DioException catch (e, st) {
      // 400: grupo inexistente / admin tirando o próprio acesso (mensagem do backend).
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<ManagedUser>> setPerson({required int userId, int? personId}) async {
    try {
      final user = await _userAdminApi.setPerson(userId, UserPersonRequest(personId: personId));
      return Result.ok(user.toDomain());
    } on DioException catch (e, st) {
      // 400: membro inexistente ou já ligado a outro usuário (mensagem do backend).
      return Result.error(e.toAppException(st));
    }
  }
}

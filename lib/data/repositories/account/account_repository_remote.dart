import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository.dart';
import 'package:echurch_desktop/data/services/api/account_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/auth/change_password_request.dart';

class AccountRepositoryRemote({required final AccountApi _accountApi}) implements AccountRepository {
  @override
  Future<Result<void>> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _accountApi.changePassword(ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword));
      return Result.done;
    } on DioException catch (e, st) {
      // 400 traz a mensagem do backend (senha atual incorreta, regra de força...).
      return Result.error(e.toAppException(st));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/auth/change_password_request.dart';
import 'package:retrofit/retrofit.dart';

part 'account_api.g.dart';

/// Endpoints da conta do usuário logado (`AuthResource`), no Dio principal:
/// Bearer automático e renovação da sessão no 401.
@RestApi()
abstract class AccountApi {
  factory AccountApi(Dio dio) = _AccountApi;

  @POST('/v1/auth/change-password')
  Future<void> changePassword(@Body() ChangePasswordRequest request);
}

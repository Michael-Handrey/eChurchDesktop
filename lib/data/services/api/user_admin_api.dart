import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/user/password_reset_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_active_request.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_church_request.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_groups_request.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_summary_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'user_admin_api.g.dart';

/// Administração de usuários (`UserResource`, só ROLE_ADMIN), no Dio principal:
/// Bearer automático e renovação da sessão no 401.
@RestApi()
abstract class UserAdminApi {
  factory UserAdminApi(Dio dio) = _UserAdminApi;

  @GET('/v1/users')
  Future<List<UserSummaryApiModel>> list();

  @POST('/v1/users/{id}/reset-password')
  Future<PasswordResetApiModel> resetPassword(@Path('id') int id, @Body() PasswordResetRequest request);

  @PUT('/v1/users/{id}/active')
  Future<UserSummaryApiModel> setActive(@Path('id') int id, @Body() UserActiveRequest request);

  @PUT('/v1/users/{id}/church')
  Future<UserSummaryApiModel> setChurch(@Path('id') int id, @Body() UserChurchRequest request);

  @PUT('/v1/users/{id}/groups')
  Future<UserSummaryApiModel> updateGroups(@Path('id') int id, @Body() UserGroupsRequest request);
}

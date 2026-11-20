import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/group/group_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'group_admin_api.g.dart';

/// Grupos e catálogo de permissões (`GroupResource`, só ROLE_ADMIN), no Dio principal.
@RestApi()
abstract class GroupAdminApi {
  factory GroupAdminApi(Dio dio) = _GroupAdminApi;

  @GET('/v1/groups')
  Future<List<GroupApiModel>> list();

  @POST('/v1/groups')
  Future<GroupApiModel> create(@Body() GroupRequest request);

  @PUT('/v1/groups/{id}')
  Future<GroupApiModel> update(@Path('id') int id, @Body() GroupRequest request);

  @DELETE('/v1/groups/{id}')
  Future<void> delete(@Path('id') int id);

  @GET('/v1/permissions')
  Future<List<String>> permissions();
}

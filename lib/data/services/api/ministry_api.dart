import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/ministry/ministry_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'ministry_api.g.dart';

/// Ministérios (`MinistryResource`): ler qualquer usuário; alterar Secretaria/Administrador.
@RestApi()
abstract class MinistryApi {
  factory MinistryApi(Dio dio) = _MinistryApi;

  /// `churchId` nulo = todas as igrejas do alcance; `inactive` inclui os desativados.
  @GET('/v1/ministries')
  Future<List<MinistryApiModel>> list({@Query('churchId') int? churchId, @Query('inactive') bool? inactive});

  @POST('/v1/ministries')
  Future<MinistryApiModel> create(@Body() MinistryInput request);

  @PUT('/v1/ministries/{id}')
  Future<MinistryApiModel> update(@Path('id') int id, @Body() MinistryInput request);

  @PUT('/v1/ministries/{id}/active')
  Future<MinistryApiModel> setActive(@Path('id') int id, @Body() MinistryActiveInput request);

  @GET('/v1/ministries/{id}/members')
  Future<List<MemberRowApiModel>> members(@Path('id') int id);

  @POST('/v1/ministries/{id}/members')
  Future<List<MemberRowApiModel>> addMembers(@Path('id') int id, @Body() MinistryMembersInput request);

  @POST('/v1/ministries/{id}/members/remove')
  Future<List<MemberRowApiModel>> removeMembers(@Path('id') int id, @Body() MinistryMembersInput request);
}

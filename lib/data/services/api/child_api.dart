import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/child/child_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'child_api.g.dart';

/// Crianças e Adolescentes (`ChildResource`): só Secretaria e Administrador.
@RestApi()
abstract class ChildApi {
  factory ChildApi(Dio dio) = _ChildApi;

  /// `churchId` nulo = todas do alcance; `ministryId` 0 = sem ministério; `status`: ACTIVE, INACTIVE, ALL.
  @GET('/v1/children')
  Future<ChildPageApiModel> search({
    @Query('churchId') int? churchId,
    @Query('ministryId') int? ministryId,
    @Query('text') String? text,
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/v1/children/guardian-options')
  Future<List<GuardianOptionApiModel>> guardianOptions(@Query('text') String text);

  @GET('/v1/children/{id}')
  Future<ChildApiModel> find(@Path('id') int id);

  @POST('/v1/children')
  Future<ChildApiModel> create(@Body() ChildInput request);

  @PUT('/v1/children/{id}')
  Future<ChildApiModel> update(@Path('id') int id, @Body() ChildInput request);

  @PUT('/v1/children/{id}/active')
  Future<ChildApiModel> setActive(@Path('id') int id, @Body() ChildActiveInput request);
}

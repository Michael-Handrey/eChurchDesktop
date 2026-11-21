import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/prayer/prayer_request_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'prayer_request_api.g.dart';

/// Pedidos de oração da equipe (`PrayerRequestResource`), no Dio principal.
/// Quais ações valem para cada pedido vêm em `actions` (a API decide).
@RestApi()
abstract class PrayerRequestApi {
  factory PrayerRequestApi(Dio dio) = _PrayerRequestApi;

  @GET('/v1/prayer-requests')
  Future<PrayerRequestPageApiModel> search({
    @Query('churchId') int? churchId,
    @Query('status') String? status,
    @Query('text') String? text,
    @Query('excluded') bool? excluded,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @POST('/v1/prayer-requests')
  Future<PrayerRequestApiModel> create(@Body() PrayerRequestInput request);

  @PUT('/v1/prayer-requests/{id}')
  Future<PrayerRequestApiModel> update(@Path('id') int id, @Body() PrayerRequestInput request);

  @POST('/v1/prayer-requests/in-vase')
  Future<List<PrayerRequestApiModel>> markInVase(@Body() PrayerRequestIds request);

  @POST('/v1/prayer-requests/in-vase/all')
  Future<List<PrayerRequestApiModel>> markAllNewInVase(@Body() PrayerRequestChurch request);

  @PUT('/v1/prayer-requests/{id}/reject')
  Future<PrayerRequestApiModel> reject(@Path('id') int id, @Body() PrayerRequestReject request);

  @PUT('/v1/prayer-requests/{id}/back-to-new')
  Future<PrayerRequestApiModel> backToNew(@Path('id') int id);

  @PUT('/v1/prayer-requests/{id}/exclude')
  Future<PrayerRequestApiModel> exclude(@Path('id') int id);

  @PUT('/v1/prayer-requests/{id}/restore')
  Future<PrayerRequestApiModel> restore(@Path('id') int id);
}

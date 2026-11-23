import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/dashboard/dashboard_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'dashboard_api.g.dart';

/// Painel inicial da igreja em uso (`DashboardResource`).
@RestApi()
abstract class DashboardApi {
  factory DashboardApi(Dio dio) = _DashboardApi;

  @GET('/v1/dashboard')
  Future<DashboardApiModel> dashboard(@Query('churchId') int churchId);
}

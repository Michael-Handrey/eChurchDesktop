import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/church/church_summary_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'church_api.g.dart';

/// Igrejas (`ChurchResource`), no Dio principal. Qualquer usuário autenticado.
@RestApi()
abstract class ChurchApi {
  factory ChurchApi(Dio dio) = _ChurchApi;

  /// Sede primeiro, depois as filiais em ordem alfabética.
  @GET('/v1/churches')
  Future<List<ChurchSummaryApiModel>> list();
}

import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/interceptors/auth_interceptor.dart';
import 'package:echurch_desktop/data/services/api/model/auth/login_request.dart';
import 'package:echurch_desktop/data/services/api/model/auth/refresh_token_request.dart';
import 'package:echurch_desktop/data/services/api/model/auth/token_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/auth/user_me_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

/// Endpoints de `AuthResource` (e-Church: `/api/v1/auth/**`).
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('/v1/auth/login')
  @Extra(AuthInterceptor.publicRoute)
  Future<TokenApiModel> login(@Body() LoginRequest request);

  @POST('/v1/auth/refresh')
  @Extra(AuthInterceptor.publicRoute)
  Future<TokenApiModel> refresh(@Body() RefreshTokenRequest request);

  /// [authorization] explícito: logo após o login o token ainda não está no storage.
  @GET('/v1/auth/me')
  Future<UserMeApiModel> me({@Header('Authorization') String? authorization});

  @POST('/v1/auth/logout')
  Future<void> logout(@Body() RefreshTokenRequest request);
}

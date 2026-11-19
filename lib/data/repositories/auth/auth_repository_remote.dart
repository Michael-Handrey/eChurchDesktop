import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/services/api/auth_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/auth_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/auth/login_request.dart';
import 'package:echurch_desktop/data/services/api/model/auth/refresh_token_request.dart';
import 'package:echurch_desktop/data/services/api/model/auth/token_api_model.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

class AuthRepositoryRemote({required final AuthApi _authApi}) implements AuthRepository {
  @override
  Future<Result<AuthSession>> login({required String login, required String password}) async {
    try {
      final tokens = await _authApi.login(LoginRequest(login: login, password: password));
      return Result.ok(await _sessionOf(tokens));
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 401) {
        return Result.error(InvalidCredentialsException(cause: e, stackTrace: st));
      }
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<AuthSession>> refresh({required String refreshToken}) async {
    try {
      final tokens = await _authApi.refresh(RefreshTokenRequest(refreshToken: refreshToken));
      return Result.ok(await _sessionOf(tokens));
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }

  @override
  Future<Result<void>> logout({required String refreshToken, String? accessToken}) async {
    try {
      await _authApi.logout(
        RefreshTokenRequest(refreshToken: refreshToken),
        authorization: accessToken == null ? null : 'Bearer $accessToken',
      );
      return Result.done;
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }

  Future<AuthSession> _sessionOf(TokenApiModel apiTokens) async {
    final tokens = apiTokens.toDomain();
    final user = await _authApi.me(authorization: '${apiTokens.tokenType} ${tokens.accessToken}');

    return AuthSession(
      accessToken: tokens.accessToken,
      accessTokenExpiresAt: tokens.accessTokenExpiresAt,
      refreshToken: tokens.refreshToken,
      refreshTokenExpiresAt: tokens.refreshTokenExpiresAt,
      user: user.toDomain(),
    );
  }
}

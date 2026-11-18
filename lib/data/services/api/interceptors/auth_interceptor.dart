import 'dart:async';

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/data/services/local/secure_storage_service.dart';
import 'package:echurch_desktop/data/services/local/storage_keys.dart';

class AuthInterceptor({required final SecureStorageService _storage}) extends Interceptor {
  static const publicRoute = <String, Object>{_publicRouteKey: true};

  static const _publicRouteKey = 'publicRoute';
  static const _authorization = 'Authorization';
  static const _sessionEndedStatus = {401, 403};

  final _log = AppLogger('AuthInterceptor');

  final _unauthorized = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorized.stream;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[_publicRouteKey] == true || options.headers.containsKey(_authorization)) {
      return handler.next(options);
    }

    try {
      final token = await _storage.fetch(StorageKeys.accessToken);
      if (token != null) {
        options.headers[_authorization] = 'Bearer $token';
      }
    } on Exception catch (e, st) {
      _log.error('Falha ao ler o token', error: e, stackTrace: st);
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_endsSession(err)) {
      _log.info('Backend recusou o token');
      _unauthorized.add(null);
    }
    handler.next(err);
  }

  bool _endsSession(DioException err) => _sessionEndedStatus.contains(err.response?.statusCode) && err.requestOptions.headers.containsKey(_authorization);

  void dispose() => _unauthorized.close();
}

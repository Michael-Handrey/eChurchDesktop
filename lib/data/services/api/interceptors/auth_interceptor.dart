import 'dart:async';

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

/// Renova a sessão; ver `AuthRefreshSessionUseCase.refresh`.
typedef SessionRefresher = Future<Result<AuthSession?>> Function({String? rejectedAccessToken});

/// Põe o Bearer nas rotas autenticadas e, num 401, renova a sessão uma vez e repete a requisição.
///
/// Só um 401 encerra a sessão (refresh recusado, ou 401 de novo com o token novo).
/// 403 é "sem permissão" para aquele recurso e segue como erro normal.
/// Falha de rede/servidor na renovação também segue como erro, sem derrubar a sessão.
class AuthInterceptor({
  required final AuthSessionRepository _sessions,
  required final SessionRefresher _refreshSession,

  /// Dio sem interceptors, para repetir a requisição já com o token novo.
  required final Dio _retryClient,
}) extends Interceptor {
  static const publicRoute = <String, Object>{_publicRouteKey: true};

  static const _publicRouteKey = 'publicRoute';

  /// Token que este interceptor colocou na requisição (para saber qual foi recusado).
  static const _sentTokenKey = 'authSentAccessToken';
  static const _authorization = 'Authorization';
  static const _unauthorizedStatus = 401;

  final _log = AppLogger('AuthInterceptor');

  final _unauthorized = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorized.stream;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[_publicRouteKey] == true || options.headers.containsKey(_authorization)) {
      return handler.next(options);
    }

    switch (await _sessions.fetch()) {
      case Ok(value: (:final session, remember: _)?):
        options.headers[_authorization] = 'Bearer ${session.accessToken}';
        options.extra[_sentTokenKey] = session.accessToken;
      case Ok():
        break;
      case Error(:final error):
        _log.error('Falha ao ler a sessão', error: error, stackTrace: error.stackTrace);
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final sentToken = options.extra[_sentTokenKey];

    if (err.response?.statusCode != _unauthorizedStatus || sentToken is! String) {
      return handler.next(err);
    }

    switch (await _refreshSession(rejectedAccessToken: sentToken)) {
      case Ok(value: final session?):
        return _retry(options, session.accessToken, handler);

      case Ok():
        _log.info('Backend recusou a sessão');
        _endSession();
        return handler.next(err);

      case Error(:final error):
        _log.warning('Não foi possível renovar a sessão agora', error: error, stackTrace: error.stackTrace);
        return handler.next(err);
    }
  }

  Future<void> _retry(RequestOptions options, String accessToken, ErrorInterceptorHandler handler) async {
    final data = options.data;
    final retry = options.copyWith(
      headers: {...options.headers, _authorization: 'Bearer $accessToken'},
      extra: {...options.extra, _sentTokenKey: accessToken},
      // FormData só pode ser enviado uma vez.
      data: data is FormData ? data.clone() : data,
    );

    try {
      handler.resolve(await _retryClient.fetch<dynamic>(retry));
    } on DioException catch (e) {
      if (e.response?.statusCode == _unauthorizedStatus) {
        _log.info('Backend recusou o token renovado');
        _endSession();
      }
      handler.next(e);
    }
  }

  void _endSession() {
    if (!_unauthorized.isClosed) _unauthorized.add(null);
  }

  void dispose() => _unauthorized.close();
}

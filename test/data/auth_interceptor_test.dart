import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/data/services/api/interceptors/auth_interceptor.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_fakes.dart';

/// Backend falso: responde [status] para qualquer token diferente de [validToken].
class _FakeBackend implements HttpClientAdapter {
  String validToken = 'access-2';
  int status = 401;
  final authorizations = <Object?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final authorization = options.headers['Authorization'];
    authorizations.add(authorization);
    final ok = authorization == 'Bearer $validToken';
    return ResponseBody.fromString(
      ok ? '{"ok":true}' : '{}',
      ok ? 200 : status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeBackend backend;
  late FakeAuthRepository authRepository;
  late AuthSessionRepositoryLocal sessions;
  late AuthInterceptor interceptor;
  late Dio dio;
  late int sessionsEnded;

  setUp(() async {
    backend = _FakeBackend();
    authRepository = FakeAuthRepository();
    sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
    await sessions.save(sessionOf('1'), remember: false);

    final retryClient = Dio()..httpClientAdapter = backend;
    interceptor = AuthInterceptor(
      sessions: sessions,
      refreshSession: AuthRefreshSessionUseCase(authRepository: authRepository, authSessionRepository: sessions).refresh,
      retryClient: retryClient,
    );
    dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'))
      ..httpClientAdapter = backend
      ..interceptors.add(interceptor);

    sessionsEnded = 0;
    interceptor.onUnauthorized.listen((_) => sessionsEnded++);
  });

  tearDown(() => interceptor.dispose());

  test('401 renova a sessão e repete a requisição com o token novo', () async {
    authRepository.nextRefresh().complete(Result.ok(sessionOf('2')));

    final response = await dio.get<dynamic>('/v1/members');

    expect(response.statusCode, 200);
    expect(backend.authorizations, ['Bearer access-1', 'Bearer access-2']);
    expect(sessionsEnded, 0);
  });

  test('requisições paralelas com 401 fazem um único refresh', () async {
    authRepository.nextRefresh().complete(Result.ok(sessionOf('2')));

    final responses = await Future.wait([dio.get<dynamic>('/v1/a'), dio.get<dynamic>('/v1/b'), dio.get<dynamic>('/v1/c')]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(authRepository.refreshCalls, hasLength(1));
  });

  test('refresh recusado encerra a sessão', () async {
    authRepository.nextRefresh().complete(const Result.error(UnauthorizedException()));

    await expectLater(dio.get<dynamic>('/v1/members'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(sessionsEnded, 1);
  });

  test('backend fora do ar no refresh não encerra a sessão', () async {
    authRepository.nextRefresh().complete(const Result.error(NetworkException()));

    await expectLater(dio.get<dynamic>('/v1/members'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(sessionsEnded, 0);
  });

  test('403 é falta de permissão: não renova nem encerra a sessão', () async {
    backend.status = 403;

    await expectLater(dio.get<dynamic>('/v1/members'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(authRepository.refreshCalls, isEmpty);
    expect(sessionsEnded, 0);
  });

  test('401 de novo com o token renovado encerra a sessão', () async {
    backend.validToken = 'nenhum';
    authRepository.nextRefresh().complete(Result.ok(sessionOf('2')));

    await expectLater(dio.get<dynamic>('/v1/members'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(sessionsEnded, 1);
  });

  test('rota pública não recebe token', () async {
    backend.validToken = 'x';
    backend.status = 200;

    await dio.post<dynamic>('/v1/auth/login', options: Options(extra: AuthInterceptor.publicRoute));

    expect(backend.authorizations.single, isNull);
  });
}

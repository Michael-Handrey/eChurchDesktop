import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_fakes.dart';

void main() {
  late FakeAuthRepository authRepository;
  late AuthSessionRepositoryLocal sessions;
  late AuthRefreshSessionUseCase useCase;

  setUp(() async {
    authRepository = FakeAuthRepository();
    sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
    useCase = AuthRefreshSessionUseCase(authRepository: authRepository, authSessionRepository: sessions);
    await sessions.save(sessionOf('1'), remember: true);
  });

  AuthSession? valueOf(Result<AuthSession?> result) => (result as Ok<AuthSession?>).value;

  test('renovações simultâneas usam um único refresh (o backend gira o token)', () async {
    final response = authRepository.nextRefresh();

    final first = useCase.refresh(rejectedAccessToken: 'access-1');
    final second = useCase.refresh(rejectedAccessToken: 'access-1');
    response.complete(Result.ok(sessionOf('2')));

    expect(valueOf(await first)?.accessToken, 'access-2');
    expect(valueOf(await second)?.accessToken, 'access-2');
    expect(authRepository.refreshCalls, ['refresh-1']);
  });

  test('token recusado que já foi renovado não renova de novo', () async {
    authRepository.nextRefresh().complete(Result.ok(sessionOf('2')));
    await useCase.refresh(rejectedAccessToken: 'access-1');

    final again = await useCase.refresh(rejectedAccessToken: 'access-1');

    expect(valueOf(again)?.accessToken, 'access-2');
    expect(authRepository.refreshCalls, hasLength(1));
  });

  test('refresh recusado pelo backend encerra a sessão', () async {
    authRepository.nextRefresh().complete(const Result.error(UnauthorizedException()));

    final result = await useCase.refresh(rejectedAccessToken: 'access-1');

    expect(result, isA<Ok<AuthSession?>>());
    expect(valueOf(result), isNull);
  });

  test('falha de rede mantém a sessão (erro transitório)', () async {
    authRepository.nextRefresh().complete(const Result.error(NetworkException()));

    final result = await useCase.refresh(rejectedAccessToken: 'access-1');

    expect(result, isA<Error<AuthSession?>>());
    expect(((await sessions.fetch()) as Ok).value?.session.accessToken, 'access-1');
  });

  test('logout durante a renovação não ressuscita a sessão e revoga os tokens novos', () async {
    final response = authRepository.nextRefresh();

    final refreshing = useCase.refresh(rejectedAccessToken: 'access-1');
    await Future<void>.delayed(Duration.zero);
    await sessions.delete();
    response.complete(Result.ok(sessionOf('2')));

    expect(valueOf(await refreshing), isNull);
    expect(((await sessions.fetch()) as Ok).value, isNull);
    expect(authRepository.logoutCalls.single.refreshToken, 'refresh-2');
  });
}

import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_change_password_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_fakes.dart';

class _FakeAccountRepository implements AccountRepository {
  Result<void> response = Result.done;
  final calls = <({String currentPassword, String newPassword})>[];

  @override
  Future<Result<void>> changePassword({required String currentPassword, required String newPassword}) async {
    calls.add((currentPassword: currentPassword, newPassword: newPassword));
    return response;
  }
}

void main() {
  late _FakeAccountRepository accounts;
  late FakeAuthRepository auth;
  late AuthChangePasswordUseCase useCase;

  setUp(() async {
    accounts = _FakeAccountRepository();
    auth = FakeAuthRepository();
    final sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
    await sessions.save(sessionOf('1', firstAccess: true), remember: true);
    useCase = AuthChangePasswordUseCase(
      accountRepository: accounts,
      authRefreshSessionUseCase: AuthRefreshSessionUseCase(authRepository: auth, authSessionRepository: sessions),
    );
  });

  test('troca a senha e renova a sessão sem a marca de primeiro acesso', () async {
    auth.nextRefresh().complete(Result.ok(sessionOf('2')));

    final result = await useCase.changePassword(currentPassword: 'provisoria', newPassword: 'Igreja#2026');

    expect(((result as Ok<AuthSessionUser?>).value)?.firstAccess, isFalse);
    expect(accounts.calls.single.newPassword, 'Igreja#2026');
    expect(auth.refreshCalls, ['refresh-1']);
  });

  test('senha recusada pelo backend não renova a sessão', () async {
    accounts.response = const Result.error(ValidationException('Senha atual incorreta.'));

    final result = await useCase.changePassword(currentPassword: 'errada', newPassword: 'Igreja#2026');

    expect((result as Error).error, isA<ValidationException>());
    expect(auth.refreshCalls, isEmpty);
  });

  test('senha trocada mas renovação falhou pede novo login', () async {
    auth.nextRefresh().complete(const Result.error(NetworkException()));

    final result = await useCase.changePassword(currentPassword: 'provisoria', newPassword: 'Igreja#2026');

    expect(result, isA<Ok<AuthSessionUser?>>());
    expect((result as Ok<AuthSessionUser?>).value, isNull);
  });
}

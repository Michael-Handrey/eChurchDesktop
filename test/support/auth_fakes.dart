import 'dart:async';

import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/services/local/secure_storage_service.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

AuthSession sessionOf(String tag, {Duration accessIn = const Duration(minutes: 15), bool firstAccess = false}) {
  final now = DateTime.now();
  return AuthSession(
    accessToken: 'access-$tag',
    accessTokenExpiresAt: now.add(accessIn),
    refreshToken: 'refresh-$tag',
    refreshTokenExpiresAt: now.add(const Duration(days: 14)),
    user: AuthSessionUser(login: 'maria', name: 'Maria Silva', firstAccess: firstAccess, churchId: 1),
  );
}

class FakeSecureStorage implements SecureStorageService {
  final values = <String, String>{};
  var failWrites = false;

  @override
  Future<String?> fetch(String key) async => values[key];

  @override
  Future<void> save({required String key, required String value}) async {
    if (failWrites) throw const StorageException();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FakeAuthRepository implements AuthRepository {
  /// Respostas do refresh, em ordem. Um [Completer] permite segurar a resposta.
  final refreshResponses = <Completer<Result<AuthSession>>>[];
  final refreshCalls = <String>[];
  final logoutCalls = <({String refreshToken, String? accessToken})>[];

  Completer<Result<AuthSession>> nextRefresh() {
    final completer = Completer<Result<AuthSession>>();
    refreshResponses.add(completer);
    return completer;
  }

  @override
  Future<Result<AuthSession>> login({required String login, required String password}) async => Result.ok(sessionOf('login'));

  @override
  Future<Result<AuthSession>> refresh({required String refreshToken}) {
    refreshCalls.add(refreshToken);
    return refreshResponses.removeAt(0).future;
  }

  @override
  Future<Result<void>> logout({required String refreshToken, String? accessToken}) async {
    logoutCalls.add((refreshToken: refreshToken, accessToken: accessToken));
    return Result.done;
  }
}

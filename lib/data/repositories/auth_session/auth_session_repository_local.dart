import 'dart:convert';

import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/data/services/local/model/auth_session_local_model.dart';
import 'package:echurch_desktop/data/services/local/secure_storage_service.dart';
import 'package:echurch_desktop/data/services/local/storage_keys.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

class AuthSessionRepositoryLocal({required final SecureStorageService _storage}) implements AuthSessionRepository {
  @override
  Future<Result<void>> delete() async {
    try {
      for (final key in StorageKeys.all) {
        await _storage.delete(key);
      }
      return Result.done;
    } on StorageException catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<StoredAuthSession?>> fetch() async {
    try {
      final accessToken = await _storage.fetch(StorageKeys.accessToken);
      final refreshToken = await _storage.fetch(StorageKeys.refreshToken);
      final rawSession = await _storage.fetch(StorageKeys.authSession);

      if (accessToken == null || refreshToken == null || rawSession == null) return Result.ok(null);

      final local = AuthSessionLocalModel.fromJson(jsonDecode(rawSession) as Map<String, dynamic>);

      return Result.ok((
        session: AuthSession(
          accessToken: accessToken,
          accessTokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(local.accessTokenExpiresAt),
          refreshToken: refreshToken,
          refreshTokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(local.refreshTokenExpiresAt),
          user: AuthSessionUser(login: local.login, name: local.name, firstAccess: local.firstAccess, churchId: local.churchId),
        ),
        remember: local.remember,
      ));
    } on StorageException catch (e) {
      return Result.error(e);
    } on FormatException catch (e, st) {
      // JSON corrompido/de versão antiga: descarta a sessão.
      await delete();
      return Result.error(StorageException(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> save(AuthSession session, {required bool remember}) async {
    try {
      await _storage.save(key: StorageKeys.accessToken, value: session.accessToken);
      await _storage.save(key: StorageKeys.refreshToken, value: session.refreshToken);

      final local = AuthSessionLocalModel(
        accessTokenExpiresAt: session.accessTokenExpiresAt.millisecondsSinceEpoch,
        refreshTokenExpiresAt: session.refreshTokenExpiresAt.millisecondsSinceEpoch,
        remember: remember,
        login: session.user.login,
        name: session.user.name,
        firstAccess: session.user.firstAccess,
        churchId: session.user.churchId,
      );
      await _storage.save(key: StorageKeys.authSession, value: jsonEncode(local.toJson()));

      return Result.done;
    } on StorageException catch (e) {
      await delete();
      return Result.error(e);
    }
  }
}

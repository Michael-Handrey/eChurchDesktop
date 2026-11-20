import 'dart:convert';

import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/data/services/local/model/auth_session_local_model.dart';
import 'package:echurch_desktop/data/services/local/secure_storage_service.dart';
import 'package:echurch_desktop/data/services/local/storage_keys.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:json_annotation/json_annotation.dart';

class AuthSessionRepositoryLocal({required final SecureStorageService _storage}) implements AuthSessionRepository {
  /// Limite de `DateTime` em ms; acima disso `fromMillisecondsSinceEpoch` lança erro.
  static const _maxEpochMillis = 8640000000000000;

  final _log = AppLogger('AuthSessionRepositoryLocal');

  StoredAuthSession? _current;

  /// `true` depois da primeira leitura do disco (ou de qualquer save/delete):
  /// a partir daí a memória é a fonte da verdade.
  var _loaded = false;

  @override
  Future<Result<StoredAuthSession?>> fetch() async {
    if (_loaded) return Result.ok(_current);

    try {
      final stored = await _read();
      // Um save/delete pode ter ocorrido durante a leitura do disco: ele vence.
      if (!_loaded) {
        _current = stored;
        _loaded = true;
      }
      return Result.ok(_current);
    } on StorageException catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> save(AuthSession session, {required bool remember}) {
    _current = (session: session, remember: remember);
    _loaded = true;
    return _persist(session, remember: remember);
  }

  @override
  Future<Result<bool>> replace({required AuthSession current, required AuthSession next}) async {
    // Verificação e troca sem `await` no meio: nenhuma outra operação intercala.
    final stored = _current;
    if (!_loaded || stored == null || stored.session.refreshToken != current.refreshToken) {
      return const Result.ok(false);
    }

    _current = (session: next, remember: stored.remember);

    return switch (await _persist(next, remember: stored.remember)) {
      Ok() => const Result.ok(true),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> delete() async {
    _current = null;
    _loaded = true;

    final failure = await _wipeStorage();
    return failure == null ? Result.done : Result.error(failure);
  }

  Future<Result<void>> _persist(AuthSession session, {required bool remember}) async {
    if (!remember) {
      // Garante que nenhuma sessão anterior "lembrada" continue no disco.
      final failure = await _wipeStorage();
      return failure == null ? Result.done : Result.error(failure);
    }

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
        roles: session.user.roles,
      );
      // Por último: sem este JSON a leitura considera a sessão incompleta e descarta.
      await _storage.save(key: StorageKeys.authSession, value: jsonEncode(local.toJson()));

      return Result.done;
    } on StorageException catch (e) {
      // Não deixa sessão parcial no disco; a memória continua valendo nesta execução.
      await _wipeStorage();
      return Result.error(e);
    }
  }

  Future<StoredAuthSession?> _read() async {
    final accessToken = await _storage.fetch(StorageKeys.accessToken);
    final refreshToken = await _storage.fetch(StorageKeys.refreshToken);
    final rawSession = await _storage.fetch(StorageKeys.authSession);

    if (accessToken == null || refreshToken == null || rawSession == null) {
      if (accessToken != null || refreshToken != null || rawSession != null) {
        _log.warning('Sessão incompleta no storage; descartando');
        await _wipeStorage();
      }
      return null;
    }

    try {
      final local = switch (jsonDecode(rawSession)) {
        final Map<String, dynamic> json => AuthSessionLocalModel.fromJson(json),
        _ => throw const FormatException('Sessão local não é um objeto JSON'),
      };

      return (
        session: AuthSession(
          accessToken: accessToken,
          accessTokenExpiresAt: _dateOf(local.accessTokenExpiresAt),
          refreshToken: refreshToken,
          refreshTokenExpiresAt: _dateOf(local.refreshTokenExpiresAt),
          user: AuthSessionUser(
            login: local.login,
            name: local.name,
            firstAccess: local.firstAccess,
            churchId: local.churchId,
            roles: local.roles ?? const [],
          ),
        ),
        remember: local.remember,
      );
    } on FormatException catch (e, st) {
      return _discardCorrupted(e, st);
    } on CheckedFromJsonException catch (e, st) {
      return _discardCorrupted(e, st);
    }
  }

  Future<StoredAuthSession?> _discardCorrupted(Object error, StackTrace stackTrace) async {
    // JSON corrompido/de versão antiga: trata como "sem sessão" (vai para o login).
    _log.warning('Sessão guardada inválida; descartando', error: error, stackTrace: stackTrace);
    await _wipeStorage();
    return null;
  }

  static DateTime _dateOf(int millis) {
    if (millis.abs() > _maxEpochMillis) throw FormatException('Data fora do intervalo: $millis');
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Apaga todas as chaves, mesmo que alguma falhe. Retorna a primeira falha.
  Future<StorageException?> _wipeStorage() async {
    StorageException? failure;
    for (final key in StorageKeys.all) {
      try {
        await _storage.delete(key);
      } on StorageException catch (e) {
        failure ??= e;
      }
    }
    if (failure != null) _log.error('Falha ao apagar a sessão do storage', error: failure, stackTrace: failure.stackTrace);
    return failure;
  }
}

import 'dart:convert';

import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/data/services/api/mappers/auth_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/auth/user_me_api_model.dart';
import 'package:echurch_desktop/data/services/local/storage_keys.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_fakes.dart';

void main() {
  test('/me com ROLE_ADMIN vira usuário administrador', () {
    final user = UserMeApiModel.fromJson({
      'login': 'admin',
      'name': 'Admin',
      'roles': ['ROLE_ADMIN', 'ROLE_USER'],
    }).toDomain();
    expect(user.isAdmin, isTrue);
    expect(
      UserMeApiModel.fromJson({
        'login': 'maria',
        'name': 'Maria',
        'roles': ['ROLE_SECRETARIA'],
      }).toDomain().isAdmin,
      isFalse,
    );
  });

  test('/me de backend antigo (sem roles) não quebra: usuário sem papéis', () {
    final user = UserMeApiModel.fromJson({'login': 'maria', 'name': 'Maria'}).toDomain();
    expect(user.roles, isEmpty);
    expect(user.isAdmin, isFalse);
  });

  test('papéis sobrevivem a um novo início do app', () async {
    final storage = FakeSecureStorage();
    final base = sessionOf('x');
    final session = AuthSession(
      accessToken: base.accessToken,
      accessTokenExpiresAt: base.accessTokenExpiresAt,
      refreshToken: base.refreshToken,
      refreshTokenExpiresAt: base.refreshTokenExpiresAt,
      user: const AuthSessionUser(login: 'admin', name: 'Admin', firstAccess: false, roles: [AuthSessionUser.adminRole]),
    );
    await AuthSessionRepositoryLocal(storage: storage).save(session, remember: true);

    final restored = await AuthSessionRepositoryLocal(storage: storage).fetch();
    final user = (restored as Ok<StoredAuthSession?>).value!.session.user;
    expect(user.isAdmin, isTrue);
  });

  test('sessão gravada por versão anterior (sem roles) continua válida', () async {
    final storage = FakeSecureStorage();
    await AuthSessionRepositoryLocal(storage: storage).save(sessionOf('x'), remember: true);
    final json = jsonDecode(storage.values[StorageKeys.authSession]!) as Map<String, dynamic>..remove('roles');
    storage.values[StorageKeys.authSession] = jsonEncode(json);

    final restored = await AuthSessionRepositoryLocal(storage: storage).fetch();
    final user = (restored as Ok<StoredAuthSession?>).value!.session.user;
    expect(user.login, 'maria');
    expect(user.roles, isEmpty);
  });
}

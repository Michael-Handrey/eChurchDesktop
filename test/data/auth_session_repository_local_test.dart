import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/data/services/local/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_fakes.dart';

void main() {
  late FakeSecureStorage storage;

  setUp(() => storage = FakeSecureStorage());

  test('sem "Lembrar-me" nada vai para o disco, mas a sessão vale em memória', () async {
    final repository = AuthSessionRepositoryLocal(storage: storage);

    await repository.save(sessionOf('1'), remember: false);

    expect(storage.values, isEmpty);
    final fetched = await repository.fetch();
    expect(fetched, isA<Ok>());
    expect((fetched as Ok).value?.session.accessToken, 'access-1');
  });

  test('sem "Lembrar-me" apaga uma sessão lembrada anterior do disco', () async {
    final repository = AuthSessionRepositoryLocal(storage: storage);
    await repository.save(sessionOf('1'), remember: true);
    expect(storage.values.keys, containsAll(StorageKeys.all));

    await repository.save(sessionOf('2'), remember: false);

    expect(storage.values, isEmpty);
  });

  test('com "Lembrar-me" a sessão sobrevive a um novo início do app', () async {
    await AuthSessionRepositoryLocal(storage: storage).save(sessionOf('1'), remember: true);

    final fetched = await AuthSessionRepositoryLocal(storage: storage).fetch();

    expect((fetched as Ok).value?.session.refreshToken, 'refresh-1');
  });

  test('JSON corrompido vira "sem sessão" e limpa o disco', () async {
    storage.values.addAll({StorageKeys.accessToken: 'a', StorageKeys.refreshToken: 'r', StorageKeys.authSession: '{não é json'});

    final fetched = await AuthSessionRepositoryLocal(storage: storage).fetch();

    expect((fetched as Ok).value, isNull);
    expect(storage.values, isEmpty);
  });

  test('JSON com campo faltando vira "sem sessão" (sem TypeError)', () async {
    storage.values.addAll({StorageKeys.accessToken: 'a', StorageKeys.refreshToken: 'r', StorageKeys.authSession: '{"login":"maria"}'});

    final fetched = await AuthSessionRepositoryLocal(storage: storage).fetch();

    expect((fetched as Ok).value, isNull);
    expect(storage.values, isEmpty);
  });

  test('JSON que não é objeto vira "sem sessão"', () async {
    storage.values.addAll({StorageKeys.accessToken: 'a', StorageKeys.refreshToken: 'r', StorageKeys.authSession: '[1,2]'});

    final fetched = await AuthSessionRepositoryLocal(storage: storage).fetch();

    expect((fetched as Ok).value, isNull);
  });

  test('sessão incompleta no disco é descartada', () async {
    storage.values[StorageKeys.accessToken] = 'a';

    final fetched = await AuthSessionRepositoryLocal(storage: storage).fetch();

    expect((fetched as Ok).value, isNull);
    expect(storage.values, isEmpty);
  });

  test('replace não altera nada se a sessão atual já não é a esperada', () async {
    final repository = AuthSessionRepositoryLocal(storage: storage);
    await repository.save(sessionOf('1'), remember: true);
    await repository.delete();

    final replaced = await repository.replace(current: sessionOf('1'), next: sessionOf('2'));

    expect((replaced as Ok).value, isFalse);
    expect(((await repository.fetch()) as Ok).value, isNull);
    expect(storage.values, isEmpty);
  });

  test('replace mantém o "Lembrar-me" da sessão atual', () async {
    final repository = AuthSessionRepositoryLocal(storage: storage);
    final first = sessionOf('1');
    await repository.save(first, remember: true);

    await repository.replace(current: first, next: sessionOf('2'));

    expect(storage.values[StorageKeys.accessToken], 'access-2');
  });

  test('falha ao gravar não deixa sessão parcial no disco', () async {
    final repository = AuthSessionRepositoryLocal(storage: storage);
    storage.failWrites = true;

    final saved = await repository.save(sessionOf('1'), remember: true);

    expect(saved, isA<Error>());
    expect(storage.values, isEmpty);
  });
}

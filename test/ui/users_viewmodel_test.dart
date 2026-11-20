import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/user_admin_fakes.dart';

void main() {
  late FakeUserAdminRepository repository;
  late FakeGroupAdminRepository groupRepository;
  late UsersViewModel viewModel;

  setUp(() async {
    repository = FakeUserAdminRepository();
    groupRepository = FakeGroupAdminRepository();
    viewModel = UsersViewModel(
      userAdminRepository: repository,
      groupAdminRepository: groupRepository,
      churchRepository: FakeChurchRepository(),
      sessionNotifier: sessionSignedInAs(admin),
    );
    await viewModel.load.execute();
  });

  test('carrega os usuários com grupos legíveis e marca o próprio usuário', () {
    expect(viewModel.rows, hasLength(3));
    final maria = viewModel.rows.firstWhere((row) => row.user.login == 'maria');
    expect(maria.groupsLabel, 'Secretaria, Usuário');
    expect(maria.isCurrentUser, isFalse);
    expect(viewModel.rows.firstWhere((row) => row.user.login == 'admin').isCurrentUser, isTrue);
  });

  test('busca por nome ou login, sem diferenciar maiúsculas', () {
    viewModel.setSearch('MARIA');
    expect(viewModel.rows.map((row) => row.user.login), ['maria']);
    viewModel.setSearch('joa');
    expect(viewModel.rows.map((row) => row.user.login), ['joao']);
    viewModel.setSearch('');
    expect(viewModel.rows, hasLength(3));
  });

  test('redefinir com senha gerada não envia senha e marca "senha provisória" na lista', () async {
    final maria = users[1];
    await viewModel.resetPassword.execute((user: maria, password: null));

    expect(repository.resetCalls.single, (userId: 2, temporaryPassword: null));
    expect(viewModel.resetPassword.result, isA<Ok<PasswordReset>>());
    expect(viewModel.rows.firstWhere((row) => row.user.id == 2).user.firstAccess, isTrue);
    expect(viewModel.rows.firstWhere((row) => row.user.id == 3).user.firstAccess, isFalse);
  });

  test('redefinir com senha escolhida envia a senha digitada', () async {
    await viewModel.resetPassword.execute((user: users[1], password: 'Escolhida@2026'));

    expect(repository.resetCalls.single.temporaryPassword, 'Escolhida@2026');
    final reset = (viewModel.resetPassword.result! as Ok<PasswordReset>).value;
    expect(reset.temporaryPassword, 'Escolhida@2026');
  });

  test('erro do backend chega à tela e não marca a lista', () async {
    repository.resetError = const ValidationException('A nova senha precisa ter um número.');
    await viewModel.resetPassword.execute((user: users[1], password: 'semnumero@A'));

    expect(viewModel.resetPassword.result, isA<Error<PasswordReset>>());
    expect(viewModel.rows.firstWhere((row) => row.user.id == 2).user.firstAccess, isFalse);
  });

  test('regras da senha usam o login de quem vai receber a senha', () {
    final maria = users[1];
    expect(viewModel.acceptsPassword('Maria@2026x', maria), isFalse, reason: 'contém o login "maria"');
    expect(viewModel.acceptsPassword('Prov1s@ria', maria), isTrue);
  });

  test('falha ao listar fica no resultado do comando', () async {
    repository.listError = const NetworkException();
    await viewModel.load.execute();
    expect(viewModel.load.result, isA<Error<void>>());
  });

  test('falha ao listar os grupos também falha a carga', () async {
    groupRepository.listError = const NetworkException();
    await viewModel.load.execute();
    expect(viewModel.load.result, isA<Error<void>>());
  });

  test('opções de grupo mostram o nome amigável e as permissões', () {
    final options = viewModel.groupOptions;
    expect(options.map((option) => option.label), ['Administrador', 'Secretaria', 'Usuário']);
    expect(options.first.permissionsLabel, 'Administração');
  });

  test('trocar grupos atualiza a linha do usuário', () async {
    await viewModel.updateAccess.execute((user: users[2], churchId: users[2].churchId, groupIds: {3, 2}));

    expect(repository.groupCalls.single.userId, 3);
    expect(repository.groupCalls.single.groupIds, {3, 2});
    expect(viewModel.updateAccess.result, isA<Ok<void>>());
    expect(viewModel.rows.firstWhere((row) => row.user.id == 3).groupsLabel, 'Secretaria, Usuário');
  });

  test('filtra por grupo e por "sem grupo", junto com a busca', () async {
    viewModel.setGroupFilter(const InGroup(2)); // USUARIO
    expect(viewModel.rows.map((row) => row.user.login), ['maria', 'joao']);
    expect(viewModel.isFiltering, isTrue);

    viewModel.setSearch('jo');
    expect(viewModel.rows.map((row) => row.user.login), ['joao']);

    viewModel.setSearch('');
    viewModel.setGroupFilter(const WithoutGroup());
    expect(viewModel.rows, isEmpty);

    await viewModel.updateAccess.execute((user: users[2], churchId: users[2].churchId, groupIds: {}));
    expect(viewModel.rows.map((row) => row.user.login), ['joao']);

    viewModel.setGroupFilter(const AllGroups());
    expect(viewModel.rows, hasLength(3));
    expect(viewModel.isFiltering, isFalse);
  });

  test('filtra por igreja; opções com a sede primeiro', () {
    expect(viewModel.churchFilterOptions.map((option) => option.label), ['Todas as igrejas', 'Sede - Rolândia', 'Filial - Londrina']);
    expect(viewModel.rows.firstWhere((row) => row.user.id == 2).churchLabel, 'Filial - Londrina');

    viewModel.setChurchFilter(1);
    expect(viewModel.rows.map((row) => row.user.login), ['admin', 'joao']);
    expect(viewModel.isFiltering, isTrue);

    viewModel.setGroupFilter(const InGroup(2)); // USUARIO, combinado com a igreja
    expect(viewModel.rows.map((row) => row.user.login), ['joao']);

    viewModel.setChurchFilter(null);
    viewModel.setGroupFilter(const AllGroups());
    expect(viewModel.rows, hasLength(3));
  });

  test('opções do filtro: todos, cada grupo e sem grupo', () {
    expect(viewModel.groupFilterOptions.map((option) => option.label), ['Todos os grupos', 'Administrador', 'Secretaria', 'Usuário', 'Sem grupo']);
  });

  test('grupo do filtro excluído volta para "todos" ao recarregar', () async {
    viewModel.setGroupFilter(const InGroup(3));
    groupRepository.stored = [
      for (final group in groupRepository.stored)
        if (group.id != 3) group,
    ];
    await viewModel.load.execute();
    expect(viewModel.groupFilter, const AllGroups());
  });

  test('desativar e reativar atualizam a linha', () async {
    await viewModel.setActive.execute((user: users[1], active: false));
    expect(repository.activeCalls.single, (userId: 2, active: false));
    expect(viewModel.rows.firstWhere((row) => row.user.id == 2).user.active, isFalse);

    await viewModel.setActive.execute((user: users[1], active: true));
    expect(viewModel.rows.firstWhere((row) => row.user.id == 2).user.active, isTrue);
  });

  test('erro ao trocar grupos (ex.: admin tirando o próprio acesso) não mexe na lista', () async {
    repository.groupsError = const ValidationException('Você não pode tirar o seu próprio acesso de administrador.');
    await viewModel.updateAccess.execute((user: users[0], churchId: users[0].churchId, groupIds: {}));

    expect(viewModel.updateAccess.result, isA<Error<void>>());
    expect(viewModel.rows.firstWhere((row) => row.user.id == 1).groupsLabel, 'Administrador');
  });

  test('trocar a igreja envia só a igreja quando os grupos não mudam', () async {
    final joao = users[2];
    await viewModel.updateAccess.execute((user: joao, churchId: 3, groupIds: {...joao.groupIds}));

    expect(repository.churchCalls.single, (userId: 3, churchId: 3));
    expect(repository.groupCalls, isEmpty);
    expect(viewModel.rows.firstWhere((row) => row.user.id == 3).churchLabel, 'Filial - Maringá');
  });

  test('igreja e grupos mudando juntos: as duas alterações são enviadas', () async {
    final joao = users[2];
    await viewModel.updateAccess.execute((user: joao, churchId: 2, groupIds: {2, 3}));

    expect(repository.churchCalls.single.churchId, 2);
    expect(repository.groupCalls.single.groupIds, {2, 3});
    expect(viewModel.updateAccess.result, isA<Ok<void>>());
  });

  test('falha ao trocar a igreja não envia os grupos', () async {
    repository.churchError = const ValidationException('Igreja não encontrada. Atualize a lista e tente de novo.');
    final joao = users[2];
    await viewModel.updateAccess.execute((user: joao, churchId: 2, groupIds: {2, 3}));

    expect(viewModel.updateAccess.result, isA<Error<void>>());
    expect(repository.groupCalls, isEmpty);
  });

  test('igrejas carregadas para o diálogo de acesso', () {
    expect(viewModel.churches.map((church) => church.name), ['Sede - Rolândia', 'Filial - Londrina', 'Filial - Maringá']);
  });
}

import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';
import 'package:echurch_desktop/ui/ministries/ministries_screen.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:echurch_desktop/ui/ministries/ministries_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/user_admin_fakes.dart';

class _FakeMinistries implements MinistryRepository {
  /// [canEdit]: o que a API diria para quem está logado (Secretaria, ou o líder do ministério).
  _FakeMinistries({bool canEdit = true})
    : stored = [
        Ministry(id: 2, type: 'Ministério de Jovens', name: 'Filhos da Promessa', churchId: 1, leaderId: 10, leaderName: 'Ana Souza', memberCount: 2, canEditMembers: canEdit),
        const Ministry(id: 6, type: 'Ministério de Louvor', name: 'Shekinah', churchId: 1, memberCount: 0, active: false),
      ];

  List<Ministry> stored;
  final candidateSearches = <(int, String)>[];
  final added = <int>[];
  final searches = <({int? churchId, bool includeInactive})>[];
  final saved = <(int?, MinistryDraft)>[];
  var memberRows = <MemberRow>[
    const MemberRow(id: 10, name: 'Ana Souza', status: MemberStatus.active),
    const MemberRow(id: 11, name: 'Bruno Lima', status: MemberStatus.active),
  ];
  final removed = <int>[];
  AppException? saveError;

  @override
  Future<Result<List<Ministry>>> list({int? churchId, bool includeInactive = false}) async {
    searches.add((churchId: churchId, includeInactive: includeInactive));
    return Result.ok([
      for (final ministry in stored)
        if (includeInactive || ministry.active) ministry,
    ]);
  }

  @override
  Future<Result<Ministry>> save(int? id, MinistryDraft draft) async {
    if (saveError case final error?) return Result.error(error);
    saved.add((id, draft));
    return Result.ok(Ministry(id: id ?? 99, type: draft.type, name: draft.name, churchId: draft.churchId));
  }

  @override
  Future<Result<Ministry>> setActive(int id, bool active) async => Result.ok(stored.firstWhere((item) => item.id == id));

  @override
  Future<Result<List<MemberRow>>> members(int id) async => Result.ok(memberRows);

  @override
  Future<Result<List<MinistryCandidate>>> candidates(int id, String text) async {
    candidateSearches.add((id, text));
    return const Result.ok([MinistryCandidate(id: 12, name: 'Carla Dias', role: 'DIACONISA', church: 'Sede - Rolândia')]);
  }

  @override
  Future<Result<List<MemberRow>>> addMembers(int id, List<int> personIds) async {
    added.addAll(personIds);
    return Result.ok(memberRows);
  }

  @override
  Future<Result<List<MemberRow>>> removeMembers(int id, List<int> personIds) async {
    removed.addAll(personIds);
    memberRows = [
      for (final member in memberRows)
        if (!personIds.contains(member.id)) member,
    ];
    return Result.ok(memberRows);
  }
}

class _FakeMembers implements MemberRepository {
  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) async => const Result.ok(
    MemberPage(
      items: [MemberRow(id: 10, name: 'Ana Souza', status: MemberStatus.active, churchName: 'Sede - Rolândia')],
      total: 1,
      page: 0,
      size: 8,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _consulta = AuthSessionUser(login: 'joao', name: 'João', firstAccess: false, churchId: 1, roles: ['ROLE_USER']);
const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);
const _lider = AuthSessionUser(login: 'ana', name: 'Ana', firstAccess: false, churchId: 1, roles: [AuthSessionUser.ministryLeaderRole]);

void main() {
  late _FakeMinistries repository;

  Future<MinistriesViewModel> viewModelFor(AuthSessionUser user, {WidgetTester? tester}) async {
    repository = _FakeMinistries(canEdit: user.canManage || user.isMinistryLeader);
    final session = sessionSignedInAs(user);
    final churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(), sessionNotifier: session);
    final viewModel = MinistriesViewModel(repository: repository, members: _FakeMembers(), churchContext: churchContext, session: session);
    Future<void> settle() async {
      await pumpEventQueue();
      viewModel.init();
      await pumpEventQueue();
    }

    tester == null ? await settle() : await tester.runAsync(settle);
    return viewModel;
  }

  Future<MinistriesViewModel> pumpScreen(WidgetTester tester, AuthSessionUser user) async {
    tester.view.physicalSize = const Size(1900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = await viewModelFor(user, tester: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MinistriesScreen(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  test('lista os ativos da igreja em uso; as abas Inativos e Todos buscam com os desativados', () async {
    final viewModel = await viewModelFor(_secretaria);
    expect(repository.searches.single, (churchId: 1, includeInactive: false));
    expect(viewModel.ministries.map((item) => item.name), ['Filhos da Promessa']);

    viewModel.setTab(MinistryTab.all);
    await pumpEventQueue();
    expect(repository.searches.last, (churchId: 1, includeInactive: true));
    expect(viewModel.ministries, hasLength(2));

    viewModel.setTab(MinistryTab.inactive);
    await pumpEventQueue();
    expect(viewModel.ministries.map((item) => item.name), ['Shekinah']);
  });

  testWidgets('secretaria cadastra, edita e desativa; quem só consulta só vê os membros', (tester) async {
    await pumpScreen(tester, _secretaria);
    expect(find.text('Novo ministério'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Desativar'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget, reason: 'líder');

    await tester.pumpWidget(const SizedBox());
    await pumpScreen(tester, _consulta);
    expect(find.text('Novo ministério'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Membros'), findsWidgets);
  });

  testWidgets('cadastrar: só com nome e tipo; o erro da API fica no diálogo', (tester) async {
    await pumpScreen(tester, _secretaria);
    await tester.tap(find.text('Novo ministério'));
    await tester.pumpAndSettle();

    FilledButton save() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Cadastrar'));
    expect(save().onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Nome *'), 'Águas Cristalinas');
    await tester.enterText(find.widgetWithText(TextField, 'Tipo *'), 'Círculo de Oração');
    await tester.pump();
    expect(save().onPressed, isNotNull);

    repository.saveError = const ValidationException('O líder e o vice-líder precisam ser pessoas diferentes.');
    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.text('O líder e o vice-líder precisam ser pessoas diferentes.'), findsOneWidget);

    repository.saveError = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(repository.saved.single.$2, (type: 'Círculo de Oração', name: 'Águas Cristalinas', churchId: 1, leaderId: null, viceLeaderId: null));
    expect(find.text('Ministério cadastrado.'), findsOneWidget);
  });

  testWidgets('membros: o líder não tem o botão de tirar; os outros saem', (tester) async {
    await pumpScreen(tester, _secretaria);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Membros').first);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(find.text('2 membros'), findsOneWidget);
    expect(find.byTooltip('Tirar do ministério'), findsOneWidget, reason: 'só o Bruno; a Ana é a líder');
    await tester.tap(find.byTooltip('Tirar do ministério'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(repository.removed, [11]);
    expect(find.text('1 membro'), findsOneWidget);
  });

  testWidgets('líder: vê os que lidera, inclui (nome, cargo e igreja) e tira membros, sem editar o ministério', (tester) async {
    await pumpScreen(tester, _lider);
    expect(find.textContaining('Os ministérios que você lidera'), findsOneWidget);
    expect(find.text('Novo ministério'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Desativar'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Membros').first);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tirar do ministério'), findsOneWidget);

    final field = find.descendant(of: find.byType(LookupField<MinistryCandidate>), matching: find.byType(TextField));
    await tester.enterText(field, 'c');
    await tester.enterText(field, 'car');
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(repository.candidateSearches.last, (2, 'car'));
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.text('DIACONISA · Sede - Rolândia'), findsOneWidget);

    await tester.tap(find.text('Carla Dias'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(repository.added, [12]);
  });

  testWidgets('quem só consulta abre os membros sem incluir nem tirar', (tester) async {
    await pumpScreen(tester, _consulta);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Membros').first);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.byType(LookupField<MinistryCandidate>), findsNothing);
    expect(find.byTooltip('Tirar do ministério'), findsNothing);
  });

  test('sem ministério que lidera: aviso próprio', () async {
    final viewModel = await viewModelFor(_lider);
    expect(viewModel.onlyLeads, isTrue);
    expect((await viewModelFor(_secretaria)).onlyLeads, isFalse);
  });

  test('nome, cargo e igreja do candidato', () {
    expect(const MinistryCandidate(id: 1, name: 'A', role: 'DIÁCONO', church: 'Sede').details, 'DIÁCONO · Sede');
    expect(const MinistryCandidate(id: 1, name: 'A', church: 'Sede').details, 'Sede');
    expect(const MinistryCandidate(id: 1, name: 'A').details, isNull);
  });
}

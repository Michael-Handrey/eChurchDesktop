import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/prayer_request/prayer_request_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_screen.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/user_admin_fakes.dart';

const _newActions = {PrayerRequestAction.edit, PrayerRequestAction.inVase, PrayerRequestAction.reject};

/// Repositório falso: as ações de cada pedido são as que a API devolveria para a secretaria
/// (o teste de quem só consulta zera as ações, como a API faz).
class _FakePrayerRequestRepository implements PrayerRequestRepository {
  _FakePrayerRequestRepository({required bool canManage}) {
    if (!canManage) stored = [for (final item in stored) _copy(item, actions: const {})];
  }

  List<PrayerRequest> stored = [
    PrayerRequest(id: 1, requesterName: 'Ana Souza', description: 'Saúde da mãe', requestDate: DateTime(2026, 11, 20), status: PrayerRequestStatus.newRequest, churchId: 1, churchName: 'Sede - Rolândia', createdByName: 'Maria', actions: _newActions),
    PrayerRequest(id: 2, requesterName: 'Visitante', description: 'Pela família', requestDate: DateTime(2026, 11, 19), status: PrayerRequestStatus.newRequest, fromCommunity: true, actions: const {PrayerRequestAction.inVase, PrayerRequestAction.reject}),
    PrayerRequest(id: 3, requesterName: 'Pedro Lima', description: 'Emprego', requestDate: DateTime(2026, 11, 18), status: PrayerRequestStatus.inVase, churchId: 1, printedAt: DateTime(2026, 11, 19)),
    PrayerRequest(id: 4, requesterName: 'Ofensa', description: 'Texto que não condiz', requestDate: DateTime(2026, 11, 10), status: PrayerRequestStatus.rejected, churchId: 1, rejectionReason: 'Ofensivo', actions: const {PrayerRequestAction.exclude}),
  ];
  final searches = <({int? churchId, PrayerRequestStatus? status, String? text, bool excluded})>[];
  final created = <PrayerRequestDraft>[];
  final inVase = <Set<int>>[];
  final allInVase = <int>[];
  final rejected = <({int id, String? reason})>[];
  final excluded = <int>[];
  AppException? error;

  static PrayerRequest _copy(PrayerRequest item, {PrayerRequestStatus? status, Set<PrayerRequestAction>? actions}) => PrayerRequest(
    id: item.id,
    requesterName: item.requesterName,
    description: item.description,
    requestDate: item.requestDate,
    status: status ?? item.status,
    fromCommunity: item.fromCommunity,
    churchId: item.churchId,
    churchName: item.churchName,
    createdByName: item.createdByName,
    rejectionReason: item.rejectionReason,
    actions: actions ?? item.actions,
  );

  @override
  Future<Result<PrayerRequestPage>> search({int? churchId, PrayerRequestStatus? status, String? text, bool excluded = false, int page = 0, int size = 20}) async {
    searches.add((churchId: churchId, status: status, text: text, excluded: excluded));
    if (error case final e?) return Result.error(e);
    final items = [
      for (final item in stored)
        if (status == null || item.status == status) item,
    ];
    return Result.ok(PrayerRequestPage(items: items, total: items.length, page: page, size: size));
  }

  @override
  Future<Result<PrayerRequest>> create(PrayerRequestDraft draft) async {
    created.add(draft);
    final request = PrayerRequest(id: 10, requesterName: draft.requesterName.trim(), description: draft.description.trim(), requestDate: draft.requestDate, status: PrayerRequestStatus.newRequest);
    stored = [request, ...stored];
    return Result.ok(request);
  }

  @override
  Future<Result<PrayerRequest>> update(int id, PrayerRequestDraft draft) async => Result.ok(stored.firstWhere((item) => item.id == id));

  @override
  Future<Result<List<PrayerRequest>>> markInVase(Set<int> ids) async {
    inVase.add(ids);
    stored = [for (final item in stored) ids.contains(item.id) ? _copy(item, status: PrayerRequestStatus.inVase, actions: const {}) : item];
    return Result.ok([
      for (final item in stored)
        if (ids.contains(item.id)) item,
    ]);
  }

  @override
  Future<Result<List<PrayerRequest>>> markAllNewInVase(int churchId) async {
    allInVase.add(churchId);
    final ids = {
      for (final item in stored)
        if (item.status == PrayerRequestStatus.newRequest) item.id,
    };
    return markInVase(ids);
  }

  @override
  Future<Result<PrayerRequest>> reject(int id, {String? reason}) async {
    rejected.add((id: id, reason: reason));
    return Result.ok(stored.firstWhere((item) => item.id == id));
  }

  @override
  Future<Result<PrayerRequest>> backToNew(int id) async => Result.ok(stored.firstWhere((item) => item.id == id));

  @override
  Future<Result<PrayerRequest>> exclude(int id) async {
    excluded.add(id);
    return Result.ok(stored.firstWhere((item) => item.id == id));
  }

  @override
  Future<Result<PrayerRequest>> restore(int id) async => Result.ok(stored.firstWhere((item) => item.id == id));
}

const _consulta = AuthSessionUser(login: 'joao', name: 'João', firstAccess: false, churchId: 1, roles: ['ROLE_USER']);
const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);
const _admin = AuthSessionUser(login: 'admin', name: 'Admin', firstAccess: false, churchId: 1, roles: [AuthSessionUser.adminRole]);

void main() {
  late _FakePrayerRequestRepository repository;

  /// ViewModel já carregado na igreja do usuário (sede).
  late ChurchContextNotifier churchContext;

  /// [reachable]: igrejas que o usuário alcança (o padrão é só a sede).
  Future<PrayerRequestsViewModel> viewModelFor(AuthSessionUser user, {WidgetTester? tester, List<ChurchSummary>? reachable}) async {
    repository = _FakePrayerRequestRepository(canManage: user.canManage);
    final session = sessionSignedInAs(user);
    churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(reachable ?? [churches.first]), sessionNotifier: session);
    final viewModel = PrayerRequestsViewModel(repository: repository, churchContext: churchContext, session: session)..init();
    Future<void> settle() async {
      await pumpEventQueue();
      await pumpEventQueue();
    }

    tester == null ? await settle() : await tester.runAsync(settle);
    return viewModel;
  }

  Future<PrayerRequestsViewModel> pumpScreen(WidgetTester tester, AuthSessionUser user, {List<ChurchSummary>? reachable}) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = await viewModelFor(user, tester: tester, reachable: reachable);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PrayerRequestsScreen(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  group('ViewModel', () {
    test('carrega os novos da igreja em uso', () async {
      final viewModel = await viewModelFor(_secretaria);
      expect(repository.searches.first, (churchId: 1, status: PrayerRequestStatus.newRequest, text: '', excluded: false));
      expect(viewModel.rows.map((row) => row.request.requesterName), ['Ana Souza', 'Visitante']);
    });

    test('aba de excluídos só para o administrador', () async {
      expect((await viewModelFor(_secretaria)).tabs, isNot(contains(PrayerRequestTab.excluded)));
      final admin = await viewModelFor(_admin);
      expect(admin.tabs, contains(PrayerRequestTab.excluded));

      admin.setTab(PrayerRequestTab.excluded);
      await pumpEventQueue();
      expect(repository.searches.last, (churchId: 1, status: null, text: '', excluded: true));
    });

    test('seleção só dos que podem ir para o vaso; marcar a página toda', () async {
      final viewModel = await viewModelFor(_secretaria);
      viewModel.setTab(PrayerRequestTab.all);
      await pumpEventQueue();
      expect(viewModel.rows.map((row) => row.selectable), [true, true, false, false]);

      viewModel.togglePageSelection(true);
      expect(viewModel.selectedIds, {1, 2});
      expect(viewModel.pageSelection, isTrue);
      viewModel.toggleSelection(viewModel.rows.first.request, false);
      expect(viewModel.pageSelection, isNull, reason: 'alguns marcados');
    });

    test('marcar todos no vaso: só na aba de novos e sem busca', () async {
      final viewModel = await viewModelFor(_secretaria);
      expect(viewModel.canMarkAll, isTrue);
      expect(viewModel.newCount, 2);

      await viewModel.markAllInVase.execute();
      expect(repository.allInVase, [1]);
      expect(viewModel.markAllInVase.result, isA<Ok<int>>());

      viewModel.setText('ana');
      expect(viewModel.canMarkAll, isFalse);
    });

    test('"Todas as igrejas": busca sem igreja, sem "marcar todos"; trocar o seletor desliga', () async {
      final viewModel = await viewModelFor(_secretaria, reachable: churches);
      expect(viewModel.canSeeAllChurches, isTrue);
      expect(viewModel.canMarkAll, isTrue);

      viewModel.setAllChurches(true);
      await pumpEventQueue();
      expect(repository.searches.last.churchId, isNull);
      expect(viewModel.canMarkAll, isFalse, reason: '"marcar todos" é por igreja');
      expect(viewModel.showChurchColumn, isTrue);

      churchContext.select(2);
      await pumpEventQueue();
      expect(viewModel.allChurches, isFalse);
      expect(repository.searches.last.churchId, 2);
    });

    test('quem alcança só uma igreja não tem o "Todas as igrejas"', () async {
      final viewModel = await viewModelFor(_secretaria);
      expect(viewModel.canSeeAllChurches, isFalse);
    });

    test('quem só consulta não tem seleção nem ações', () async {
      final viewModel = await viewModelFor(_consulta);
      expect(viewModel.canManage, isFalse);
      expect(viewModel.rows.every((row) => !row.selectable), isTrue);
      expect(viewModel.canMarkAll, isFalse);
    });
  });

  group('Tela', () {
    testWidgets('"Todas as igrejas" mostra a coluna Igreja (traço nos sem igreja)', (tester) async {
      await pumpScreen(tester, _secretaria, reachable: churches);
      expect(find.text('Igreja'), findsNothing);

      await tester.tap(find.text('Todas as igrejas'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(find.text('Igreja'), findsNWidgets(2), reason: 'título fixo e a cópia de altura zero que mede a coluna');
      expect(find.text('Sede - Rolândia'), findsOneWidget, reason: 'Ana; o Visitante (sem igreja) fica com traço');
      expect(find.textContaining('Marcar todos'), findsNothing);
    });

    testWidgets('ao rolar a lista, os títulos das colunas ficam no lugar', (tester) async {
      final viewModel = await pumpScreen(tester, _consulta);
      repository.stored = [
        for (var i = 1; i <= 20; i++) PrayerRequest(id: i, requesterName: 'Pessoa $i', description: 'Pedido $i', requestDate: DateTime(2026, 11, 20), status: PrayerRequestStatus.newRequest),
      ];
      await tester.runAsync(viewModel.load.execute);
      await tester.pumpAndSettle();

      final titleTop = tester.getTopLeft(find.text('Quem pediu').first).dy;
      final firstTop = tester.getTopLeft(find.text('Pessoa 1')).dy;
      await tester.drag(find.text('Pessoa 3'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Quem pediu').first).dy, titleTop);
      expect(tester.getTopLeft(find.text('Pessoa 1')).dy, lessThan(firstTop), reason: 'as linhas rolaram');
      expect(tester.getTopLeft(find.text('Quem pediu').first).dx, closeTo(tester.getTopLeft(find.text('Pessoa 1')).dx, 1), reason: 'título alinhado com a coluna');
    });

    testWidgets('secretaria vê seleção e só os botões que a API permite', (tester) async {
      await pumpScreen(tester, _secretaria);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3), reason: 'cabeçalho + 2 novos');
      expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget, reason: 'o da comunidade não tem editar');
      expect(find.widgetWithText(OutlinedButton, 'Rejeitar'), findsNWidgets(2));
      expect(find.text('Sem igreja'), findsNothing, reason: 'só nos detalhes; a coluna "Registrado por" já mostra a origem');
      expect(find.text('Comunidade (app)'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Marcar todos no vaso (2)'), findsOneWidget);
    });

    testWidgets('sem nada para selecionar, a coluna de seleção some', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria);
      viewModel.setTab(PrayerRequestTab.inVase);
      await tester.pumpAndSettle();
      expect(find.text('Pedro Lima'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('usuário de consulta só registra e vê', (tester) async {
      await pumpScreen(tester, _consulta);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Editar'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Novo pedido'), findsOneWidget);
    });

    testWidgets('registrar pedido: só libera com nome e pedido', (tester) async {
      await pumpScreen(tester, _consulta);
      await tester.tap(find.widgetWithText(FilledButton, 'Novo pedido'));
      await tester.pumpAndSettle();

      FilledButton register() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Registrar'));
      expect(register().onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Quem pediu'), 'Lucas Almeida');
      await tester.enterText(find.widgetWithText(TextField, 'Pedido'), 'Pela prova da faculdade');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
      await tester.pumpAndSettle();

      expect(repository.created.single.requesterName, 'Lucas Almeida');
      expect(repository.created.single.churchId, 1, reason: 'igreja em uso');
      expect(find.text('Pedido de oração registrado.'), findsOneWidget);
    });

    testWidgets('marcar os selecionados no vaso', (tester) async {
      await pumpScreen(tester, _secretaria);
      await tester.tap(find.byType(Checkbox).at(1)); // Ana
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Marcar 1 no vaso'));
      await tester.pumpAndSettle();

      expect(repository.inVase.single, {1});
      expect(find.text('1 pedido no vaso.'), findsOneWidget);
    });

    testWidgets('marcar todos no vaso pede confirmação', (tester) async {
      await pumpScreen(tester, _secretaria);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Marcar todos no vaso (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Marcar todos no vaso?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Marcar todos'));
      await tester.pumpAndSettle();
      expect(repository.allInVase, [1]);
      expect(find.text('2 pedidos no vaso.'), findsOneWidget);
    });

    testWidgets('rejeitar com motivo', (tester) async {
      await pumpScreen(tester, _secretaria);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Rejeitar').last); // Visitante (comunidade)
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Texto ofensivo.');
      await tester.tap(find.widgetWithText(FilledButton, 'Rejeitar'));
      await tester.pumpAndSettle();

      expect(repository.rejected.single, (id: 2, reason: 'Texto ofensivo.'));
      expect(find.text('Pedido de oração rejeitado.'), findsOneWidget);
    });

    testWidgets('excluir um rejeitado pede confirmação', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria);
      viewModel.setTab(PrayerRequestTab.rejected);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir o pedido da lista?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(repository.excluded, [4]);
      expect(find.text('Pedido excluído da lista.'), findsOneWidget);
    });

    testWidgets('detalhes mostram a origem e a igreja', (tester) async {
      await pumpScreen(tester, _secretaria);
      await tester.tap(find.text('Pela família'));
      await tester.pumpAndSettle();
      expect(find.text('Pedido de Visitante'), findsOneWidget);
      expect(find.text('Comunidade'), findsOneWidget);
      expect(find.text('· Sem igreja'), findsOneWidget);
    });

    testWidgets('erro ao carregar mostra a mensagem e permite tentar de novo', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria);
      repository.error = const NetworkException();
      await viewModel.load.execute();
      await tester.pumpAndSettle();
      expect(find.text('Tentar de novo'), findsOneWidget);
    });
  });
}

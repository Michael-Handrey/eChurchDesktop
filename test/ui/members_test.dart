import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/member_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/ui/members/members_screen.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/user_admin_fakes.dart';

class _FakeMemberRepository implements MemberRepository {
  List<MemberRow> stored = const [
    MemberRow(id: 1, name: 'Ana Souza', status: MemberStatus.active, ecclesiasticalRoleName: 'Diaconisa', phone: '(43) 99999-0001', birthDay: 15, birthMonth: 3),
    MemberRow(id: 2, name: 'Bruno Lima', status: MemberStatus.active, churchId: 2, churchName: 'Filial - Londrina'),
    MemberRow(id: 3, name: 'Carla Dias', status: MemberStatus.inactive, deactivationReason: DeactivationReason.movedAway),
  ];
  final searches = <({int? churchId, MemberStatus? status, String? text, int? roleId, int page})>[];
  final deactivated = <({int id, DeactivationReason reason, String description})>[];
  final reactivated = <int>[];
  AppException? deactivateError;

  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) async {
    searches.add((churchId: churchId, status: status, text: text, roleId: ecclesiasticalRoleId, page: page));
    final items = [
      for (final item in stored)
        if (status == null || item.status == status) item,
    ];
    return Result.ok(MemberPage(items: items, total: items.length == 2 && status == MemberStatus.active ? 41 : items.length, page: page, size: size));
  }

  @override
  Future<Result<List<EcclesiasticalRoleOption>>> roles() async => const Result.ok([EcclesiasticalRoleOption(id: 7, name: 'Diácono')]);

  @override
  Future<Result<MemberDetails>> details(int id) async {
    final row = stored.firstWhere((item) => item.id == id);
    return Result.ok(MemberDetails(id: id, name: row.name, status: row.status, phone: row.phone, cpf: '123.456.789-00', ministryNames: const ['Louvor'], leaderships: const ['Vice-líder de Louvor'], ministerialRoleNames: const ['PRIMEIRO(A) TESOUREIRO(A)'], birthDate: DateTime(1980, 3, 15)));
  }

  @override
  Future<Result<MemberDetails>> deactivate(int id, {required DeactivationReason reason, required String description}) async {
    if (deactivateError case final error?) return Result.error(error);
    deactivated.add((id: id, reason: reason, description: description));
    return Result.ok(MemberDetails(id: id, name: '', status: MemberStatus.inactive));
  }

  @override
  Future<Result<MemberDetails>> reactivate(int id) async {
    reactivated.add(id);
    return Result.ok(MemberDetails(id: id, name: '', status: MemberStatus.active));
  }

  @override
  Future<Result<MemberFormOptions>> formOptions() => throw UnimplementedError();

  @override
  Future<Result<MemberDraft>> loadForEdit(int id) => throw UnimplementedError();

  @override
  Future<Result<int>> save(MemberDraft draft) => throw UnimplementedError();

  /// Casos de cadastro duplicado que a API devolveria (o botão aparece com a contagem).
  List<DuplicateGroup> duplicateGroups = const [];

  @override
  Future<Result<List<DuplicateGroup>>> duplicates() async => Result.ok(duplicateGroups);

  @override
  Future<Result<void>> mergeDuplicates({required int keepId, required int removeId, required Set<MergeField> takeFromRemoved}) => throw UnimplementedError();

  @override
  Future<Result<void>> dismissDuplicate(int personId, int otherPersonId) => throw UnimplementedError();

  /// Revisão de cônjuges que a API devolveria (o botão aparece com a contagem).
  SpouseReview spouseReviewResult = const SpouseReview();

  @override
  Future<Result<SpouseReview>> spouseReview() async => Result.ok(spouseReviewResult);

  @override
  Future<Result<void>> linkSpouses(List<SpouseLink> links) => throw UnimplementedError();

  @override
  Future<Result<void>> dismissSpouse(int personId, {int? candidateId}) => throw UnimplementedError();
}

const _consulta = AuthSessionUser(login: 'joao', name: 'João', firstAccess: false, churchId: 1, roles: ['ROLE_USER']);
const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);

void main() {
  late _FakeMemberRepository repository;

  late ChurchContextNotifier churchContext;

  /// [reachable]: igrejas que o usuário alcança (o padrão é só a sede).
  Future<MembersViewModel> viewModelFor(AuthSessionUser user, {WidgetTester? tester, List<ChurchSummary>? reachable}) async {
    repository = _FakeMemberRepository();
    final session = sessionSignedInAs(user);
    churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(reachable ?? [churches.first]), sessionNotifier: session);
    final viewModel = MembersViewModel(repository: repository, churchContext: churchContext, session: session)..init();
    Future<void> settle() async {
      await pumpEventQueue();
      await pumpEventQueue();
    }

    tester == null ? await settle() : await tester.runAsync(settle);
    return viewModel;
  }

  Future<MembersViewModel> pumpScreen(WidgetTester tester, AuthSessionUser user, {List<ChurchSummary>? reachable}) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = await viewModelFor(user, tester: tester, reachable: reachable);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MembersScreen(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  group('ViewModel', () {
    test('carrega os ativos da igreja em uso e os cargos para o filtro', () async {
      final viewModel = await viewModelFor(_secretaria);
      expect(repository.searches.single, (churchId: 1, status: MemberStatus.active, text: '', roleId: null, page: 0));
      expect(viewModel.rows.map((row) => row.name), ['Ana Souza', 'Bruno Lima']);
      expect(viewModel.roles.single.name, 'Diácono');
      expect(viewModel.rangeLabel, '1–2 de 41');
      expect(viewModel.hasNext, isTrue);
    });

    test('abas, cargo e páginas refazem a busca do começo', () async {
      final viewModel = await viewModelFor(_secretaria);
      viewModel.nextPage();
      await pumpEventQueue();
      expect(repository.searches.last.page, 1);

      viewModel.setRole(7);
      await pumpEventQueue();
      expect(repository.searches.last, (churchId: 1, status: MemberStatus.active, text: '', roleId: 7, page: 0));
      expect(viewModel.isFiltered, isTrue);

      viewModel.setTab(MemberTab.all);
      await pumpEventQueue();
      expect(repository.searches.last.status, isNull);
      expect(viewModel.rows, hasLength(3));
    });

    test('"Todas as igrejas": busca sem igreja; trocar o seletor volta para a igreja escolhida', () async {
      final viewModel = await viewModelFor(_secretaria, reachable: churches);
      expect(viewModel.canSeeAllChurches, isTrue);
      expect(viewModel.allChurches, isFalse);
      expect(repository.searches.last.churchId, 1);
      expect(viewModel.showChurchColumn, isFalse);

      viewModel.setAllChurches(true);
      await pumpEventQueue();
      expect(repository.searches.last.churchId, isNull);
      expect(viewModel.showChurchColumn, isTrue);
      expect(viewModel.churchName, isNull);

      churchContext.select(2);
      await pumpEventQueue();
      expect(viewModel.allChurches, isFalse);
      expect(repository.searches.last.churchId, 2);
    });

    test('quem alcança só uma igreja não tem o "Todas as igrejas"', () async {
      final viewModel = await viewModelFor(_consulta);
      expect(viewModel.canSeeAllChurches, isFalse);
      viewModel.setAllChurches(true);
      expect(viewModel.allChurches, isFalse);
    });

    test('desativar manda motivo e descrição e recarrega a lista', () async {
      final viewModel = await viewModelFor(_secretaria);
      final before = repository.searches.length;
      await viewModel.deactivate.execute((member: viewModel.rows.first, reason: DeactivationReason.transferred, description: 'Foi para Londrina'));
      await pumpEventQueue();
      expect(repository.deactivated.single, (id: 1, reason: DeactivationReason.transferred, description: 'Foi para Londrina'));
      expect(repository.searches.length, before + 1);
    });
  });

  group('Mapeamento', () {
    test('endereço numa linha e contato da versão reduzida no topo', () {
      const address = MemberAddressApiModel(streetType: 'STREET', streetName: 'das Flores', streetNumber: '120', districtName: 'Centro', cityName: 'Rolândia', stateAbbreviation: 'PR', postalCode: '86600-000');
      expect(address.toLine(), 'Rua das Flores, 120 - Centro, Rolândia/PR - CEP 86600-000');
      expect(const MemberAddressApiModel().toLine(), isNull);

      final summary = MemberDetailsApiModel.fromJson({'id': 5, 'name': ' Ana ', 'status': 'ACTIVE', 'phone': '4399', 'birthDay': 2, 'birthMonth': 9}).toDomain();
      expect(summary.name, 'Ana');
      expect(summary.phone, '4399');
      expect(summary.birthDate, isNull);
      expect(summary.birthMonth, 9);

      final full = MemberDetailsApiModel.fromJson({
        'id': 5,
        'status': 'INACTIVE',
        'birthDate': '1980-03-15',
        'gender': 'F',
        'contact': {'phone': '4311'},
        'deactivationReason': 'DECEASED',
      }).toDomain();
      expect(full.phone, '4311');
      expect(full.gender, 'Feminino');
      expect(full.birthDate, DateTime(1980, 3, 15));
      expect(full.deactivationReason, DeactivationReason.deceased);
    });
  });

  group('Tela', () {
    testWidgets('secretaria vê desativar nos ativos e reativar nos inativos', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('15/03'), findsOneWidget);
      expect(find.text('Desativar'), findsNWidgets(2));
      expect(find.text('Editar'), findsNWidgets(2), reason: 'editar em cada linha');

      viewModel.setTab(MemberTab.inactive);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.text('Carla Dias'), findsOneWidget);
      expect(find.text('Reativar'), findsOneWidget);
      expect(find.text('Desativar'), findsNothing);
    });

    testWidgets('em "Todas as igrejas" aparece a coluna Igreja', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria, reachable: churches);
      expect(find.text('Igreja'), findsNothing);

      await tester.tap(find.text('Todas as igrejas'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(viewModel.allChurches, isTrue);
      expect(find.text('Igreja'), findsNWidgets(2), reason: 'título fixo e a cópia de altura zero que mede a coluna');
      expect(find.text('Filial - Londrina'), findsOneWidget, reason: 'linha do Bruno');
    });

    testWidgets('ao rolar a lista, os títulos das colunas ficam no lugar', (tester) async {
      // Sem a coluna de botões: a fonte larga dos testes estica os botões além da largura mínima.
      final viewModel = await pumpScreen(tester, _consulta);
      repository.stored = [for (var i = 1; i <= 20; i++) MemberRow(id: i, name: 'Membro $i', status: MemberStatus.active)];
      await tester.runAsync(viewModel.load.execute);
      await tester.pumpAndSettle();

      final titleTop = tester.getTopLeft(find.text('Telefone').first).dy;
      final firstTop = tester.getTopLeft(find.text('Membro 1')).dy;
      await tester.drag(find.text('Membro 3'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Telefone').first).dy, titleTop);
      expect(tester.getTopLeft(find.text('Membro 1')).dy, lessThan(firstTop), reason: 'as linhas rolaram');
      expect(tester.getCenter(find.text('Cargo').first).dx, closeTo(tester.getCenter(find.text('—').first).dx, 1), reason: 'título alinhado com a coluna');
    });

    testWidgets('janela estreita: filtros vão para a segunda linha, sem estourar', (tester) async {
      await pumpScreen(tester, _secretaria, reachable: churches);
      final tabsTop = tester.getTopLeft(find.text('Ativos')).dy;
      expect(tester.getTopLeft(find.text('Todas as igrejas')).dy, closeTo(tabsTop, 12), reason: 'larga: tudo numa linha');

      tester.view.physicalSize = const Size(900, 900);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Todas as igrejas')).dy, greaterThan(tabsTop + 20), reason: 'estreita: filtros embaixo');
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('com cadastros duplicados, aparece o botão com a contagem (só para quem gerencia)', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria);
      expect(find.textContaining('Cadastros duplicados'), findsNothing);

      repository.duplicateGroups = const [
        DuplicateGroup(kind: DuplicateKind.cpf, records: []),
        DuplicateGroup(kind: DuplicateKind.cpf, records: []),
      ];
      await tester.runAsync(viewModel.loadDuplicateCount);
      await tester.pumpAndSettle();
      expect(find.text('Cadastros duplicados (2)'), findsOneWidget);
    });

    testWidgets('quem só consulta não tem botões de desativar/reativar', (tester) async {
      await pumpScreen(tester, _consulta);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Desativar'), findsNothing);
      expect(find.text('Reativar'), findsNothing);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('desativar só libera com motivo e descrição', (tester) async {
      await pumpScreen(tester, _secretaria);
      await tester.tap(find.text('Desativar').first);
      await tester.pumpAndSettle();

      FilledButton confirm() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Desativar'));
      expect(confirm().onPressed, isNull);

      await tester.tap(find.byType(DropdownButtonFormField<DeactivationReason>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mudou de cidade').last);
      await tester.pumpAndSettle();
      expect(confirm().onPressed, isNull, reason: 'falta a descrição');

      await tester.enterText(find.widgetWithText(TextField, 'Descrição'), '  Foi para Curitiba ');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Desativar'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(repository.deactivated.single, (id: 1, reason: DeactivationReason.movedAway, description: 'Foi para Curitiba'));
      expect(find.text('Ana Souza foi desativado(a).'), findsOneWidget);
    });

    testWidgets('erro da API fica no diálogo', (tester) async {
      await pumpScreen(tester, _secretaria);
      repository.deactivateError = const ValidationException('O membro já está inativo.');
      await tester.tap(find.text('Desativar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<DeactivationReason>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outro').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Teste');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Desativar'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(find.text('O membro já está inativo.'), findsOneWidget);
      expect(find.text('Desativar membro'), findsOneWidget, reason: 'diálogo continua aberto');
    });

    testWidgets('voltar para a lista (do formulário, por exemplo) mantém o texto da busca no campo', (tester) async {
      final viewModel = await pumpScreen(tester, _secretaria);
      await tester.enterText(find.byKey(const ValueKey('member-search')), 'ana');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pumpAndSettle();
      expect(viewModel.text, 'ana');

      // A lista sai da tela (formulário no lugar) e volta com o mesmo viewmodel.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MembersScreen(viewModel: viewModel)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'ana'), findsOneWidget, reason: 'campo e lista falam da mesma busca');
    });

    testWidgets('clicar no nome abre os detalhes buscados na API', (tester) async {
      await pumpScreen(tester, _secretaria);
      await tester.tap(find.text('Ana Souza'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(find.text('Louvor'), findsOneWidget);
      expect(find.text('123.456.789-00'), findsOneWidget);
      expect(find.text('15/03/1980'), findsOneWidget);

      // Ordem fixa, com "—" nos vazios (sem cargo e sem igreja neste membro): nada muda de lugar.
      double top(String label) => tester.getTopLeft(find.descendant(of: find.byType(AlertDialog), matching: find.text(label))).dy;
      expect(top('Igreja'), lessThan(top('Cargo')));
      expect(top('Cargo'), lessThan(top('Ministérios')));
      expect(top('Ministérios'), lessThan(top('Liderança')));
      expect(top('Liderança'), lessThan(top('Funções')));
      expect(top('Funções'), lessThan(top('Batismo')));
      expect(find.text('Vice-líder de Louvor'), findsOneWidget);
      expect(find.text('PRIMEIRO(A) TESOUREIRO(A)'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });
  });
}

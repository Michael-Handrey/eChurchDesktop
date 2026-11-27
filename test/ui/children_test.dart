import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/child/child_repository.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/child/child.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';
import 'package:echurch_desktop/ui/children/children_screen.dart';
import 'package:echurch_desktop/ui/children/children_viewmodel.dart';
import 'package:echurch_desktop/ui/children/widgets/child_form_dialog.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/user_admin_fakes.dart';

final _today = DateTime(2026, 11, 26);

const _soldadinhos = Ministry(id: 5, type: 'Ministério Infantil', name: 'Soldadinhos de Cristo', churchId: 1, minAge: 3, maxAge: 10);
const _aviva = Ministry(id: 14, type: 'Ministério de Adolescentes', name: 'Projeto Aviva', churchId: 1, minAge: 11, maxAge: 17);

class _FakeMinistries implements MinistryRepository {
  @override
  Future<Result<List<Ministry>>> list({int? churchId, bool includeInactive = false}) async => const Result.ok([
    _aviva,
    Ministry(id: 2, type: 'Ministério de Jovens', name: 'Filhos da Promessa', churchId: 1),
    _soldadinhos,
    Ministry(id: 9, type: 'Antigo', name: 'Desativado', churchId: 1, minAge: 3, maxAge: 10, active: false),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeChildren implements ChildRepository {
  final searches = <({int? churchId, int? ministryId, String text, ChildTab tab})>[];
  final saved = <ChildDraft>[];
  AppException? saveError;
  ChildDetails? details;

  @override
  Future<Result<ChildPage>> search({int? churchId, int? ministryId, String text = '', ChildTab tab = ChildTab.active, int page = 0, int size = 20}) async {
    searches.add((churchId: churchId, ministryId: ministryId, text: text, tab: tab));
    return Result.ok(
      ChildPage(
        items: [
          ChildRow(id: 1, name: 'Davi Souza Augusto', birthDate: DateTime(2021, 5, 10), age: 5, ministryId: 5, ministryName: 'Soldadinhos de Cristo', guardians: 'Michael (Pai), Carla (Mãe)'),
          ChildRow(id: 2, name: 'Bebê Lima', birthDate: DateTime(2026, 3, 1), age: 0, guardians: 'Ana Lima (Mãe)'),
        ],
        total: 2,
        page: 0,
        size: 20,
      ),
    );
  }

  @override
  Future<Result<ChildDetails>> find(int id) async => Result.ok(details!);

  @override
  Future<Result<ChildDetails>> save(ChildDraft draft) async {
    if (saveError case final error?) return Result.error(error);
    saved.add(draft);
    return Result.ok(ChildDetails(id: draft.id ?? 99, name: draft.name, birthDate: draft.birthDate, age: 5));
  }

  @override
  Future<Result<ChildDetails>> setActive(int id, bool active) async => Result.ok(ChildDetails(id: id, name: 'Davi', birthDate: DateTime(2021, 5, 10), age: 5, active: active));

  @override
  Future<Result<List<GuardianOption>>> guardianOptions(String text) async => const Result.ok([
    GuardianOption(id: 10, name: 'Michael Handrey dos Santos Augusto', churchName: 'Sede - Rolândia', gender: 'M', spouseId: 11, spouseName: 'Carla Andressa Souza Leite', spouseGender: 'F'),
  ]);
}

const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);

void main() {
  late _FakeChildren repository;

  Future<ChildrenViewModel> viewModelFor({WidgetTester? tester}) async {
    repository = _FakeChildren();
    final session = sessionSignedInAs(_secretaria);
    final churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(), sessionNotifier: session);
    final viewModel = ChildrenViewModel(repository: repository, ministries: _FakeMinistries(), churchContext: churchContext);
    Future<void> settle() async {
      await pumpEventQueue();
      viewModel.init();
      await pumpEventQueue();
    }

    tester == null ? await settle() : await tester.runAsync(settle);
    return viewModel;
  }

  Future<ChildrenViewModel> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = await viewModelFor(tester: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChildrenScreen(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  Future<ChildrenViewModel> pumpForm(WidgetTester tester, {int? childId, ChildDetails? details}) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = await viewModelFor(tester: tester);
    repository.details = details;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChildFormDialog(viewModel: viewModel, childId: childId, today: _today),
        ),
      ),
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    return viewModel;
  }

  test('carrega a igreja em uso e só os ministérios ativos com faixa, em ordem de idade', () async {
    final viewModel = await viewModelFor();
    expect(repository.searches.single, (churchId: 1, ministryId: null, text: '', tab: ChildTab.active));
    expect(viewModel.childMinistries.map((ministry) => ministry.name), ['Soldadinhos de Cristo', 'Projeto Aviva']);
    expect(viewModel.ministriesFor(DateTime(2021, 5, 10), today: _today).single.name, 'Soldadinhos de Cristo');
    expect(viewModel.ministriesFor(DateTime(2014, 1, 1), today: _today).single.name, 'Projeto Aviva');
    expect(viewModel.ministriesFor(DateTime(2025, 1, 1), today: _today), isEmpty, reason: '0 a 2 anos');

    viewModel.setMinistryFilter(const NoMinistry());
    await pumpEventQueue();
    expect(repository.searches.last.ministryId, 0);
    viewModel.setMinistryFilter(const InMinistry(14));
    await pumpEventQueue();
    viewModel.setTab(ChildTab.all);
    await pumpEventQueue();
    expect(repository.searches.last, (churchId: 1, ministryId: 14, text: '', tab: ChildTab.all));
  });

  test('idade completa', () {
    expect(ageAt(DateTime(2021, 11, 27), _today), 4, reason: 'faz 5 amanhã');
    expect(ageAt(DateTime(2021, 11, 26), _today), 5);
  });

  testWidgets('lista: idade, ministério e responsáveis', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Crianças e Adolescentes'), findsOneWidget);
    expect(find.text('Davi Souza Augusto'), findsOneWidget);
    expect(find.text('5 anos'), findsOneWidget);
    expect(find.text('Soldadinhos de Cristo'), findsOneWidget);
    expect(find.text('Michael (Pai), Carla (Mãe)'), findsOneWidget);
    expect(find.text('0 anos'), findsOneWidget);
    expect(find.text('Nova criança'), findsOneWidget);
  });

  testWidgets('nova: ministério pela idade, responsável e a sugestão do cônjuge; salva com o parentesco', (tester) async {
    await pumpForm(tester);
    FilledButton save() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Cadastrar'));
    expect(save().onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('child-name')), 'Davi Souza Augusto');
    await tester.enterText(find.descendant(of: find.byKey(const ValueKey('child-birth')), matching: find.byType(TextField)), '10/05/2021');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    expect(find.text('Projeto Aviva (11 a 17 anos)'), findsNothing, reason: 'fora da idade');
    await tester.tap(find.text('Soldadinhos de Cristo (3 a 10 anos)').last);
    await tester.pumpAndSettle();

    final field = find.descendant(of: find.byType(LookupField<GuardianOption>), matching: find.byType(TextField));
    await tester.enterText(field, 'm');
    await tester.enterText(field, 'mic');
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Michael Handrey dos Santos Augusto').last);
    await tester.pumpAndSettle();

    expect(find.text('Incluir também Carla Andressa Souza Leite, cônjuge de Michael Handrey dos Santos Augusto?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Incluir'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('child-spouse-suggestion')), findsNothing);

    expect(save().onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    final draft = repository.saved.single;
    expect(draft.name, 'Davi Souza Augusto');
    expect(draft.birthDate, DateTime(2021, 5, 10));
    expect(draft.churchId, 1);
    expect(draft.ministryId, 5);
    expect([for (final guardian in draft.guardians) (guardian.personId, guardian.kinship)], [(10, Kinship.father), (11, Kinship.mother)]);
  });

  testWidgets('0 a 2 anos: sem ministério; 18 ou mais não entra', (tester) async {
    await pumpForm(tester);
    final birth = find.descendant(of: find.byKey(const ValueKey('child-birth')), matching: find.byType(TextField));
    await tester.enterText(birth, '01/03/2026');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum ministério para 0 anos (ex.: de 0 a 2 anos).'), findsOneWidget);

    await tester.enterText(birth, '01/01/2008');
    await tester.pumpAndSettle();
    expect(find.text('Com 18 anos ou mais, cadastre como membro'), findsOneWidget);
  });

  testWidgets('editar: carrega os responsáveis e mantém o ministério que saiu da faixa', (tester) async {
    await pumpForm(
      tester,
      childId: 1,
      details: ChildDetails(
        id: 1,
        name: 'Ana Clara',
        birthDate: DateTime(2015, 10, 1),
        age: 11,
        churchId: 1,
        ministryId: 5,
        ministryName: 'Soldadinhos de Cristo',
        guardians: const [ChildGuardian(personId: 11, name: 'Carla Andressa Souza Leite', kinship: Kinship.mother)],
      ),
    );
    expect(find.text('Editar cadastro'), findsOneWidget);
    expect(find.text('Carla Andressa Souza Leite'), findsOneWidget);
    expect(find.text('Soldadinhos de Cristo (3 a 10 anos) — fora da faixa'), findsOneWidget, reason: 'fez 11: a secretaria decide');

    repository.saveError = const ValidationException('Inclua pelo menos um responsável (membro).');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.text('Inclua pelo menos um responsável (membro).'), findsOneWidget, reason: 'erro da API no diálogo');

    repository.saveError = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(repository.saved.single.id, 1);
    expect(repository.saved.single.ministryId, 5);
  });

  test('sugestão de parentesco pelo sexo', () {
    expect(Kinship.parentFor('F'), Kinship.mother);
    expect(Kinship.parentFor('M'), Kinship.father);
    expect(Kinship.parentFor(null), Kinship.father);
    expect(Kinship.fromApi('GRANDMOTHER'), Kinship.grandmother);
    expect(Kinship.fromApi('?'), Kinship.other);
  });
}

import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/spouse_review_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/member/spouse_review_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';
import 'package:echurch_desktop/ui/members/spouse_review/spouse_review_screen.dart';
import 'package:echurch_desktop/ui/members/spouse_review/spouse_review_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

SpousePerson _person(int id, String name, {String? spouse, String? address}) => SpousePerson(id: id, name: name, writtenSpouse: spouse, maritalStatus: MaritalStatus.married, churchName: 'Sede - Rolândia', address: address);

SpouseSuggestion _suggestion(SpouseConfidence confidence, int a, String nameA, int b, String nameB, {bool sameAddress = true, List<String> notes = const []}) => SpouseSuggestion(
  confidence: confidence,
  kind: SpouseMatchKind.mutual,
  person: _person(a, nameA, spouse: nameB, address: 'Rua A, 1'),
  candidate: _person(b, nameB, spouse: nameA, address: sameAddress ? 'Rua A, 1' : 'Rua B, 2'),
  sameAddress: sameAddress,
  notes: notes,
);

class _FakeRepository implements MemberRepository {
  _FakeRepository(this.review);

  SpouseReview review;
  final linked = <SpouseLink>[];
  final dismissed = <(int, int?)>[];

  void _remove(Set<int> ids) => review = SpouseReview(
    suggestions: [
      for (final suggestion in review.suggestions)
        if (!ids.contains(suggestion.person.id)) suggestion,
    ],
    withoutSuggestion: [
      for (final person in review.withoutSuggestion)
        if (!ids.contains(person.id)) person,
    ],
  );

  @override
  Future<Result<SpouseReview>> spouseReview() async => Result.ok(review);

  @override
  Future<Result<void>> linkSpouses(List<SpouseLink> links) async {
    linked.addAll(links);
    _remove({for (final link in links) link.personId});
    return Result.done;
  }

  @override
  Future<Result<void>> dismissSpouse(int personId, {int? candidateId}) async {
    dismissed.add((personId, candidateId));
    _remove({personId});
    return Result.done;
  }

  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) async => const Result.ok(
    MemberPage(
      items: [
        MemberRow(id: 1, name: 'Ana Souza', status: MemberStatus.active),
        MemberRow(id: 50, name: 'João Souza', status: MemberStatus.active, churchName: 'Filial - Londrina'),
      ],
      total: 2,
      page: 0,
      size: 8,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeRepository repository;

  final review = SpouseReview(
    suggestions: [
      _suggestion(SpouseConfidence.high, 1, 'Ana Souza', 2, 'Bruno Souza'),
      _suggestion(SpouseConfidence.high, 3, 'Carla Dias', 4, 'Davi Dias'),
      _suggestion(SpouseConfidence.medium, 5, 'Eva Lima', 6, 'Fábio Lima', sameAddress: false, notes: ['Endereços diferentes.']),
    ],
    withoutSuggestion: [_person(7, 'Gil Rocha', spouse: 'Helena de Fora')],
  );

  Future<SpouseReviewViewModel> viewModelFor(SpouseReview review) async {
    repository = _FakeRepository(review);
    final viewModel = SpouseReviewViewModel(repository: repository)..init();
    await pumpEventQueue();
    return viewModel;
  }

  group('ViewModel', () {
    test('separa em lote (alta), um a um (média e baixa) e sem sugestão', () async {
      final viewModel = await viewModelFor(review);
      expect(viewModel.countOf(SpouseReviewTab.batch), 2);
      expect(viewModel.countOf(SpouseReviewTab.oneByOne), 1);
      expect(viewModel.countOf(SpouseReviewTab.withoutSuggestion), 1);
      expect(viewModel.review.pending, 4);
    });

    test('lote: vincula só os marcados', () async {
      final viewModel = await viewModelFor(review);
      viewModel.toggle(viewModel.batch.last, false);
      expect(viewModel.checkedCount, 1);

      await viewModel.linkBatch.execute();
      expect(repository.linked, [(personId: 1, spouseId: 2, addressFrom: null)]);
      expect(viewModel.batch.single.person.name, 'Carla Dias', reason: 'o desmarcado continua para revisar');
      expect(viewModel.changed, isTrue);
    });

    test('um a um: vincular com o endereço escolhido; "não é este" guarda o par', () async {
      final viewModel = await viewModelFor(review);
      viewModel.setAddressFrom(6);
      await viewModel.linkCurrent.execute();
      expect(repository.linked.single, (personId: 5, spouseId: 6, addressFrom: 6));

      final second = await viewModelFor(review);
      await second.dismissCurrent.execute();
      expect(repository.dismissed, [(5, 6)]);
    });

    test('sem sugestão: "não é membro" e vincular a um membro buscado', () async {
      final viewModel = await viewModelFor(review);
      final options = await viewModel.searchMembers('souza', excludeId: 1);
      expect(options.map((option) => option.name), ['João Souza'], reason: 'sem a própria pessoa');

      await viewModel.linkWith.execute((personId: 7, spouseId: 50));
      expect(repository.linked.single, (personId: 7, spouseId: 50, addressFrom: null));

      final other = await viewModelFor(review);
      await other.notMember.execute(7);
      expect(repository.dismissed, [(7, null)]);
    });
  });

  test('mapeamento da API', () {
    final mapped = SpouseReviewApiModel.fromJson({
      'suggestions': [
        {
          'confidence': 'MEDIUM',
          'kind': 'ONE_SIDE',
          'person': {'id': 1, 'name': ' Ana ', 'writtenSpouse': 'Bruno', 'maritalStatus': 'MARRIED', 'status': 'ACTIVE'},
          'candidate': {'id': 2, 'name': 'Bruno', 'maritalStatus': 'SINGLE', 'address': 'Rua A, 1'},
          'sameAddress': false,
          'notes': ['Endereços diferentes.'],
        },
      ],
      'withoutSuggestion': [
        {'id': 3, 'name': 'Gil', 'writtenSpouse': 'Helena'},
      ],
    }).toDomain();
    final suggestion = mapped.suggestions.single;
    expect(suggestion.confidence, SpouseConfidence.medium);
    expect(suggestion.kind, SpouseMatchKind.oneSide);
    expect(suggestion.person.name, 'Ana');
    expect(suggestion.candidate.maritalStatus, MaritalStatus.single);
    expect(mapped.pending, 2);
  });

  group('Tela', () {
    Future<(SpouseReviewViewModel, List<bool>)> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1700, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late SpouseReviewViewModel viewModel;
      await tester.runAsync(() async => viewModel = await viewModelFor(review));
      final closed = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpouseReviewScreen(viewModel: viewModel, onClose: closed.add),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (viewModel, closed);
    }

    testWidgets('lote com confirmação; um a um mostra avisos e a escolha do endereço', (tester) async {
      final (viewModel, closed) = await pumpScreen(tester);
      expect(find.text('Ana Souza  ⇄  Bruno Souza'), findsOneWidget);
      expect(find.text('Vincular os 2 marcados'), findsOneWidget);

      await tester.tap(find.text('Vincular os 2 marcados'));
      await tester.pumpAndSettle();
      expect(find.text('Vincular 2 casais?'), findsOneWidget);
      await tester.tap(find.text('Vincular').last);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(repository.linked, hasLength(2));

      viewModel.setTab(SpouseReviewTab.oneByOne);
      await tester.pumpAndSettle();
      expect(find.text('Eva Lima'), findsNWidgets(2), reason: 'nome e cônjuge escrito do outro');
      expect(find.text('Endereços diferentes.'), findsOneWidget);
      expect(find.text('Endereço para os dois:'), findsOneWidget);
      await tester.tap(find.text('O de Fábio'));
      await tester.pump();
      expect(viewModel.addressFrom, 6);

      await tester.tap(find.byTooltip('Voltar para a lista'));
      expect(closed, [true]);
    });

    testWidgets('sem sugestão: o cônjuge escrito em destaque, com a pergunta sobre ele', (tester) async {
      final (viewModel, _) = await pumpScreen(tester);
      viewModel.setTab(SpouseReviewTab.withoutSuggestion);
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Helena de Fora'));
      expect(title.style?.fontWeight, FontWeight.w600, reason: 'quem está sendo decidido fica em destaque');
      expect(find.text('cônjuge de Gil Rocha · Sede - Rolândia'), findsOneWidget);
      expect(find.text('Sim, buscar o cadastro'), findsOneWidget);

      await tester.tap(find.text('Sim, buscar o cadastro'));
      await tester.pumpAndSettle();
      expect(find.text('Cadastro de Helena de Fora'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Não é membro'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(repository.dismissed, [(7, null)]);
      expect(find.text('Marcado: Helena de Fora não é membro.'), findsOneWidget);
    });
  });
}

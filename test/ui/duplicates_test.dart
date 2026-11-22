import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/duplicate_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_form_api_model.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/members/duplicates/duplicates_screen.dart';
import 'package:echurch_desktop/ui/members/duplicates/duplicates_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

DuplicateRecord _record(int id, {MemberStatus status = MemberStatus.active, String? phone, String? email, String rg = '1234', DateTime? createdAt}) => DuplicateRecord(
  id: id,
  name: 'Ana Souza',
  status: status,
  createdAt: createdAt,
  values: {
    for (final field in MergeField.values) field: null,
    MergeField.name: 'Ana Souza',
    MergeField.cpf: '529.982.247-25',
    MergeField.rg: rg,
    MergeField.phone: phone,
    MergeField.email: email,
  },
);

class _FakeRepository implements MemberRepository {
  _FakeRepository(this.groups);

  List<DuplicateGroup> groups;
  final merges = <({int keepId, int removeId, Set<MergeField> take})>[];
  final dismissed = <(int, int)>[];

  @override
  Future<Result<List<DuplicateGroup>>> duplicates() async => Result.ok(groups);

  @override
  Future<Result<void>> mergeDuplicates({required int keepId, required int removeId, required Set<MergeField> takeFromRemoved}) async {
    merges.add((keepId: keepId, removeId: removeId, take: takeFromRemoved));
    groups = groups.skip(1).toList();
    return Result.done;
  }

  @override
  Future<Result<void>> dismissDuplicate(int personId, int otherPersonId) async {
    dismissed.add((personId, otherPersonId));
    groups = groups.skip(1).toList();
    return Result.done;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeRepository repository;

  Future<DuplicatesViewModel> viewModelFor(List<DuplicateGroup> groups) async {
    repository = _FakeRepository(groups);
    final viewModel = DuplicatesViewModel(repository: repository)..init();
    await pumpEventQueue();
    return viewModel;
  }

  final cpfGroup = DuplicateGroup(
    kind: DuplicateKind.cpf,
    records: [
      _record(10, phone: '(43) 3256-0000', createdAt: DateTime(2020)),
      _record(11, phone: '(43) 99999-0000', email: 'ana@exemplo.com', rg: '9999', createdAt: DateTime(2024)),
    ],
  );

  group('ViewModel', () {
    test('sugere o cadastro mais completo e, nos campos vazios, o valor do outro', () async {
      final viewModel = await viewModelFor([cpfGroup]);
      expect(viewModel.keepId, 11, reason: 'tem e-mail: mais completo');
      expect(viewModel.differences, [MergeField.rg, MergeField.phone, MergeField.email]);
      expect(viewModel.finalValue(MergeField.phone), '(43) 99999-0000');

      viewModel.setKeep(10);
      expect(viewModel.finalValue(MergeField.email), 'ana@exemplo.com', reason: 'o que fica não tem e-mail: vem do outro');
      expect(viewModel.finalValue(MergeField.phone), '(43) 3256-0000');
      viewModel.choose(MergeField.phone, 11);
      expect(viewModel.finalValue(MergeField.phone), '(43) 99999-0000');
    });

    test('ativo fica na frente do inativo, mesmo menos completo', () async {
      final viewModel = await viewModelFor([
        DuplicateGroup(
          kind: DuplicateKind.cpf,
          records: [
            _record(10),
            _record(11, status: MemberStatus.inactive, email: 'a@b.com'),
          ],
        ),
      ]);
      expect(viewModel.keepId, 10);
    });

    test('juntar manda o que fica, o que sai e os campos vindos do outro; recarrega', () async {
      final viewModel = await viewModelFor([cpfGroup]);
      viewModel.setKeep(10);
      viewModel.choose(MergeField.phone, 11);
      await viewModel.merge.execute();

      final merge = repository.merges.single;
      expect((merge.keepId, merge.removeId), (10, 11));
      expect(merge.take, {MergeField.email, MergeField.phone});
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.changed, isTrue);
    });

    test('"não são a mesma pessoa" só para nome e nascimento', () async {
      final viewModel = await viewModelFor([
        cpfGroup,
        DuplicateGroup(kind: DuplicateKind.nameBirth, records: [_record(20), _record(21)]),
      ]);
      await viewModel.dismiss.execute();
      expect(repository.dismissed, isEmpty, reason: 'caso atual é de mesmo CPF');

      viewModel.next();
      await viewModel.dismiss.execute();
      expect(repository.dismissed, [(20, 21)]);
    });
  });

  test('mapeamento: CPF com máscara, endereço numa linha e cargos', () {
    final record = DuplicateMemberApiModel.fromJson({
      'person': {
        'id': 10,
        'name': 'Ana Souza',
        'cpf': '52998224725',
        'status': 'ACTIVE',
        'address': {'streetType': 'STREET', 'streetName': 'das Flores', 'streetNumber': '120', 'districtName': 'Centro', 'cityName': 'Rolândia', 'stateAbbreviation': 'PR', 'postalCode': '86600000'},
        'ministryNames': ['Louvor'],
        'churchName': 'Sede - Rolândia',
      },
      'createdAt': '2024-05-01T10:00:00',
      'positions': ['Líder do ministério Louvor'],
    }).toDomain();
    expect(record.values[MergeField.cpf], '529.982.247-25');
    expect(record.values[MergeField.address], 'Rua das Flores, 120 · Centro · Rolândia/PR · CEP 86600000');
    expect(record.values[MergeField.church], 'Sede - Rolândia');
    expect(record.positions, ['Líder do ministério Louvor']);
    expect(record.createdAt, DateTime(2024, 5, 1, 10));
  });

  group('Tela', () {
    Future<(DuplicatesViewModel, List<bool>)> pumpScreen(WidgetTester tester, List<DuplicateGroup> groups) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late DuplicatesViewModel viewModel;
      await tester.runAsync(() async => viewModel = await viewModelFor(groups));
      final closed = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DuplicatesScreen(viewModel: viewModel, onClose: closed.add),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (viewModel, closed);
    }

    testWidgets('mostra os dois lado a lado; clicar no valor escolhe; juntar com confirmação', (tester) async {
      final (viewModel, closed) = await pumpScreen(tester, [cpfGroup]);
      expect(find.text('Caso 1 de 1 · mesmo CPF'), findsOneWidget);
      expect(find.text('Este fica'), findsOneWidget);
      expect(find.text('Este será desativado'), findsOneWidget);
      expect(find.text('Não são a mesma pessoa'), findsNothing, reason: 'mesmo CPF: não tem essa opção');

      await tester.tap(find.text('(43) 3256-0000'));
      await tester.pump();
      expect(viewModel.finalValue(MergeField.phone), '(43) 3256-0000');

      await tester.tap(find.text('Juntar'));
      await tester.pumpAndSettle();
      expect(find.text('Juntar os cadastros?'), findsOneWidget);
      await tester.tap(find.text('Juntar').last);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(repository.merges.single.take, contains(MergeField.phone));
      expect(find.text('Nenhum cadastro duplicado.'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar para a lista'));
      expect(closed, [true], reason: 'juntou: a lista recarrega');
    });

    testWidgets('sem duplicados: aviso', (tester) async {
      await pumpScreen(tester, const []);
      expect(find.text('Nenhum cadastro duplicado.'), findsOneWidget);
      expect(find.text('Juntar'), findsNothing);
    });
  });
}

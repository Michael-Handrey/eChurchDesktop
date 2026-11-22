import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/ui/main/widgets/member_quick_search.dart';
import 'package:echurch_desktop/ui/members/member_quick_search_viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/user_admin_fakes.dart';

class _FakeMemberRepository implements MemberRepository {
  final searches = <({int? churchId, String? text, int size})>[];

  static const _all = [
    MemberRow(id: 1, name: 'Ana Souza', status: MemberStatus.active, churchName: 'Sede - Rolândia', phone: '(43) 9882-09471'),
    MemberRow(id: 2, name: 'Ana Lima', status: MemberStatus.inactive, churchName: 'Filial - Londrina', deactivationReason: DeactivationReason.movedAway),
  ];

  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) async {
    searches.add((churchId: churchId, text: text, size: size));
    final items = [
      for (final item in _all)
        if (item.name.toLowerCase().contains((text ?? '').toLowerCase()) || (item.phone ?? '').replaceAll(RegExp(r'\D'), '').contains(text ?? '-')) item,
    ];
    return Result.ok(MemberPage(items: items, total: items.length == 2 ? 15 : items.length, page: 0, size: size));
  }

  @override
  Future<Result<List<EcclesiasticalRoleOption>>> roles() async => const Result.ok([]);

  @override
  Future<Result<MemberDetails>> details(int id) async => Result.ok(MemberDetails(id: id, name: _all.firstWhere((item) => item.id == id).name, status: MemberStatus.active, ministryNames: const ['Louvor']));

  @override
  Future<Result<MemberDetails>> deactivate(int id, {required DeactivationReason reason, required String description}) => throw UnimplementedError();

  @override
  Future<Result<MemberDetails>> reactivate(int id) => throw UnimplementedError();

  @override
  Future<Result<MemberFormOptions>> formOptions() => throw UnimplementedError();

  @override
  Future<Result<MemberDraft>> loadForEdit(int id) => throw UnimplementedError();

  @override
  Future<Result<int>> save(MemberDraft draft) => throw UnimplementedError();

  @override
  Future<Result<List<DuplicateGroup>>> duplicates() => throw UnimplementedError();

  @override
  Future<Result<void>> mergeDuplicates({required int keepId, required int removeId, required Set<MergeField> takeFromRemoved}) => throw UnimplementedError();

  @override
  Future<Result<void>> dismissDuplicate(int personId, int otherPersonId) => throw UnimplementedError();

  @override
  Future<Result<SpouseReview>> spouseReview() => throw UnimplementedError();

  @override
  Future<Result<void>> linkSpouses(List<SpouseLink> links) => throw UnimplementedError();

  @override
  Future<Result<void>> dismissSpouse(int personId, {int? candidateId}) => throw UnimplementedError();
}

const _consulta = AuthSessionUser(login: 'joao', name: 'João', firstAccess: false, churchId: 1, roles: ['ROLE_USER']);
const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);

void main() {
  late _FakeMemberRepository repository;

  MemberQuickSearchViewModel viewModelFor(AuthSessionUser user) {
    repository = _FakeMemberRepository();
    return MemberQuickSearchViewModel(repository: repository, session: sessionSignedInAs(user));
  }

  Future<MemberQuickSearchViewModel> pumpField(WidgetTester tester, AuthSessionUser user) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = viewModelFor(user);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(height: 64, child: MemberQuickSearchWidget()),
                Expanded(child: Text('conteúdo')),
              ],
            ),
          ),
        ),
      ),
    );
    return viewModel;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('busca-rapida')), text);
    await tester.pump(const Duration(milliseconds: 350)); // espera a digitação parar
    await tester.pumpAndSettle();
  }

  group('ViewModel', () {
    test('só busca com 2 letras ou mais, em todas as igrejas do alcance, até 8 resultados', () async {
      final viewModel = viewModelFor(_secretaria);
      viewModel.setQuery('a');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(repository.searches, isEmpty);
      expect(viewModel.isActive, isFalse);

      viewModel.setQuery(' an ');
      expect(viewModel.loading, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(repository.searches.single, (churchId: null, text: 'an', size: MemberQuickSearchViewModel.maxResults));
      expect(viewModel.results, hasLength(2));
      expect(viewModel.total, 15);
      expect(viewModel.loading, isFalse);
    });

    test('digitação rápida faz uma busca só (a última)', () async {
      final viewModel = viewModelFor(_secretaria);
      viewModel
        ..setQuery('an')
        ..setQuery('ana')
        ..setQuery('ana s');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(repository.searches.map((search) => search.text), ['ana s']);
      expect(viewModel.results.single.name, 'Ana Souza');
    });

    test('CPF no texto de ajuda só para quem gerencia', () {
      expect(viewModelFor(_secretaria).hint, contains('CPF'));
      expect(viewModelFor(_consulta).hint, isNot(contains('CPF')));
    });
  });

  group('Campo', () {
    testWidgets('resultados aparecem abaixo do campo; clicar abre a ficha e limpa a busca', (tester) async {
      await pumpField(tester, _secretaria);
      await type(tester, 'ana');

      expect(find.text('MEMBROS'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Sede - Rolândia  ·  (43) 9882-09471'), findsOneWidget);
      expect(find.text('Inativo'), findsOneWidget);
      expect(find.text('Mostrando 2 de 15. Digite mais para refinar.'), findsOneWidget);
      expect(tester.getTopLeft(find.text('MEMBROS')).dy, greaterThan(tester.getBottomLeft(find.byKey(const ValueKey('busca-rapida'))).dy));

      await tester.tap(find.text('Ana Lima'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Louvor'), findsOneWidget);
      expect(find.text('MEMBROS'), findsNothing, reason: 'a lista fechou');
      expect(tester.widget<TextField>(find.byKey(const ValueKey('busca-rapida'))).controller!.text, isEmpty);
    });

    testWidgets('busca por telefone; nada encontrado mostra aviso', (tester) async {
      await pumpField(tester, _secretaria);
      await type(tester, '988209');
      expect(find.text('Ana Souza'), findsOneWidget);

      await type(tester, 'zzz');
      expect(find.text('Nenhum membro encontrado.'), findsOneWidget);
    });

    testWidgets('Enter abre o primeiro; Esc fecha a lista; Ctrl+K volta para o campo', (tester) async {
      await pumpField(tester, _secretaria);
      await type(tester, 'ana');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('MEMBROS'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('MEMBROS'), findsOneWidget, reason: 'voltou o foco, a lista reaparece com a busca anterior');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Louvor'), findsOneWidget, reason: 'abriu a ficha da primeira (Ana Souza)');
      expect(find.text('Ana Souza'), findsOneWidget);
    });
  });
}

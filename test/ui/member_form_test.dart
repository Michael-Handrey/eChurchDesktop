import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/lookup_repository.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/services/api/mappers/member_form_api_model_mapper.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/ui/members/form/member_form_screen.dart';
import 'package:echurch_desktop/ui/members/form/member_form_viewmodel.dart';
import 'package:echurch_desktop/ui/members/form/widgets/form_fields.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/user_admin_fakes.dart';

const _rolandia = CityOption(id: 7, name: 'Rolândia', state: 'PR');

/// Membro para editar: casada, com Instagram (o formulário não mostra, mas não pode apagar).
final _carla = MemberDraft(
  id: 10,
  name: 'Carla Andressa Souza Leite',
  birthDate: DateTime(1991, 10, 13),
  gender: Gender.female,
  birthCity: _rolandia,
  cpf: '52998224725',
  rg: '107605428',
  maritalStatus: MaritalStatus.married,
  spouseName: 'Michael Handrey dos Santos Augusto',
  addressId: 3,
  postalCode: '86602602',
  streetType: StreetType.street,
  streetName: 'Antônio Olinto Miranda',
  streetNumber: '90',
  city: _rolandia,
  district: const NamedOption(id: 5, name: 'Jardim Paraná'),
  contactId: 4,
  phone: '(43) 9880-83844',
  instagram: '@carla',
  churchId: 1,
  ecclesiasticalRoleId: 2,
  ministryIds: const {1},
);

class _FakeMemberRepository implements MemberRepository {
  final saved = <MemberDraft>[];
  AppException? saveError;

  @override
  Future<Result<MemberFormOptions>> formOptions() async => const Result.ok(
    MemberFormOptions(
      roles: [NamedOption(id: 2, name: 'Diaconisa')],
      ministries: [
        NamedOption(id: 1, name: 'Louvor'),
        NamedOption(id: 3, name: 'Soldadinhos de Cristo'),
      ],
      nationalities: [
        NationalityOption.brazilian,
        NationalityOption(value: 'PORTUGUESE', label: 'Português'),
      ],
    ),
  );

  @override
  Future<Result<MemberDraft>> loadForEdit(int id) async => Result.ok(_carla);

  @override
  Future<Result<int>> save(MemberDraft draft) async {
    if (saveError case final error?) return Result.error(error);
    saved.add(draft);
    return Result.ok(draft.id ?? 99);
  }

  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) async {
    const all = [
      MemberRow(id: 10, name: 'Carla Andressa Souza Leite', status: MemberStatus.active, churchName: 'Sede - Rolândia'),
      MemberRow(id: 30, name: 'Michael Handrey dos Santos Augusto', status: MemberStatus.active, churchName: 'Sede - Rolândia'),
    ];
    final items = [
      for (final member in all)
        if (member.name.toLowerCase().contains((text ?? '').toLowerCase())) member,
    ];
    return Result.ok(MemberPage(items: items, total: items.length, page: 0, size: size));
  }

  @override
  Future<Result<List<EcclesiasticalRoleOption>>> roles() => throw UnimplementedError();

  @override
  Future<Result<MemberDetails>> details(int id) => throw UnimplementedError();

  @override
  Future<Result<MemberDetails>> deactivate(int id, {required DeactivationReason reason, required String description}) => throw UnimplementedError();

  @override
  Future<Result<MemberDetails>> reactivate(int id) => throw UnimplementedError();

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

class _FakeLookupRepository implements LookupRepository {
  final createdDistricts = <String>[];
  CepAddress? cepResult = const CepAddress(postalCode: '86600000', streetType: StreetType.avenue, street: 'Presidente Vargas', district: 'Centro', city: 'Rolândia', state: 'PR', cityId: 7);

  @override
  Future<Result<List<CityOption>>> cities(String text) async => Result.ok([if ('rolândia'.contains(text.toLowerCase())) _rolandia]);

  @override
  Future<Result<List<NamedOption>>> districts(int cityId) async => const Result.ok([NamedOption(id: 5, name: 'Jardim Paraná')]);

  @override
  Future<Result<NamedOption>> createDistrict(int cityId, String name) async {
    createdDistricts.add(name);
    return Result.ok(NamedOption(id: 50, name: name));
  }

  @override
  Future<Result<List<NamedOption>>> professions(String text) async => const Result.ok([]);

  @override
  Future<Result<NamedOption>> createProfession(String name) async => Result.ok(NamedOption(id: 60, name: name));

  @override
  Future<Result<CepAddress>> cep(String postalCode) async => cepResult == null ? Result.error(const NotFoundException()) : Result.ok(cepResult!);
}

const _secretaria = AuthSessionUser(login: 'maria', name: 'Maria', firstAccess: false, churchId: 1, roles: ['ROLE_SECRETARIA']);

void main() {
  late _FakeMemberRepository members;
  late _FakeLookupRepository lookup;

  Future<MemberFormViewModel> viewModelFor({int? memberId, WidgetTester? tester}) async {
    members = _FakeMemberRepository();
    lookup = _FakeLookupRepository();
    final session = sessionSignedInAs(_secretaria);
    final churchContext = ChurchContextNotifier(churchRepository: FakeChurchRepository(), sessionNotifier: session);
    final viewModel = MemberFormViewModel(members: members, lookup: lookup, churchContext: churchContext, memberId: memberId);
    Future<void> settle() async {
      await pumpEventQueue();
      viewModel.init();
      await pumpEventQueue();
    }

    tester == null ? await settle() : await tester.runAsync(settle);
    return viewModel;
  }

  group('ViewModel', () {
    test('novo: começa na igreja em uso; salvar vazio mostra os obrigatórios sem chamar a API', () async {
      final viewModel = await viewModelFor();
      expect(viewModel.isNew, isTrue);
      expect(viewModel.draft.churchId, 1);
      expect(viewModel.statusOf(MemberFormSection.personal), SectionStatus.pending);
      expect(viewModel.statusOf(MemberFormSection.notes), SectionStatus.complete);

      await viewModel.save.execute();
      expect(members.saved, isEmpty);
      expect(viewModel.errorOf('name'), 'Obrigatório');
      expect(viewModel.errorOf('cpf'), 'Obrigatório');
      expect(viewModel.errorOf('address.postalCode'), 'Obrigatório');
      expect(viewModel.statusOf(MemberFormSection.documents), SectionStatus.error);
      expect(viewModel.firstSectionWithError, MemberFormSection.personal);

      viewModel.update((d) => d.copyWith(name: 'Ana'), field: 'name');
      expect(viewModel.errorOf('name'), isNull, reason: 'o erro some ao preencher');
    });

    test('CPF com dígitos errados, e-mail e datas inválidas', () async {
      expect(MemberFormViewModel.isValidCpf('52998224725'), isTrue);
      expect(MemberFormViewModel.isValidCpf('12345678900'), isFalse);
      expect(MemberFormViewModel.isValidCpf('11111111111'), isFalse);

      final viewModel = await viewModelFor(memberId: 10);
      viewModel.update((d) => d.copyWith(cpf: '123.456.789-00', email: 'carla@', baptismDate: DateTime(1980)));
      await viewModel.save.execute();
      expect(viewModel.errorOf('cpf'), 'CPF inválido');
      expect(viewModel.errorOf('contact.email'), 'E-mail inválido');
      expect(viewModel.errorOf('baptismDate'), 'Antes do nascimento');
      expect(members.saved, isEmpty);
    });

    test('menor de 18 anos: nome da mãe obrigatório; casado: cônjuge obrigatório', () async {
      final viewModel = await viewModelFor(memberId: 10);
      viewModel.update(
        (d) => d.copyWith(
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
          spouseName: '',
        ),
      );
      expect(viewModel.isMinor, isTrue);
      await viewModel.save.execute();
      expect(viewModel.errorOf('motherName'), 'Obrigatório');
      expect(viewModel.errorOf('spouseName'), 'Obrigatório');
    });

    test('edição: carrega o membro, guarda o que o formulário não mostra e salva', () async {
      final viewModel = await viewModelFor(memberId: 10);
      expect(viewModel.draft, _carla);
      expect(viewModel.hasChanges, isFalse);
      expect(viewModel.districts.single.name, 'Jardim Paraná');
      expect(viewModel.textRevision, greaterThan(0));

      viewModel.update((d) => d.copyWith(phone: '(43) 99999-0000'));
      expect(viewModel.hasChanges, isTrue);
      await viewModel.save.execute();
      expect(viewModel.save.result, isA<Ok<int>>());
      expect(members.saved.single.phone, '(43) 99999-0000');
      expect(members.saved.single.instagram, '@carla');
      expect(viewModel.hasChanges, isFalse);
    });

    test('erros por campo da API aparecem no campo', () async {
      final viewModel = await viewModelFor(memberId: 10);
      members.saveError = const ValidationException('Revise os campos destacados.', fields: {'cpf': 'Já existe um cadastro com este CPF.'});
      await viewModel.save.execute();
      expect(viewModel.errorOf('cpf'), 'Já existe um cadastro com este CPF.');
      expect(viewModel.statusOf(MemberFormSection.documents), SectionStatus.error);
    });

    test('CEP preenche o endereço; bairro que não existe pode ser cadastrado', () async {
      final viewModel = await viewModelFor();
      viewModel.update((d) => d.copyWith(postalCode: '86600-000', streetNumber: '120'));
      final revision = viewModel.textRevision;
      await viewModel.lookupCep.execute();
      await pumpEventQueue();

      expect(viewModel.draft.streetType, StreetType.avenue);
      expect(viewModel.draft.streetName, 'Presidente Vargas');
      expect(viewModel.draft.streetNumber, '120', reason: 'o número não é apagado');
      expect(viewModel.draft.city, _rolandia);
      expect(viewModel.draft.district, isNull);
      expect(viewModel.suggestedDistrict, 'Centro');
      expect(viewModel.textRevision, revision + 1, reason: 'a tela copia os textos novos');

      await viewModel.createDistrict.execute('Centro');
      expect(lookup.createdDistricts, ['Centro']);
      expect(viewModel.draft.district, const NamedOption(id: 50, name: 'Centro'));
      expect(viewModel.suggestedDistrict, isNull);
    });

    test('CEP não encontrado avisa e não mexe no endereço', () async {
      final viewModel = await viewModelFor();
      lookup.cepResult = null;
      viewModel.update((d) => d.copyWith(postalCode: '00000000'));
      await viewModel.lookupCep.execute();
      expect(viewModel.cepMessage, contains('CEP não encontrado'));
      expect(viewModel.draft.streetName, isEmpty);
    });
  });

  group('Pedido para a API', () {
    test('CPF e CEP só com números, datas aaaa-mm-dd, cônjuge só para casados', () {
      final input = _carla.copyWith(cpf: '529.982.247-25', postalCode: '86602-602').toInput();
      expect(input.cpf, '52998224725');
      expect(input.address?.postalCode, '86602602');
      expect(input.birthDate, '1991-10-13');
      expect(input.spouseName, 'Michael Handrey dos Santos Augusto');
      expect(input.contact?.instagram, '@carla');
      expect(input.address?.district, 5);

      final single = MemberDraft(maritalStatus: MaritalStatus.single, spouseName: 'Sobrou do cadastro antigo', name: ' Ana ').toInput();
      expect(single.spouseName, isNull);
      expect(single.name, 'Ana');
    });

    test('cônjuge: vínculo (com id) só para casados ou viúvos; sem vínculo vai só o nome', () {
      final linked = _carla.copyWith(spouseId: 30).toInput();
      expect(linked.spouseId, 30);
      expect(linked.spouseName, 'Michael Handrey dos Santos Augusto');

      final widowed = MemberDraft(maritalStatus: MaritalStatus.widowed, spouseId: 30, spouseName: 'Michael').toInput();
      expect(widowed.spouseId, 30, reason: 'viúvo mantém o vínculo');

      final divorced = MemberDraft(maritalStatus: MaritalStatus.divorced, spouseId: 30, spouseName: 'Michael').toInput();
      expect(divorced.spouseId, isNull);
      expect(divorced.spouseName, isNull);
    });

    test('StreetType separa o tipo do nome que vem do CEP', () {
      expect(StreetType.split('Rua das Flores'), (StreetType.street, 'das Flores'));
      expect(StreetType.split('Av. Brasil'), (StreetType.avenue, 'Brasil'));
      expect(StreetType.split('Praça da Sé'), (null, 'Praça da Sé'));
    });
  });

  group('Tela', () {
    Future<(MemberFormViewModel, List<int?>)> pumpForm(WidgetTester tester, {int? memberId}) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final viewModel = await viewModelFor(memberId: memberId, tester: tester);
      final closed = <int?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberFormScreen(viewModel: viewModel, onClose: closed.add),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (viewModel, closed);
    }

    testWidgets('edição: campos preenchidos (CPF com máscara); salvar devolve o id', (tester) async {
      final (viewModel, closed) = await pumpForm(tester, memberId: 10);
      expect(find.text('Editar membro'), findsOneWidget);
      expect(find.text('529.982.247-25'), findsOneWidget);
      expect(find.text('Rolândia/PR'), findsNWidgets(2), reason: 'nascimento e endereço');
      expect(find.text('Jardim Paraná'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('member-form-contact.phone')), '43999990000');
      expect(viewModel.draft.phone, '(43) 99999-0000', reason: 'máscara de telefone');

      await tester.tap(find.text('Salvar'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(closed, [10]);
    });

    testWidgets('novo: salvar vazio marca as seções com erro no índice', (tester) async {
      await pumpForm(tester);
      expect(find.text('Novo membro'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);

      await tester.tap(find.text('Cadastrar'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsNWidgets(4), reason: 'pessoais, documentos, família e endereço (a igreja já vem preenchida)');
      expect(find.text('Revise os campos destacados.'), findsOneWidget);
    });

    testWidgets('cônjuge: busca os membros (sem o próprio) e permite usar só o nome', (tester) async {
      final (viewModel, _) = await pumpForm(tester, memberId: 10);
      expect(viewModel.draft.spouse, const SpouseOption(name: 'Michael Handrey dos Santos Augusto'), reason: 'cadastro antigo: só o nome');
      expect(find.text('Só o nome (não está vinculado a um cadastro).'), findsOneWidget);

      final field = find.descendant(of: find.byType(LookupField<SpouseOption>), matching: find.byType(TextField));
      await tester.enterText(field, 'a');
      await tester.enterText(field, 'aug');
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(ListTile), matching: find.text('Sede - Rolândia')),
        findsOneWidget,
        reason: 'a igreja aparece na opção',
      );
      expect(
        find.descendant(of: find.byType(ListTile), matching: find.text('Carla Andressa Souza Leite')),
        findsNothing,
        reason: 'o próprio membro não aparece na lista',
      );
      expect(find.text('Usar só o nome “aug”'), findsOneWidget);

      await tester.tap(find.text('Michael Handrey dos Santos Augusto').last);
      await tester.pumpAndSettle();
      expect(viewModel.draft.spouseId, 30);
      expect(find.textContaining('Vinculado ao cadastro de Michael'), findsOneWidget);

      await tester.tap(find.text('Desvincular'));
      await tester.pumpAndSettle();
      expect(viewModel.draft.spouseId, isNull);
      expect(viewModel.draft.spouseName, 'Michael Handrey dos Santos Augusto', reason: 'o nome fica');
    });

    testWidgets('cancelar com alterações pede confirmação', (tester) async {
      final (viewModel, closed) = await pumpForm(tester, memberId: 10);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(closed, [null], reason: 'sem alterações, fecha direto');

      viewModel.update((d) => d.copyWith(notes: 'Nova observação'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Descartar as alterações?'), findsOneWidget);
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(closed, [null, null]);
    });
  });
}

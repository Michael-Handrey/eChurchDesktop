import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/services/api/child_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/child/child_api_model.dart';
import 'package:echurch_desktop/domain/models/child/child.dart';

/// Crianças e Adolescentes. Erros de regra da API (sem responsável, ministério fora da faixa...) chegam como
/// `ValidationException` com a mensagem dela.
abstract interface class ChildRepository {
  /// [churchId] nulo = todas do alcance; [ministryId] 0 = sem ministério.
  Future<Result<ChildPage>> search({int? churchId, int? ministryId, String text = '', ChildTab tab = ChildTab.active, int page = 0, int size = 20});

  Future<Result<ChildDetails>> find(int id);

  /// Cadastra ([ChildDraft.id] nulo) ou altera.
  Future<Result<ChildDetails>> save(ChildDraft draft);

  Future<Result<ChildDetails>> setActive(int id, bool active);

  /// Membros ativos para responsável (com o cônjuge vinculado).
  Future<Result<List<GuardianOption>>> guardianOptions(String text);
}

class ChildRepositoryRemote({required final ChildApi _api}) implements ChildRepository {
  @override
  Future<Result<ChildPage>> search({int? churchId, int? ministryId, String text = '', ChildTab tab = ChildTab.active, int page = 0, int size = 20}) => _guard(() async {
    final data = await _api.search(churchId: churchId, ministryId: ministryId, text: text.trim(), status: tab.apiValue, page: page, size: size);
    return ChildPage(
      items: [
        for (final item in data.items)
          ChildRow(
            id: item.id,
            name: (item.name ?? '').trim(),
            birthDate: _date(item.birthDate),
            age: item.age ?? 0,
            churchName: item.churchName,
            ministryId: item.ministryId,
            ministryName: item.ministryName,
            guardians: item.guardians ?? '',
            active: item.active ?? true,
          ),
      ],
      total: data.total,
      page: data.page,
      size: data.size,
    );
  });

  @override
  Future<Result<ChildDetails>> find(int id) => _guard(() async => _details(await _api.find(id)));

  @override
  Future<Result<ChildDetails>> save(ChildDraft draft) => _guard(() async {
    final input = ChildInput(
      name: draft.name.trim(),
      birthDate: _iso(draft.birthDate),
      churchId: draft.churchId,
      ministryId: draft.ministryId,
      notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
      guardians: [for (final guardian in draft.guardians) GuardianInput(personId: guardian.personId, kinship: guardian.kinship.apiValue)],
    );
    return _details(draft.id == null ? await _api.create(input) : await _api.update(draft.id!, input));
  });

  @override
  Future<Result<ChildDetails>> setActive(int id, bool active) => _guard(() async => _details(await _api.setActive(id, ChildActiveInput(active: active))));

  @override
  Future<Result<List<GuardianOption>>> guardianOptions(String text) => _guard(
    () async => [
      for (final item in await _api.guardianOptions(text.trim()))
        GuardianOption(
          id: item.id,
          name: (item.name ?? '').trim(),
          churchName: item.churchName,
          gender: item.gender,
          spouseId: item.spouseId,
          spouseName: item.spouseName?.trim(),
          spouseGender: item.spouseGender,
        ),
    ],
  );

  static ChildDetails _details(ChildApiModel model) => ChildDetails(
    id: model.id,
    name: (model.name ?? '').trim(),
    birthDate: _date(model.birthDate),
    age: model.age ?? 0,
    churchId: model.churchId,
    churchName: model.churchName,
    ministryId: model.ministryId,
    ministryName: model.ministryName,
    notes: model.notes,
    active: model.active ?? true,
    guardians: [
      for (final guardian in model.guardians) ChildGuardian(personId: guardian.personId, name: (guardian.name ?? '').trim(), kinship: Kinship.fromApi(guardian.kinship), phone: guardian.phone, churchName: guardian.churchName),
    ],
  );

  static DateTime _date(String? value) => DateTime.tryParse(value ?? '') ?? DateTime(1900);

  static String _iso(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/member/lookup_repository.dart';
import 'package:echurch_desktop/data/services/api/lookup_api.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:echurch_desktop/data/services/api/mappers/member_form_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_form_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';

class LookupRepositoryRemote({required final LookupApi _api}) implements LookupRepository {
  @override
  Future<Result<List<CityOption>>> cities(String text) => _guard(() async {
    final term = text.trim();
    if (term.length < 2) return const <CityOption>[];
    return [
      for (final city in await _api.cities(term))
        if ((city.name ?? '').trim().isNotEmpty) CityOption(id: city.id, name: city.name!.trim(), state: city.stateName),
    ];
  });

  @override
  Future<Result<List<NamedOption>>> districts(int cityId) => _guard(() async => _named(await _api.districts(cityId)));

  @override
  Future<Result<NamedOption>> createDistrict(int cityId, String name) => _guard(() async {
    final text = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return NamedOption(id: (await _api.createDistrict(cityId, text)).id, name: text);
  });

  @override
  Future<Result<List<NamedOption>>> professions(String text) => _guard(() async {
    final term = text.trim();
    if (term.length < 2) return const <NamedOption>[];
    return _named(await _api.professions(term));
  });

  @override
  Future<Result<NamedOption>> createProfession(String name) => _guard(() async {
    final text = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return NamedOption(id: (await _api.createProfession(text)).id, name: text);
  });

  @override
  Future<Result<CepAddress>> cep(String postalCode) => _guard(() async {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    return (await _api.cep(digits)).toDomain(digits);
  });

  static List<NamedOption> _named(List<NamedApiModel> items) => [
    for (final item in items)
      if ((item.name ?? '').trim().isNotEmpty) NamedOption(id: item.id, name: item.name!.trim()),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on DioException catch (e, st) {
      return Result.error(e.toAppException(st));
    }
  }
}

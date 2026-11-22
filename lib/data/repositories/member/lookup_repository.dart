import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';

/// Buscas do formulário de pessoas: cidades, bairros, profissões e CEP.
abstract interface class LookupRepository {
  /// Cidades cujo nome contém [text] (a partir de 2 letras).
  Future<Result<List<CityOption>>> cities(String text);

  /// Bairros da cidade, em ordem de nome.
  Future<Result<List<NamedOption>>> districts(int cityId);

  /// Cria o bairro (se já existir com o mesmo nome, devolve o existente).
  Future<Result<NamedOption>> createDistrict(int cityId, String name);

  /// Profissões cujo nome contém [text].
  Future<Result<List<NamedOption>>> professions(String text);

  /// Cria a profissão (se já existir com o mesmo nome, devolve a existente).
  Future<Result<NamedOption>> createProfession(String name);

  /// Endereço do CEP (8 dígitos). CEP que não existe: `NotFoundException`.
  Future<Result<CepAddress>> cep(String postalCode);
}

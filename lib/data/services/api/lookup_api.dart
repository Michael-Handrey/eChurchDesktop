import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_form_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'lookup_api.g.dart';

/// Buscas do formulário de pessoas (`UtilResource` e `CepResource`): cidades, bairros, profissões e CEP.
/// Criar bairro ou profissão: só Secretaria/Administrador (se já existir com o mesmo nome, a API devolve o existente).
@RestApi()
abstract class LookupApi {
  factory LookupApi(Dio dio) = _LookupApi;

  @GET('/v1/utils/city/autocomplete/{name}')
  Future<List<CityApiModel>> cities(@Path('name') String name);

  @GET('/v1/utils/district/autocomplete/{cityId}')
  Future<List<NamedApiModel>> districts(@Path('cityId') int cityId);

  @PUT('/v1/utils/district/new/{cityId}/{name}')
  Future<CreatedIdApiModel> createDistrict(@Path('cityId') int cityId, @Path('name') String name);

  @GET('/v1/utils/profession/autocomplete/{name}')
  Future<List<NamedApiModel>> professions(@Path('name') String name);

  @PUT('/v1/utils/profession/new/{name}')
  Future<CreatedIdApiModel> createProfession(@Path('name') String name);

  /// 404: CEP não existe; 503: consulta indisponível (o endereço é preenchido à mão).
  @GET('/v1/addresses/get-endereco-pelo-cep/{cep}')
  Future<CepApiModel> cep(@Path('cep') String cep);
}

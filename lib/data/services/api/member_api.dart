import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:retrofit/retrofit.dart';

part 'member_api.g.dart';

/// Membros (`NaturalPersonResource`), no Dio principal. A lista é igual para todos os perfis;
/// o detalhe vem completo ou reduzido conforme o perfil.
@RestApi()
abstract class MemberApi {
  factory MemberApi(Dio dio) = _MemberApi;

  @GET('/v1/people')
  Future<MemberPageApiModel> search({
    @Query('churchId') int? churchId,
    @Query('status') String? status,
    @Query('text') String? text,
    @Query('ecclesiasticalRoleId') int? ecclesiasticalRoleId,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/v1/people/options')
  Future<MemberOptionsApiModel> options();

  @GET('/v1/people/{id}')
  Future<MemberDetailsApiModel> findById(@Path('id') int id);

  @PUT('/v1/people/{id}/deactivate')
  Future<MemberDetailsApiModel> deactivate(@Path('id') int id, @Body() MemberDeactivationInput request);

  @PUT('/v1/people/{id}/reactivate')
  Future<MemberDetailsApiModel> reactivate(@Path('id') int id);
}

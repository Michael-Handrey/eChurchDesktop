import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_form_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/member/spouse_review_api_model.dart';
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

  /// O mesmo detalhe, com os ids e valores crus para preencher o formulário (Secretaria/Administrador).
  @GET('/v1/people/{id}')
  Future<MemberEditApiModel> findForEdit(@Path('id') int id);

  /// Sem `id` cadastra; com `id` altera. Erros por campo: 400 `{"fields": {...}}`.
  @POST('/v1/people')
  Future<MemberEditApiModel> save(@Body() MemberInput request);

  /// Cadastros duplicados (Secretaria/Administrador): grupos com a mesma pessoa.
  @GET('/v1/people/duplicates')
  Future<List<DuplicateGroupApiModel>> duplicates();

  /// Junta dois cadastros: um fica, o outro é desativado como "Cadastro duplicado".
  @POST('/v1/people/duplicates/merge')
  Future<MemberEditApiModel> mergeDuplicates(@Body() DuplicateMergeInput request);

  /// "Não são a mesma pessoa" (sugestões por nome e nascimento).
  @POST('/v1/people/duplicates/dismiss')
  Future<void> dismissDuplicate(@Body() DuplicateDismissInput request);

  /// Revisão de cônjuges (Secretaria/Administrador): sugestões de casais e quem não tem sugestão.
  @GET('/v1/people/spouse-review')
  Future<SpouseReviewApiModel> spouseReview();

  /// Liga casais (um ou vários), nos dois lados.
  @POST('/v1/people/spouse-review/link')
  Future<void> linkSpouses(@Body() SpouseLinkBatchInput request);

  /// "Não é este" / "não é membro".
  @POST('/v1/people/spouse-review/dismiss')
  Future<void> dismissSpouse(@Body() SpouseDismissInput request);

  @PUT('/v1/people/{id}/deactivate')
  Future<MemberDetailsApiModel> deactivate(@Path('id') int id, @Body() MemberDeactivationInput request);

  @PUT('/v1/people/{id}/reactivate')
  Future<MemberDetailsApiModel> reactivate(@Path('id') int id);
}

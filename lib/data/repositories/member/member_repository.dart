import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';

/// Membros da igreja. Erros de regra da API (motivo ou descrição em branco, membro já inativo...)
/// chegam como `ValidationException` com a mensagem dela.
abstract interface class MemberRepository {
  /// [churchId] nulo = todas as igrejas que o usuário alcança; [status] nulo = todas as situações;
  /// [text] busca no nome. Ordem de nome.
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20});

  /// Cargos eclesiásticos, em ordem de nome.
  Future<Result<List<EcclesiasticalRoleOption>>> roles();

  Future<Result<MemberDetails>> details(int id);

  /// Membros não são excluídos: desativar exige motivo e descrição.
  Future<Result<MemberDetails>> deactivate(int id, {required DeactivationReason reason, required String description});

  Future<Result<MemberDetails>> reactivate(int id);

  /// Listas do formulário: cargos, ministérios e nacionalidades.
  Future<Result<MemberFormOptions>> formOptions();

  /// Membro completo para editar (Secretaria/Administrador).
  Future<Result<MemberDraft>> loadForEdit(int id);

  /// Cadastra ([MemberDraft.id] nulo) ou altera; devolve o id. Erros por campo vêm em
  /// `ValidationException.fields`, pelo nome do campo no pedido (`cpf`, `address.streetName`...).
  Future<Result<int>> save(MemberDraft draft);

  /// Cadastros duplicados no alcance de quem pede (Secretaria/Administrador).
  Future<Result<List<DuplicateGroup>>> duplicates();

  /// Junta: [keepId] fica (com os campos de [takeFromRemoved] vindos do outro); [removeId] é desativado.
  Future<Result<void>> mergeDuplicates({required int keepId, required int removeId, required Set<MergeField> takeFromRemoved});

  /// Revisão de cônjuges: sugestões de casais e quem tem cônjuge escrito sem sugestão.
  Future<Result<SpouseReview>> spouseReview();

  /// Liga os casais (nos dois lados); devolve quantos.
  Future<Result<void>> linkSpouses(List<SpouseLink> links);

  /// "Não é este" ([candidateId]) ou "não é membro" ([candidateId] nulo): a sugestão não volta.
  Future<Result<void>> dismissSpouse(int personId, {int? candidateId});

  /// "Não são a mesma pessoa" (sugestão por nome e nascimento): não volta mais.
  Future<Result<void>> dismissDuplicate(int personId, int otherPersonId);
}

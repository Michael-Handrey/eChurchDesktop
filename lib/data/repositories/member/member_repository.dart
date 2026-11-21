import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';

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
}

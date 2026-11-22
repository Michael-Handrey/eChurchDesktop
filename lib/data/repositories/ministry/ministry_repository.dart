import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/ministry/ministry.dart';

/// Ministérios. Erros de regra da API (sem nome, líder igual ao vice, tirar o líder...) chegam como
/// `ValidationException` com a mensagem dela.
abstract interface class MinistryRepository {
  /// [churchId] nulo = todas as igrejas do alcance; [includeInactive] traz os desativados (no fim).
  Future<Result<List<Ministry>>> list({int? churchId, bool includeInactive = false});

  /// Cadastra ([id] nulo) ou altera. O líder e o vice entram como membros.
  Future<Result<Ministry>> save(int? id, MinistryDraft draft);

  Future<Result<Ministry>> setActive(int id, bool active);

  /// Membros do ministério, em ordem de nome.
  Future<Result<List<MemberRow>>> members(int id);

  Future<Result<List<MemberRow>>> addMembers(int id, List<int> personIds);

  /// O líder e o vice-líder não saem (troque antes).
  Future<Result<List<MemberRow>>> removeMembers(int id, List<int> personIds);
}

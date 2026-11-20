import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';

/// Grupos de acesso e catálogo de permissões (só administrador).
abstract interface class GroupAdminRepository {
  Future<Result<List<SecurityGroup>>> list();

  /// Catálogo fixo do backend: as permissões só têm efeito quando o código as confere.
  Future<Result<List<String>>> permissions();

  /// [id] nulo cria; com valor, altera nome e permissões do grupo.
  Future<Result<SecurityGroup>> save({int? id, required String name, required Set<String> permissions});

  /// Só exclui grupo sem usuários (o backend recusa com a mensagem).
  Future<Result<void>> delete(int id);
}

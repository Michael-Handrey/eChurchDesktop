import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';

abstract interface class UserAdminRepository {
  Future<Result<List<ManagedUser>>> list();

  /// Define uma senha provisória e obriga a troca no próximo acesso.
  /// [temporaryPassword] nulo: o backend gera uma senha forte.
  Future<Result<PasswordReset>> resetPassword({required int userId, String? temporaryPassword});

  /// Ativa ou desativa o usuário (desativar encerra as sessões dele). Devolve o usuário atualizado.
  Future<Result<ManagedUser>> setActive({required int userId, required bool active});

  /// Troca a igreja (sede ou filial) do usuário. Devolve o usuário atualizado.
  Future<Result<ManagedUser>> setChurch({required int userId, required int churchId});

  /// Troca os grupos do usuário. Devolve o usuário atualizado.
  Future<Result<ManagedUser>> updateGroups({required int userId, required Set<int> groupIds});
}

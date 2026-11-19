import 'package:echurch_desktop/core/result.dart';

abstract interface class AccountRepository {
  /// Troca a senha do usuário logado. A regra de força é validada no backend.
  Future<Result<void>> changePassword({required String currentPassword, required String newPassword});
}

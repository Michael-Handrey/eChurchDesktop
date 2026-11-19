import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

/// Sessão atual + se o usuário pediu "Lembrar-me".
typedef StoredAuthSession = ({AuthSession session, bool remember});

/// Sessão do usuário. Fica sempre em memória; vai para o disco (storage seguro)
/// **somente** com "Lembrar-me". Sem ele, nada é gravado e a sessão some ao fechar o app.
abstract interface class AuthSessionRepository {
  /// Define a sessão atual (login).
  Future<Result<void>> save(AuthSession session, {required bool remember});

  /// Troca [current] por [next] (renovação), mantendo o "Lembrar-me".
  /// `Ok(false)` se a sessão atual não é mais [current] (logout ou novo login no meio do caminho):
  /// nesse caso nada é alterado.
  Future<Result<bool>> replace({required AuthSession current, required AuthSession next});

  Future<Result<void>> delete();

  Future<Result<StoredAuthSession?>> fetch();
}

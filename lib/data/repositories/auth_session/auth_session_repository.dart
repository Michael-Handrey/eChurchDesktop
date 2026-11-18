import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

/// Sessão guardada + se o usuário pediu "Lembrar-me".
typedef StoredAuthSession = ({AuthSession session, bool remember});

abstract interface class AuthSessionRepository {
  Future<Result<void>> save(AuthSession session, {required bool remember});
  Future<Result<void>> delete();
  Future<Result<StoredAuthSession?>> fetch();
}

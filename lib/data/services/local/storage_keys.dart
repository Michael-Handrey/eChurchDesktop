final class StorageKeys._() {
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';

  /// JSON de [AuthSessionLocalModel] (expirações + usuário).
  static const authSession = 'auth_session';

  static const all = [accessToken, refreshToken, authSession];
}

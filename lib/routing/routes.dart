final class Routes._() {
  static const login = '/login';
  static const dashboard = '/dashboard';

  /// Troca obrigatória da senha provisória. Não é pública: exige sessão.
  static const firstAccess = '/first-access';

  static const public = {login};
}

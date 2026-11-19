final class Routes._() {
  /// Abertura do app e transição após login/troca de senha.
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';

  /// Troca obrigatória da senha provisória. Não é pública: exige sessão.
  static const firstAccess = '/first-access';

  static const public = {login};

  /// Telas em janela centralizada no tamanho do login; as demais abrem maximizadas.
  static const compactWindow = {splash, login, firstAccess};
}

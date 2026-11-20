/// Nomes amigáveis dos grupos e permissões do backend. Grupo ou permissão sem tradução
/// (ex.: grupo criado pela tela) aparece com o próprio nome.
final class AccessLabels._() {
  static String group(String name) => switch (name) {
    'ADMIN' => 'Administrador',
    'SECRETARIA' => 'Secretaria',
    'USUARIO' => 'Usuário',
    _ => name,
  };

  static String permission(String name) => switch (name) {
    'ROLE_ADMIN' => 'Administração',
    'ROLE_SECRETARIA' => 'Secretaria',
    'ROLE_USER' => 'Usuário',
    _ => name,
  };

  static String permissionDescription(String name) => switch (name) {
    'ROLE_ADMIN' => 'Gerencia usuários, grupos, permissões e senhas.',
    'ROLE_SECRETARIA' => 'Funções da secretaria (membros, cadastros e documentos).',
    'ROLE_USER' => 'Acesso básico ao sistema.',
    _ => name,
  };
}

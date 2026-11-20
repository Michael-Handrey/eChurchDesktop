import 'package:equatable/equatable.dart';

/// Grupo de acesso: junta permissões e é dado aos usuários.
class const SecurityGroup({
  required final int id,
  required final String name,

  /// Nomes do catálogo do backend (`ROLE_ADMIN`, `ROLE_SECRETARIA`...), em ordem alfabética.
  final List<String> permissions = const [],
  final int userCount = 0,
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, permissions, userCount];
}

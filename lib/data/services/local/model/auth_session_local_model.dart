import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_session_local_model.g.dart';

/// Metadados da sessão salvos no storage. Os tokens ficam em chaves próprias
/// ([StorageKeys.accessToken] / [StorageKeys.refreshToken]) para o interceptor ler direto.
/// `checked: true`: JSON inválido vira [CheckedFromJsonException] (tratável) em vez de `TypeError`.
@JsonSerializable(checked: true)
class const AuthSessionLocalModel({
  required final int accessTokenExpiresAt,
  required final int refreshTokenExpiresAt,
  required final bool remember,
  required final String login,
  required final String name,
  required final bool firstAccess,
  final int? churchId,
}) extends Equatable {
  factory AuthSessionLocalModel.fromJson(Map<String, dynamic> json) => _$AuthSessionLocalModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSessionLocalModelToJson(this);

  @override
  List<Object?> get props => [accessTokenExpiresAt, refreshTokenExpiresAt, remember, login, name, firstAccess, churchId];
}

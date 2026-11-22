sealed class const AppException({
  final Object? cause,
  final StackTrace? stackTrace,
}) implements Exception {
  @override
  String toString() => cause == null ? '$runtimeType' : '$runtimeType(cause: $cause)';
}

final class const InvalidCredentialsException({super.cause, super.stackTrace}) extends AppException;

final class const NetworkException({super.cause, super.stackTrace}) extends AppException;

final class const UnknownException({super.cause, super.stackTrace}) extends AppException;

final class const UnauthorizedException({super.cause, super.stackTrace}) extends AppException;

final class const ForbiddenException({super.cause, super.stackTrace}) extends AppException;

/// Backend exige a troca da senha provisória antes de liberar a rota (403 `FIRST_ACCESS_REQUIRED`).
final class const FirstAccessRequiredException({super.cause, super.stackTrace}) extends AppException;

final class const NotFoundException({super.cause, super.stackTrace}) extends AppException;

final class const ServerException({super.cause, super.stackTrace}) extends AppException;

final class const StorageException({super.cause, super.stackTrace}) extends AppException;

/// Backend bloqueou temporariamente por excesso de senhas incorretas (HTTP 429).
final class const TooManyAttemptsException(
  final String message, {
  super.cause,
  super.stackTrace,
}) extends AppException;

/// Dados recusados pela API (400/422). [fields]: erro de cada campo do formulário, quando a API
/// manda (`{"fields": {"cpf": "CPF Inválido"}}`), pelo nome do campo no pedido.
final class const ValidationException(
  final String message, {
  final Map<String, String> fields = const {},
  super.cause,
  super.stackTrace,
}) extends AppException;

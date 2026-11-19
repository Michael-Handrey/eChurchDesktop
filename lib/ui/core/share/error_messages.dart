import 'package:echurch_desktop/core/exceptions/app_exception.dart';

final class ErrorMessages._() {
  static String of(AppException error) => switch (error) {
    NetworkException() => 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
    ValidationException(:final message) => message,
    TooManyAttemptsException(:final message) => message,
    UnauthorizedException() => 'Sua sessão expirou. Entre novamente.',
    InvalidCredentialsException() => 'Usuário e/ou senha inválidos.',
    ForbiddenException() => 'Você não tem permissão para isso.',
    FirstAccessRequiredException() => 'Sua senha foi redefinida. Saia e entre novamente para cadastrar uma nova senha.',
    NotFoundException() => 'Não encontramos o que você procurou.',
    ServerException() => 'Estamos com um problema no servidor. Tente mais tarde.',
    StorageException() || UnknownException() => 'Algo deu errado. Tente novamente.',
  };
}

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';

extension DioExceptionMapper on DioException {
  AppException toAppException(StackTrace st) {
    return switch (type) {
      DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout || DioExceptionType.connectionError => NetworkException(cause: this, stackTrace: st),
      DioExceptionType.badResponse => _fromStatus(response?.statusCode, st),
      _ => UnknownException(cause: this, stackTrace: st),
    };
  }

  AppException _fromStatus(int? status, StackTrace st) => switch (status) {
    400 || 422 => ValidationException(serverMessage ?? 'Dados inválidos. Revise e tente novamente.', cause: this, stackTrace: st),
    401 => UnauthorizedException(cause: this, stackTrace: st),
    403 when _errorCode == _firstAccessRequired => FirstAccessRequiredException(cause: this, stackTrace: st),
    403 => ForbiddenException(cause: this, stackTrace: st),
    404 => NotFoundException(cause: this, stackTrace: st),
    429 => TooManyAttemptsException(serverMessage ?? 'Muitas tentativas. Aguarde alguns minutos e tente novamente.', cause: this, stackTrace: st),
    final code? when code >= 500 => ServerException(cause: this, stackTrace: st),
    _ => UnknownException(cause: this, stackTrace: st),
  };

  static const _firstAccessRequired = 'FIRST_ACCESS_REQUIRED';

  /// Código de erro dos filtros de segurança (`ApiErrorResponse.error`).
  String? get _errorCode => switch (response?.data) {
    {'error': final String code} => code,
    _ => null,
  };

  /// Mensagem enviada pela API Spring: `{"erro": "..."}` / `{"mensagem": "..."}` (AuthResource)
  /// ou `{"message": "..."}` (GlobalExceptionHandler e filtros de segurança).
  String? get serverMessage => switch (response?.data) {
    {'erro': final String message} => message,
    {'mensagem': final String message} => message,
    {'message': final String message} => message,
    _ => null,
  };
}

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
    403 => ForbiddenException(cause: this, stackTrace: st),
    404 => NotFoundException(cause: this, stackTrace: st),
    429 => TooManyAttemptsException(serverMessage ?? 'Muitas tentativas. Aguarde alguns minutos e tente novamente.', cause: this, stackTrace: st),
    final code? when code >= 500 => ServerException(cause: this, stackTrace: st),
    _ => UnknownException(cause: this, stackTrace: st),
  };

  /// Mensagem enviada pela API Spring: `{"erro": "..."}` ou `{"mensagem": "..."}`.
  String? get serverMessage => switch (response?.data) {
    {'erro': final String message} => message,
    {'mensagem': final String message} => message,
    _ => null,
  };
}

import 'package:dio/dio.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/data/services/api/mappers/dio_exception_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppException map(int status, Object? body) {
    final options = RequestOptions(path: '/v1/x');
    return DioException.badResponse(
      statusCode: status,
      requestOptions: options,
      response: Response<Object?>(requestOptions: options, statusCode: status, data: body),
    ).toAppException(StackTrace.empty);
  }

  test('403 de primeiro acesso vira FirstAccessRequiredException', () {
    expect(map(403, {'status': 403, 'error': 'FIRST_ACCESS_REQUIRED', 'message': 'Troque a senha'}), isA<FirstAccessRequiredException>());
  });

  test('outros 403 continuam como falta de permissão', () {
    expect(map(403, {'status': 403, 'error': 'FORBIDDEN'}), isA<ForbiddenException>());
    expect(map(403, null), isA<ForbiddenException>());
  });

  test('429 traz a mensagem do backend', () {
    final error = map(429, {'erro': 'Muitas tentativas incorretas. Tente novamente em 15 minuto(s).'});

    expect(error, isA<TooManyAttemptsException>());
    expect((error as TooManyAttemptsException).message, contains('15 minuto'));
  });

  test('400 da troca de senha traz a regra que faltou', () {
    final error = map(400, {'erro': 'A nova senha precisa ter um número.'});

    expect((error as ValidationException).message, 'A nova senha precisa ter um número.');
  });
}

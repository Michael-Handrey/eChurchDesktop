final class Environment._() {
  /// Raiz da API do e-Church (Spring Boot). Os paths das `*Api` começam em `/v1/...`.
  /// Outra máquina/porta: `flutter run --dart-define=BASE_URL=http://host:porta/api`.
  static const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8070/api');

  static String url(String path) => '$baseUrl$path';
}

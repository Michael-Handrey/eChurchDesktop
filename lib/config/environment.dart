import 'package:flutter/foundation.dart';

final class Environment._() {
  /// Raiz da API do e-Church (Spring Boot). Os paths das `*Api` começam em `/v1/...`.
  /// Outra máquina/porta: `flutter run --dart-define=BASE_URL=http://host:porta/api`.
  /// Release: precisa ser `https://` (ver [ensureSecureTransport]).
  static const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8070/api');

  static const _loopbackHosts = {'localhost', '127.0.0.1', '::1'};

  static String url(String path) => '$baseUrl$path';

  /// Em release, recusa iniciar com a API em HTTP: senha e tokens trafegariam em texto aberto.
  /// HTTP só é aceito para loopback, onde o tráfego não sai da máquina.
  /// Em debug/profile não bloqueia (ex.: API numa máquina da rede local).
  static void ensureSecureTransport() {
    if (!kReleaseMode) return;

    final uri = Uri.tryParse(baseUrl);
    final secure = uri != null && (uri.scheme == 'https' || (uri.scheme == 'http' && _loopbackHosts.contains(uri.host)));

    if (!secure) {
      throw StateError('BASE_URL precisa usar HTTPS no build de release (atual: $baseUrl).');
    }
  }
}

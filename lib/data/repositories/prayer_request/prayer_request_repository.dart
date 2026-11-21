import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';

/// Pedidos de oração. Erros de regra da API (texto vazio, pedido que não pode mais ser alterado...)
/// chegam como `ValidationException` com a mensagem dela.
abstract interface class PrayerRequestRepository {
  /// [status] nulo = todas as situações; [text] busca em nome e pedido; [excluded] = só os excluídos
  /// (administrador). [churchId] nulo = todas as igrejas que o usuário alcança. Quem alcança a Sede
  /// vê também os pedidos sem igreja.
  Future<Result<PrayerRequestPage>> search({int? churchId, PrayerRequestStatus? status, String? text, bool excluded = false, int page = 0, int size = 20});

  Future<Result<PrayerRequest>> create(PrayerRequestDraft draft);

  Future<Result<PrayerRequest>> update(int id, PrayerRequestDraft draft);

  /// Marca como "no vaso" os escolhidos (só novos).
  Future<Result<List<PrayerRequest>>> markInVase(Set<int> ids);

  /// Marca como "no vaso" todos os novos da igreja (na Sede, também os sem igreja).
  Future<Result<List<PrayerRequest>>> markAllNewInVase(int churchId);

  /// Rejeita (não condiz com a proposta), com motivo opcional.
  Future<Result<PrayerRequest>> reject(int id, {String? reason});

  /// Administrador: desfaz o "no vaso" ou a rejeição.
  Future<Result<PrayerRequest>> backToNew(int id);

  /// Tira um rejeitado da lista (fica guardado; só o administrador vê).
  Future<Result<PrayerRequest>> exclude(int id);

  /// Administrador: devolve um excluído para a lista.
  Future<Result<PrayerRequest>> restore(int id);
}

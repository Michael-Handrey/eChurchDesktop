import 'package:equatable/equatable.dart';

/// Situação do pedido: Novo → No vaso (fim do ciclo); ou Rejeitado (não condiz com a proposta).
enum PrayerRequestStatus {
  newRequest('NEW'),
  inVase('IN_VASE'),
  rejected('REJECTED');

  const PrayerRequestStatus(this.apiValue);

  /// Valor do enum na API (PrayerRequestStatus do backend).
  final String apiValue;

  static PrayerRequestStatus? fromApi(String? value) => values.where((status) => status.apiValue == value).firstOrNull;
}

/// O que quem está logado pode fazer com o pedido. Quem decide é a API (regras num lugar só);
/// o app só mostra os botões correspondentes.
enum PrayerRequestAction {
  edit('EDIT'),
  inVase('IN_VASE'),
  reject('REJECT'),
  backToNew('BACK_TO_NEW'),
  exclude('EXCLUDE'),
  restore('RESTORE');

  const PrayerRequestAction(this.apiValue);

  final String apiValue;

  static PrayerRequestAction? fromApi(String value) => values.where((action) => action.apiValue == value).firstOrNull;
}

/// Pedido de oração. Da equipe (registrado no sistema) ou da comunidade ([fromCommunity]: app
/// público, sem usuário; não pode ser editado). Sem igreja ([churchId] nulo): fica com a Sede.
class const PrayerRequest({
  required final int id,
  required final String requesterName,
  required final String description,
  required final DateTime requestDate,
  required final PrayerRequestStatus status,
  final bool fromCommunity = false,
  final int? churchId,
  final String? churchName,
  final String? createdByName,
  final DateTime? createdAt,

  /// Quando foi impresso para o vaso de oração.
  final DateTime? printedAt,
  final DateTime? rejectedAt,
  final String? rejectedByName,
  final String? rejectionReason,

  /// "Excluído": fora da lista, guardado (só o administrador vê).
  final DateTime? excludedAt,
  final String? excludedByName,
  final Set<PrayerRequestAction> actions = const {},
}) extends Equatable {
  bool get isExcluded => excludedAt != null;

  bool can(PrayerRequestAction action) => actions.contains(action);

  @override
  List<Object?> get props => [id, requesterName, description, requestDate, status, fromCommunity, churchId, churchName, createdByName, createdAt, printedAt, rejectedAt, rejectedByName, rejectionReason, excludedAt, excludedByName, actions];
}

/// Uma página da lista de pedidos.
class const PrayerRequestPage({required final List<PrayerRequest> items, required final int total, required final int page, required final int size}) extends Equatable {
  int get pageCount => size == 0 ? 0 : (total / size).ceil();

  @override
  List<Object?> get props => [items, total, page, size];
}

/// Dados para registrar ou alterar um pedido.
typedef PrayerRequestDraft = ({String requesterName, String description, DateTime requestDate, int? churchId});

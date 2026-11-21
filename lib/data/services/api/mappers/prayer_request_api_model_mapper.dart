import 'package:echurch_desktop/data/services/api/model/prayer/prayer_request_api_model.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';

extension PrayerRequestApiModelMapper on PrayerRequestApiModel {
  PrayerRequest toDomain() => PrayerRequest(
    id: id,
    requesterName: (requesterName ?? '').trim(),
    description: (description ?? '').trim(),
    requestDate: _date(requestDate) ?? DateTime.now(),
    status: PrayerRequestStatus.fromApi(status) ?? PrayerRequestStatus.newRequest,
    fromCommunity: fromCommunity ?? false,
    churchId: churchId,
    churchName: churchName,
    createdByName: createdByName,
    createdAt: _date(createdAt),
    printedAt: _date(printedAt),
    rejectedAt: _date(rejectedAt),
    rejectedByName: rejectedByName,
    rejectionReason: (rejectionReason ?? '').trim().isEmpty ? null : rejectionReason!.trim(),
    excludedAt: _date(excludedAt),
    excludedByName: excludedByName,
    // Ação desconhecida (versão nova da API) é ignorada.
    actions: {for (final action in actions ?? const <String>[]) ?PrayerRequestAction.fromApi(action)},
  );

  static DateTime? _date(String? value) => value == null ? null : DateTime.tryParse(value);
}

extension PrayerRequestPageApiModelMapper on PrayerRequestPageApiModel {
  PrayerRequestPage toDomain() => PrayerRequestPage(items: [for (final item in items) item.toDomain()], total: total, page: page, size: size);
}

extension PrayerRequestDraftMapper on PrayerRequestDraft {
  /// Data como "aaaa-mm-dd" (LocalDate da API).
  PrayerRequestInput toInput() => PrayerRequestInput(
    requesterName: requesterName.trim(),
    description: description.trim(),
    requestDate: '${requestDate.year.toString().padLeft(4, '0')}-${requestDate.month.toString().padLeft(2, '0')}-${requestDate.day.toString().padLeft(2, '0')}',
    churchId: churchId,
  );
}

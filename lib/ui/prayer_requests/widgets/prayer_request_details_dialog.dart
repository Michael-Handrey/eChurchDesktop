import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:echurch_desktop/ui/prayer_requests/widgets/prayer_request_status_chip.dart';
import 'package:material_ui/material_ui.dart';

/// Pedido completo (o texto na tabela é cortado), a origem e o histórico: registro, vaso, rejeição e exclusão.
class const PrayerRequestDetailsDialog({super.key, required final PrayerRequest request}) extends StatelessWidget {
  static Future<void> show(BuildContext context, PrayerRequest request) => showDialog<void>(
    context: context,
    builder: (_) => PrayerRequestDetailsDialog(request: request),
  );

  static String _dateTime(DateTime value) => '${PrayerRequestsViewModel.formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String _by(String? name) => name == null ? '' : ' por $name';

  @override
  Widget build(BuildContext context) {
    final history = [
      if (request.createdAt case final createdAt?) request.fromCommunity ? 'Recebido pelo app em ${_dateTime(createdAt)}' : 'Registrado em ${_dateTime(createdAt)}${_by(request.createdByName)}',
      if (request.printedAt case final printedAt?) 'Colocado no vaso em ${_dateTime(printedAt)}',
      if (request.rejectedAt case final rejectedAt?) 'Rejeitado em ${_dateTime(rejectedAt)}${_by(request.rejectedByName)}',
      if (request.excludedAt case final excludedAt?) 'Excluído da lista em ${_dateTime(excludedAt)}${_by(request.excludedByName)}',
    ];

    return AlertDialog(
      icon: const Icon(Icons.volunteer_activism_outlined, color: AppColors.prayerIcon),
      title: Text('Pedido de ${request.requesterName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 460, maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: 14,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: .center,
                children: [
                  PrayerRequestStatusChip(request: request),
                  if (request.fromCommunity) const PrayerRequestTag(label: 'Comunidade', color: AppColors.primary, background: AppColors.primarySubtle),
                  Text(PrayerRequestsViewModel.formatDate(request.requestDate), style: const TextStyle(color: AppColors.textSecondary)),
                  Text('· ${request.churchName ?? 'Sem igreja'}', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              SelectableText(request.description, style: const TextStyle(fontSize: 14.5, height: 1.45)),
              if (request.rejectionReason case final reason?)
                Container(
                  width: double.infinity,
                  padding: const .all(12),
                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('Motivo da rejeição: $reason', style: const TextStyle(color: AppColors.textPrimary)),
                ),
              if (history.isNotEmpty) ...[
                const Divider(height: 1),
                for (final line in history) Text(line, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ],
          ),
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
    );
  }
}

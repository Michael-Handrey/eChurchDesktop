import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Rejeita um pedido que não condiz com a proposta, com motivo opcional. Fecha devolvendo `true`.
class const RejectPrayerRequestDialog({super.key, required final PrayerRequestsViewModel viewModel, required final PrayerRequest request}) extends StatefulWidget {
  static const maxReason = 500;

  static Future<bool?> show(BuildContext context, {required PrayerRequestsViewModel viewModel, required PrayerRequest request}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RejectPrayerRequestDialog(viewModel: viewModel, request: request),
  );

  @override
  State<RejectPrayerRequestDialog> createState() => _RejectPrayerRequestDialogState();
}

class _RejectPrayerRequestDialogState extends State<RejectPrayerRequestDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.viewModel.reject.addListener(_onResult);
  }

  void _onResult() {
    final command = widget.viewModel.reject;
    switch (command.result) {
      case Ok<PrayerRequest>():
        command.clearResult();
        Navigator.of(context).pop(true);
      case Error<PrayerRequest>(:final error):
        command.clearResult();
        setState(() => _error = ErrorMessages.of(error));
      case null:
        setState(() {}); // running mudou
    }
  }

  @override
  void dispose() {
    widget.viewModel.reject.removeListener(_onResult);
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.reject.running;

    return AlertDialog(
      icon: const Icon(Icons.block, color: AppColors.error),
      title: const Text('Rejeitar pedido de oração'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 480),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 12,
          children: [
            Text('Pedido de ${widget.request.requesterName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Text(
              'Use quando o pedido não condiz com a proposta (ofensas, propaganda, textos sem sentido). '
              'Ele não vai para o vaso; depois, pode ser excluído da lista.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            TextField(
              controller: _reason,
              enabled: !running,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: RejectPrayerRequestDialog.maxReason,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)', alignLabelWithHint: true),
            ),
            if (_error case final message?) AppErrorBanner(message: message),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running ? null : () => widget.viewModel.reject.execute((request: widget.request, reason: _reason.text)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Rejeitar'),
        ),
      ],
    );
  }
}

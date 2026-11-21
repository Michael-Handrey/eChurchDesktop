import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/prayer/prayer_request.dart';
import 'package:echurch_desktop/ui/core/share/app_error_banner.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/prayer_requests/prayer_requests_viewmodel.dart';
import 'package:material_ui/material_ui.dart';

/// Registra ([request] nulo) ou altera um pedido. Fecha devolvendo `true` quando salvou.
class const PrayerRequestFormDialog({super.key, required final PrayerRequestsViewModel viewModel, final PrayerRequest? request}) extends StatefulWidget {
  static const maxName = 150;
  static const maxDescription = 2000;

  static Future<bool?> show(BuildContext context, {required PrayerRequestsViewModel viewModel, PrayerRequest? request}) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PrayerRequestFormDialog(viewModel: viewModel, request: request),
  );

  @override
  State<PrayerRequestFormDialog> createState() => _PrayerRequestFormDialogState();
}

class _PrayerRequestFormDialogState extends State<PrayerRequestFormDialog> {
  late final _name = TextEditingController(text: widget.request?.requesterName ?? '');
  late final _description = TextEditingController(text: widget.request?.description ?? '');
  late DateTime _date = widget.request?.requestDate ?? DateUtils.dateOnly(DateTime.now());
  String? _error;

  bool get _isNew => widget.request == null;

  @override
  void initState() {
    super.initState();
    widget.viewModel.save.addListener(_onResult);
    for (final controller in [_name, _description]) {
      controller.addListener(() => setState(() => _error = null));
    }
  }

  void _onResult() {
    final command = widget.viewModel.save;
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

  bool get _canSubmit => _name.text.trim().isNotEmpty && _description.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: today, helpText: 'Data do pedido');
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_canSubmit || widget.viewModel.save.running) return;
    widget.viewModel.save.execute((
      id: widget.request?.id,
      draft: (requesterName: _name.text, description: _description.text, requestDate: _date, churchId: widget.request?.churchId),
    ));
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_onResult);
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.viewModel.save.running;
    final churchName = widget.request?.churchName ?? widget.viewModel.churchName;

    return AlertDialog(
      icon: const Icon(Icons.volunteer_activism_outlined, color: AppColors.prayerIcon),
      title: Text(_isNew ? 'Novo pedido de oração' : 'Editar pedido de oração'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 480, maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 14,
            children: [
              if (churchName != null)
                Row(
                  spacing: 6,
                  children: [
                    const Icon(Icons.church_outlined, size: 16, color: AppColors.textSecondary),
                    Text(churchName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              TextField(
                controller: _name,
                enabled: !running,
                autofocus: _isNew,
                maxLength: PrayerRequestFormDialog.maxName,
                decoration: const InputDecoration(labelText: 'Quem pediu', hintText: 'Nome de quem fez o pedido'),
                textInputAction: .next,
              ),
              TextField(
                controller: _description,
                enabled: !running,
                minLines: 4,
                maxLines: 8,
                maxLength: PrayerRequestFormDialog.maxDescription,
                decoration: const InputDecoration(labelText: 'Pedido', hintText: 'Pelo que orar', alignLabelWithHint: true),
              ),
              InkWell(
                onTap: running ? null : _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data do pedido', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                  child: Text(PrayerRequestsViewModel.formatDate(_date)),
                ),
              ),
              if (_error case final message?) AppErrorBanner(message: message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: running || !_canSubmit ? null : _submit,
          child: running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isNew ? 'Registrar' : 'Salvar'),
        ),
      ],
    );
  }
}

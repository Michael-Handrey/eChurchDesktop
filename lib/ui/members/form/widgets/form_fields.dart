import 'dart:async';

import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Máscara simples: `#` é um número; o resto é fixo. Ex.: CPF `###.###.###-##`, CEP `#####-###`.
class MaskFormatter extends TextInputFormatter {
  MaskFormatter(this.pattern);

  /// Telefone: (43) 3256-2060 ou (43) 99882-0947, conforme a quantidade de números.
  static TextInputFormatter phone() => _PhoneFormatter();

  final String pattern;

  static String apply(String pattern, String digits) {
    final buffer = StringBuffer();
    var index = 0;
    for (final char in pattern.split('')) {
      if (index >= digits.length) break;
      if (char == '#') {
        buffer.write(digits[index++]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final max = '#'.allMatches(pattern).length;
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > max) digits = digits.substring(0, max);
    final text = apply(pattern, digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);
    final text = MaskFormatter.apply(digits.length > 10 ? '(##) #####-####' : '(##) ####-####', digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Decoração padrão dos campos do formulário: rótulo, "*" nos obrigatórios e o erro embaixo.
InputDecoration formDecoration(String label, {bool required = false, String? error, String? hint, Widget? suffix, String? helper}) => InputDecoration(
  labelText: required ? '$label *' : label,
  hintText: hint,
  helperText: helper,
  errorText: error,
  suffixIcon: suffix,
  isDense: true,
  filled: true,
  fillColor: AppColors.surface,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
);

/// Campos lado a lado, com espaço entre eles ([flex] de cada um; padrão 1).
class const FormRow({super.key, required final List<Widget> children, final List<int>? flex}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    spacing: 16,
    children: [
      for (var i = 0; i < children.length; i++) Expanded(flex: flex?[i] ?? 1, child: children[i]),
    ],
  );
}

/// Data "dd/mm/aaaa" digitada ou escolhida no calendário. [onChanged] recebe nula enquanto a data
/// não está completa e válida.
class DateFormField extends StatefulWidget {
  const DateFormField({super.key, required this.controller, required this.label, required this.onChanged, this.required = false, this.error, this.firstDate, this.lastDate});

  final TextEditingController controller;
  final String label;
  final bool required;
  final String? error;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime?> onChanged;

  static String format(DateTime? date) => date == null ? '' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}';

  /// "15/03/1980" → data; nula se incompleta ou inexistente (31/02).
  static DateTime? parse(String text) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text.trim());
    if (match == null) return null;
    final (day, month, year) = (int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    final date = DateTime(year, month, day);
    return date.day == day && date.month == month && date.year == year ? date : null;
  }

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  String? _localError;

  void _changed(String text) {
    final date = DateFormField.parse(text);
    setState(() => _localError = text.length == 10 && date == null ? 'Data inválida' : null);
    widget.onChanged(date);
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateFormField.parse(widget.controller.text) ?? now,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? now,
    );
    if (picked == null) return;
    widget.controller.text = DateFormField.format(picked);
    _changed(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    inputFormatters: [MaskFormatter('##/##/####')],
    keyboardType: TextInputType.datetime,
    onChanged: _changed,
    decoration: formDecoration(
      widget.label,
      required: widget.required,
      hint: 'dd/mm/aaaa',
      error: _localError ?? widget.error,
      suffix: IconButton(tooltip: 'Escolher no calendário', icon: const Icon(Icons.calendar_today_outlined, size: 18), onPressed: _pick),
    ),
  );
}

/// Escolha numa lista com busca (cidade, bairro, profissão). [search] devolve as opções para o
/// texto digitado; [onCreate], se informado, oferece "Cadastrar “texto”" quando não há igual.
/// Sair do campo sem escolher volta o texto para o que está escolhido.
class LookupField<T extends Object> extends StatefulWidget {
  const LookupField({
    super.key,
    required this.label,
    required this.selected,
    required this.labelOf,
    required this.search,
    required this.onSelected,
    this.required = false,
    this.error,
    this.helper,
    this.onCreate,
    this.createLabel = 'Cadastrar',
    this.enabled = true,
  });

  final String label;
  final T? selected;
  final String Function(T item) labelOf;
  final FutureOr<List<T>> Function(String text) search;
  final ValueChanged<T> onSelected;
  final bool required;
  final String? error;
  final String? helper;
  final Future<void> Function(String text)? onCreate;
  final String createLabel;
  final bool enabled;

  @override
  State<LookupField<T>> createState() => _LookupFieldState<T>();
}

/// Opção da lista: um item existente ou "cadastrar este texto".
typedef _Choice<T> = ({T? item, String? create});

class _LookupFieldState<T extends Object> extends State<LookupField<T>> {
  late final _controller = TextEditingController(text: _selectedLabel);
  final _focus = FocusNode();

  String get _selectedLabel => widget.selected == null ? '' : widget.labelOf(widget.selected as T);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _controller.text != _selectedLabel) _controller.text = _selectedLabel;
    });
  }

  @override
  void didUpdateWidget(LookupField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && !_focus.hasFocus) _controller.text = _selectedLabel;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<Iterable<_Choice<T>>> _options(TextEditingValue value) async {
    final text = value.text.trim();
    if (text.isEmpty || text == _selectedLabel) return const [];
    final items = await widget.search(text);
    final exact = items.any((item) => widget.labelOf(item).toLowerCase() == text.toLowerCase());
    return [
      for (final item in items.take(30)) (item: item, create: null),
      if (widget.onCreate != null && !exact && text.length >= 2) (item: null, create: text),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<_Choice<T>>(
      textEditingController: _controller,
      focusNode: _focus,
      optionsBuilder: _options,
      displayStringForOption: (choice) => choice.item == null ? choice.create! : widget.labelOf(choice.item as T),
      onSelected: (choice) async {
        if (choice.item case final item?) {
          widget.onSelected(item);
        } else if (choice.create case final text?) {
          await widget.onCreate?.call(text);
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: widget.enabled,
        onSubmitted: (_) => onSubmitted(),
        decoration: formDecoration(widget.label, required: widget.required, error: widget.error, helper: widget.helper, hint: 'Digite para buscar', suffix: const Icon(Icons.search, size: 18)),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
            child: ListView(
              padding: const .symmetric(vertical: 4),
              shrinkWrap: true,
              children: [
                for (final choice in options)
                  ListTile(
                    dense: true,
                    leading: choice.item == null ? const Icon(Icons.add, size: 18, color: AppColors.primary) : null,
                    title: Text(
                      choice.item == null ? '${widget.createLabel} “${choice.create}”' : widget.labelOf(choice.item as T),
                      style: choice.item == null ? const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600) : null,
                    ),
                    onTap: () => onSelected(choice),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

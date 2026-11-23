import 'package:equatable/equatable.dart';

/// Aniversariante (membro ou criança) para o painel inicial.
class const Birthday({
  required final String name,
  required final DateTime date,

  /// Idade que completa nesse aniversário (nula para quem só consulta: do nascimento, só dia e mês).
  final int? age,
  final bool isChild = false,
}) extends Equatable {
  @override
  List<Object?> get props => [name, date, age, isChild];
}

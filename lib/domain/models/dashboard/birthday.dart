import 'package:equatable/equatable.dart';

/// Aniversariante (membro ou criança) para o painel inicial.
class const Birthday({
  required final String name,
  required final DateTime date,

  /// Idade que completa nesse aniversário.
  required final int age,
  final bool isChild = false,
}) extends Equatable {
  @override
  List<Object?> get props => [name, date, age, isChild];
}

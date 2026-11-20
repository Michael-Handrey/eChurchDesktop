import 'package:equatable/equatable.dart';

/// Igreja (sede ou filial) para escolha em tela. [name] já vem pronto: "Sede - Rolândia", "Filial - Londrina".
class const ChurchSummary({required final int id, required final String name, final bool headquarters = false}) extends Equatable {
  @override
  List<Object?> get props => [id, name, headquarters];
}

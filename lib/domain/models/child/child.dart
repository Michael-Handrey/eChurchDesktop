import 'package:equatable/equatable.dart';

/// Grau de parentesco do responsável (enum Kinship da API).
enum Kinship {
  mother('MOTHER', 'Mãe'),
  father('FATHER', 'Pai'),
  grandmother('GRANDMOTHER', 'Avó'),
  grandfather('GRANDFATHER', 'Avô'),
  aunt('AUNT', 'Tia'),
  uncle('UNCLE', 'Tio'),
  stepmother('STEPMOTHER', 'Madrasta'),
  stepfather('STEPFATHER', 'Padrasto'),
  sibling('SIBLING', 'Irmão(ã)'),
  other('OTHER', 'Outro');

  const Kinship(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Kinship fromApi(String? value) => values.firstWhere((kinship) => kinship.apiValue == value, orElse: () => other);

  /// Sugestão ao escolher um responsável: mãe ou pai, pelo sexo do cadastro ("F"/"M").
  static Kinship parentFor(String? gender) => gender == 'F' ? mother : father;
}

/// Aba da lista (mesmo padrão de Membros).
enum ChildTab {
  active('ACTIVE', 'Ativas'),
  inactive('INACTIVE', 'Inativas'),
  all('ALL', 'Todas');

  const ChildTab(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Linha da lista: [guardians] já vem pronto ("Maria Souza (Mãe), João Souza (Pai)").
class const ChildRow({
  required final int id,
  required final String name,
  required final DateTime birthDate,
  required final int age,
  final String? churchName,
  final int? ministryId,
  final String? ministryName,
  final String guardians = '',
  final bool active = true,
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, birthDate, age, churchName, ministryId, ministryName, guardians, active];
}

class const ChildPage({required final List<ChildRow> items, required final int total, required final int page, required final int size}) extends Equatable {
  int get pageCount => size == 0 ? 0 : (total / size).ceil();

  @override
  List<Object?> get props => [items, total, page, size];
}

/// Responsável (membro) da criança.
class const ChildGuardian({required final int personId, required final String name, required final Kinship kinship, final String? phone, final String? churchName}) extends Equatable {
  ChildGuardian withKinship(Kinship value) => ChildGuardian(personId: personId, name: name, kinship: value, phone: phone, churchName: churchName);

  @override
  List<Object?> get props => [personId, name, kinship, phone, churchName];
}

/// A criança completa (ver e editar).
class const ChildDetails({
  required final int id,
  required final String name,
  required final DateTime birthDate,
  required final int age,
  final int? churchId,
  final String? churchName,
  final int? ministryId,
  final String? ministryName,
  final String? notes,
  final bool active = true,
  final List<ChildGuardian> guardians = const [],
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, birthDate, age, churchId, churchName, ministryId, ministryName, notes, active, guardians];
}

/// Membro que pode ser responsável, com o cônjuge vinculado (o formulário sugere incluir).
class const GuardianOption({
  required final int id,
  required final String name,
  final String? churchName,
  final String? gender,
  final int? spouseId,
  final String? spouseName,
  final String? spouseGender,
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, churchName, gender, spouseId, spouseName, spouseGender];
}

/// Para salvar: [id] nulo cadastra.
typedef ChildDraft = ({int? id, String name, DateTime birthDate, int churchId, int? ministryId, String notes, List<ChildGuardian> guardians});

/// Idade completa na data.
int ageAt(DateTime birthDate, DateTime date) {
  var age = date.year - birthDate.year;
  if (date.month < birthDate.month || (date.month == birthDate.month && date.day < birthDate.day)) age--;
  return age;
}

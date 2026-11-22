import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:equatable/equatable.dart';

/// Como o grupo foi achado: mesmo CPF (certeza) ou mesmo nome e nascimento com CPF diferente (sugestão).
enum DuplicateKind {
  cpf('CPF'),
  nameBirth('NAME_BIRTH');

  const DuplicateKind(this.apiValue);

  final String apiValue;

  static DuplicateKind fromApi(String? value) => value == nameBirth.apiValue ? nameBirth : cpf;
}

/// Campos que a secretaria escolhe, ao juntar, de qual cadastro vem o valor (na ordem da tela).
enum MergeField {
  name('name', 'Nome'),
  cpf('cpf', 'CPF'),
  rg('rg', 'RG'),
  birthDate('birthDate', 'Nascimento'),
  gender('gender', 'Sexo'),
  maritalStatus('maritalStatus', 'Estado civil'),
  spouseName('spouseName', 'Cônjuge'),
  fatherName('fatherName', 'Pai'),
  motherName('motherName', 'Mãe'),
  birthCity('birthCity', 'Cidade de nascimento'),
  nationality('nationality', 'Nacionalidade'),
  profession('profession', 'Profissão'),
  address('address', 'Endereço'),
  phone('phone', 'Telefone'),
  secondaryPhone('secondaryPhone', 'Outro telefone'),
  email('email', 'E-mail'),
  church('church', 'Igreja'),
  ecclesiasticalRole('ecclesiasticalRole', 'Cargo'),
  baptismDate('baptismDate', 'Batismo'),
  acceptedJesusDate('acceptedJesusDate', 'Aceitou Jesus'),
  notes('notes', 'Observações');

  const MergeField(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Um cadastro do grupo, com os valores já prontos para comparar lado a lado.
class const DuplicateRecord({
  required final int id,
  required final String name,
  required final MemberStatus status,
  required final Map<MergeField, String?> values,
  final DateTime? createdAt,
  final List<String> ministryNames = const [],
  final List<String> positions = const [],
  final bool credentialPrinted = false,
}) extends Equatable {
  /// Quantos campos preenchidos (para sugerir qual cadastro fica).
  int get filled => values.values.where((value) => value != null && value.trim().isNotEmpty).length;

  @override
  List<Object?> get props => [id, name, status, values, createdAt, ministryNames, positions, credentialPrinted];
}

/// Cadastros da mesma pessoa.
class const DuplicateGroup({required final DuplicateKind kind, required final List<DuplicateRecord> records}) extends Equatable {
  @override
  List<Object?> get props => [kind, records];
}

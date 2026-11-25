import 'package:equatable/equatable.dart';

/// Sexo (Gender do backend).
enum Gender {
  male('M', 'Masculino'),
  female('F', 'Feminino');

  const Gender(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Gender? fromApi(String? value) => values.where((item) => item.apiValue == value).firstOrNull;
}

/// Estado civil (MaritalStatus do backend).
enum MaritalStatus {
  single('SINGLE', 'Solteiro(a)'),
  married('MARRIED', 'Casado(a)'),
  divorced('DIVORCED', 'Divorciado(a)'),
  widowed('WIDOWED', 'Viúvo(a)'),
  separated('SEPARATED', 'Separado(a)');

  const MaritalStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MaritalStatus? fromApi(String? value) => values.where((item) => item.apiValue == value).firstOrNull;
}

/// Tipo de logradouro (StreetType do backend).
enum StreetType {
  street('STREET', 'Rua'),
  avenue('AVENUE', 'Avenida'),
  road('ROAD', 'Estrada'),
  highway('HIGHWAY', 'Rodovia'),
  lane('LANE', 'Travessa'),
  marginal('MARGINAL', 'Marginal');

  const StreetType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static StreetType? fromApi(String? value) => values.where((item) => item.apiValue == value).firstOrNull;

  /// "Rua", "R.", "Avenida", "Av."... do CEP (ViaCEP manda o tipo junto do nome: "Rua das Flores").
  static (StreetType?, String) split(String street) {
    final text = street.trim();
    final lower = text.toLowerCase();
    const prefixes = {
      'rua ': StreetType.street,
      'r. ': StreetType.street,
      'avenida ': StreetType.avenue,
      'av. ': StreetType.avenue,
      'av ': StreetType.avenue,
      'estrada ': StreetType.road,
      'rodovia ': StreetType.highway,
      'travessa ': StreetType.lane,
      'marginal ': StreetType.marginal,
    };
    for (final MapEntry(key: prefix, value: type) in prefixes.entries) {
      if (lower.startsWith(prefix)) return (type, text.substring(prefix.length).trim());
    }
    return (null, text);
  }
}

/// Cônjuge no formulário: cadastrado ([id], vínculo nos dois lados) ou só o nome escrito ([id] nulo:
/// cônjuge que não está cadastrado). [church]: só para mostrar na lista de busca.
class const SpouseOption({final int? id, required final String name, final String? church}) extends Equatable {
  bool get isLinked => id != null;

  @override
  List<Object?> get props => [id, name, church];
}

/// Opção id + nome (cargo, ministério, bairro, profissão).
class const NamedOption({required final int id, required final String name}) extends Equatable {
  @override
  List<Object?> get props => [id, name];
}

/// Nacionalidade: valor da API ("BRAZILIAN") e nome ("Brasileiro").
class const NationalityOption({required final String value, required final String label}) extends Equatable {
  static const brazilian = NationalityOption(value: 'BRAZILIAN', label: 'Brasileiro');

  @override
  List<Object?> get props => [value, label];
}

/// Cidade: "Rolândia/PR".
class const CityOption({required final int id, required final String name, final String? state}) extends Equatable {
  String get label => state == null || state!.isEmpty ? name : '$name/$state';

  @override
  List<Object?> get props => [id, name, state];
}

/// Listas do formulário (`GET /people/options`).
class const MemberFormOptions({
  final List<NamedOption> roles = const [],
  final List<NamedOption> ministries = const [],

  /// Funções ministeriais (conselho, tesouraria, secretaria), na ordem do cadastro. Sem as de
  /// Líder/Vice-líder: a liderança vem do cadastro de Ministérios.
  final List<NamedOption> ministerialRoles = const [],
  final List<NationalityOption> nationalities = const [NationalityOption.brazilian],
}) extends Equatable {
  @override
  List<Object?> get props => [roles, ministries, ministerialRoles, nationalities];
}

/// Endereço achado pelo CEP. [cityId]/[districtId]: os do cadastro, quando existem.
class const CepAddress({
  required final String postalCode,
  final StreetType? streetType,
  final String street = '',
  final String complement = '',
  final String district = '',
  final String city = '',
  final String state = '',
  final int? cityId,
  final int? districtId,
}) extends Equatable {
  @override
  List<Object?> get props => [postalCode, streetType, street, complement, district, city, state, cityId, districtId];
}

/// Membro para o formulário (cadastro: [id] nulo; edição: o que veio da API).
///
/// Leva também o que o formulário não mostra (ids do endereço e do contato, redes sociais,
/// situação, tipo, data de falecimento), para a edição não apagar esses dados.
class const MemberDraft({
  final int? id,
  final String name = '',
  final DateTime? birthDate,
  final Gender? gender,
  final String nationality = 'BRAZILIAN',
  final CityOption? birthCity,
  final NamedOption? profession,
  final String cpf = '',
  final String rg = '',
  final MaritalStatus? maritalStatus,
  final String spouseName = '',

  /// Cônjuge cadastrado (vínculo); nulo = sem vínculo ([spouseName] é o nome escrito).
  final int? spouseId,
  final String fatherName = '',
  final String motherName = '',
  final int? addressId,
  final String postalCode = '',
  final StreetType? streetType,
  final String streetName = '',
  final String streetNumber = '',
  final String complement = '',
  final CityOption? city,
  final NamedOption? district,
  final int? contactId,
  final String phone = '',
  final String secondaryPhone = '',
  final String email = '',
  final String? facebook,
  final String? twitter,
  final String? instagram,
  final int? churchId,
  final int? ecclesiasticalRoleId,
  final Set<int> ministryIds = const {},
  final Set<int> ministerialRoleIds = const {},

  /// Só leitura (do cadastro de Ministérios): "Líder de Varões de Guerra".
  final List<String> leaderships = const [],
  final DateTime? baptismDate,
  final DateTime? acceptedJesusDate,
  final String notes = '',
  final String status = 'ACTIVE',
  final String individualType = 'MEMBER',
  final DateTime? deathDate,
}) extends Equatable {
  bool get isNew => id == null;

  /// Casado ou viúvo: pode ter cônjuge (vínculo ou nome).
  bool get canHaveSpouse => maritalStatus == MaritalStatus.married || maritalStatus == MaritalStatus.widowed;

  /// O cônjuge como aparece no campo: cadastrado, só o nome, ou nenhum.
  SpouseOption? get spouse => spouseId != null
      ? SpouseOption(id: spouseId, name: spouseName)
      : spouseName.trim().isEmpty
      ? null
      : SpouseOption(name: spouseName.trim());

  MemberDraft copyWith({
    String? name,
    DateTime? birthDate,
    bool clearBirthDate = false,
    Gender? gender,
    String? nationality,
    CityOption? birthCity,
    NamedOption? profession,
    bool clearProfession = false,
    String? cpf,
    String? rg,
    MaritalStatus? maritalStatus,
    String? spouseName,
    int? spouseId,
    bool clearSpouseId = false,
    String? fatherName,
    String? motherName,
    String? postalCode,
    StreetType? streetType,
    String? streetName,
    String? streetNumber,
    String? complement,
    CityOption? city,
    NamedOption? district,
    bool clearDistrict = false,
    String? phone,
    String? secondaryPhone,
    String? email,
    int? churchId,
    int? ecclesiasticalRoleId,
    bool clearRole = false,
    Set<int>? ministryIds,
    Set<int>? ministerialRoleIds,
    DateTime? baptismDate,
    bool clearBaptismDate = false,
    DateTime? acceptedJesusDate,
    bool clearAcceptedJesusDate = false,
    String? notes,
  }) => MemberDraft(
    id: id,
    name: name ?? this.name,
    birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    nationality: nationality ?? this.nationality,
    birthCity: birthCity ?? this.birthCity,
    profession: clearProfession ? null : profession ?? this.profession,
    cpf: cpf ?? this.cpf,
    rg: rg ?? this.rg,
    maritalStatus: maritalStatus ?? this.maritalStatus,
    spouseName: spouseName ?? this.spouseName,
    spouseId: clearSpouseId ? null : spouseId ?? this.spouseId,
    fatherName: fatherName ?? this.fatherName,
    motherName: motherName ?? this.motherName,
    addressId: addressId,
    postalCode: postalCode ?? this.postalCode,
    streetType: streetType ?? this.streetType,
    streetName: streetName ?? this.streetName,
    streetNumber: streetNumber ?? this.streetNumber,
    complement: complement ?? this.complement,
    city: city ?? this.city,
    district: clearDistrict ? null : district ?? this.district,
    contactId: contactId,
    phone: phone ?? this.phone,
    secondaryPhone: secondaryPhone ?? this.secondaryPhone,
    email: email ?? this.email,
    facebook: facebook,
    twitter: twitter,
    instagram: instagram,
    churchId: churchId ?? this.churchId,
    ecclesiasticalRoleId: clearRole ? null : ecclesiasticalRoleId ?? this.ecclesiasticalRoleId,
    ministryIds: ministryIds ?? this.ministryIds,
    ministerialRoleIds: ministerialRoleIds ?? this.ministerialRoleIds,
    leaderships: leaderships,
    baptismDate: clearBaptismDate ? null : baptismDate ?? this.baptismDate,
    acceptedJesusDate: clearAcceptedJesusDate ? null : acceptedJesusDate ?? this.acceptedJesusDate,
    notes: notes ?? this.notes,
    status: status,
    individualType: individualType,
    deathDate: deathDate,
  );

  /// Idade completa hoje (nula sem nascimento).
  int? ageAt(DateTime today) {
    final birth = birthDate;
    if (birth == null) return null;
    var age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) age--;
    return age;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    birthDate,
    gender,
    nationality,
    birthCity,
    profession,
    cpf,
    rg,
    maritalStatus,
    spouseName,
    spouseId,
    fatherName,
    motherName,
    addressId,
    postalCode,
    streetType,
    streetName,
    streetNumber,
    complement,
    city,
    district,
    contactId,
    phone,
    secondaryPhone,
    email,
    facebook,
    twitter,
    instagram,
    churchId,
    ecclesiasticalRoleId,
    ministryIds,
    ministerialRoleIds,
    leaderships,
    baptismDate,
    acceptedJesusDate,
    notes,
    status,
    individualType,
    deathDate,
  ];
}

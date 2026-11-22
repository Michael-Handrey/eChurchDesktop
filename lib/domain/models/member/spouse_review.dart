import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:equatable/equatable.dart';

/// Confiança da sugestão de casal.
enum SpouseConfidence {
  high('HIGH', 'Alta'),
  medium('MEDIUM', 'Média'),
  low('LOW', 'Baixa');

  const SpouseConfidence(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SpouseConfidence fromApi(String? value) => values.where((item) => item.apiValue == value).firstOrNull ?? low;
}

/// Como o par foi achado pelo nome.
enum SpouseMatchKind {
  mutual('MUTUAL', 'Cada um tem o nome do outro'),
  oneSide('ONE_SIDE', 'Só um lado tem o nome do outro'),
  similar('SIMILAR', 'Nome parecido');

  const SpouseMatchKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SpouseMatchKind fromApi(String? value) => values.where((item) => item.apiValue == value).firstOrNull ?? similar;
}

/// Um lado do par.
class const SpousePerson({
  required final int id,
  required final String name,
  final String? writtenSpouse,
  final MaritalStatus? maritalStatus,
  final MemberStatus status = MemberStatus.active,
  final String? churchName,
  final String? address,
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, writtenSpouse, maritalStatus, status, churchName, address];
}

/// Sugestão de casal: [person] tem o cônjuge escrito; [candidate] é o cadastro sugerido.
class const SpouseSuggestion({
  required final SpouseConfidence confidence,
  required final SpouseMatchKind kind,
  required final SpousePerson person,
  required final SpousePerson candidate,
  final bool sameAddress = false,
  final List<String> notes = const [],
}) extends Equatable {
  @override
  List<Object?> get props => [confidence, kind, person, candidate, sameAddress, notes];
}

/// O que falta revisar.
class const SpouseReview({final List<SpouseSuggestion> suggestions = const [], final List<SpousePerson> withoutSuggestion = const []}) extends Equatable {
  /// Total de pendências (para o botão "Revisar cônjuges (N)").
  int get pending => suggestions.length + withoutSuggestion.length;

  @override
  List<Object?> get props => [suggestions, withoutSuggestion];
}

/// Ligar [personId] a [spouseId]; [addressFrom]: de quem é o endereço que fica para os dois (nulo = não mexe).
typedef SpouseLink = ({int personId, int spouseId, int? addressFrom});

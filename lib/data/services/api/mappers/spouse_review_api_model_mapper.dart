import 'package:echurch_desktop/data/services/api/model/member/spouse_review_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';
import 'package:echurch_desktop/domain/models/member/spouse_review.dart';

extension SpouseReviewApiModelMapper on SpouseReviewApiModel {
  SpouseReview toDomain() => SpouseReview(
    suggestions: [for (final suggestion in suggestions ?? const <SpouseSuggestionApiModel>[]) suggestion.toDomain()],
    withoutSuggestion: [for (final person in withoutSuggestion ?? const <SpousePersonApiModel>[]) person.toDomain()],
  );
}

extension SpouseSuggestionApiModelMapper on SpouseSuggestionApiModel {
  SpouseSuggestion toDomain() => SpouseSuggestion(
    confidence: SpouseConfidence.fromApi(confidence),
    kind: SpouseMatchKind.fromApi(kind),
    person: person.toDomain(),
    candidate: candidate.toDomain(),
    sameAddress: sameAddress ?? false,
    notes: notes ?? const [],
  );
}

extension SpousePersonApiModelMapper on SpousePersonApiModel {
  SpousePerson toDomain() => SpousePerson(
    id: id,
    name: (name ?? '').trim(),
    writtenSpouse: _text(writtenSpouse),
    maritalStatus: MaritalStatus.fromApi(maritalStatus),
    status: MemberStatus.fromApi(status),
    churchName: _text(churchName),
    address: _text(address),
  );
}

String? _text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

import 'package:echurch_desktop/data/services/api/mappers/member_form_api_model_mapper.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_form_api_model.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';

extension DuplicateGroupApiModelMapper on DuplicateGroupApiModel {
  DuplicateGroup toDomain() => DuplicateGroup(kind: DuplicateKind.fromApi(kind), records: [for (final member in members) member.toDomain()]);
}

extension DuplicateMemberApiModelMapper on DuplicateMemberApiModel {
  DuplicateRecord toDomain() {
    final draft = person.toDraft();
    String? date(DateTime? value) => value == null ? null : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    String? text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
    final cpf = draft.cpf.replaceAll(RegExp(r'\D'), '');
    final address = person.address;
    final cityLine = [?text(address?.cityName), ?text(address?.stateAbbreviation)].join('/');
    final street = [?draft.streetType?.label, ?text(draft.streetName)].join(' ');
    final addressLine = [
      [if (street.isNotEmpty) street, ?text(draft.streetNumber)].join(', '),
      ?text(draft.complement),
      ?text(address?.districtName),
      if (cityLine.isNotEmpty) cityLine,
      if (text(draft.postalCode) case final cep?) 'CEP $cep',
    ].where((part) => part.isNotEmpty).join(' · ');
    return DuplicateRecord(
      id: person.id,
      name: draft.name,
      status: MemberStatus.fromApi(person.status),
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt!),
      ministryNames: person.ministryNames ?? const [],
      positions: positions ?? const [],
      credentialPrinted: person.credentialPrinted ?? false,
      values: {
        MergeField.name: text(draft.name),
        MergeField.cpf: cpf.length == 11 ? '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}' : text(draft.cpf),
        MergeField.rg: text(draft.rg),
        MergeField.birthDate: date(draft.birthDate),
        MergeField.gender: draft.gender?.label,
        MergeField.maritalStatus: draft.maritalStatus?.label,
        MergeField.spouseName: text(draft.spouseName),
        MergeField.fatherName: text(draft.fatherName),
        MergeField.motherName: text(draft.motherName),
        MergeField.birthCity: draft.birthCity?.label,
        MergeField.nationality: draft.nationality == 'BRAZILIAN' ? 'Brasileiro' : text(draft.nationality),
        MergeField.profession: draft.profession?.name,
        MergeField.address: addressLine.isEmpty ? null : addressLine,
        MergeField.phone: text(draft.phone),
        MergeField.secondaryPhone: text(draft.secondaryPhone),
        MergeField.email: text(draft.email),
        MergeField.church: text(person.churchName),
        MergeField.ecclesiasticalRole: text(person.ecclesiasticalRoleName),
        MergeField.baptismDate: date(draft.baptismDate),
        MergeField.acceptedJesusDate: date(draft.acceptedJesusDate),
        MergeField.notes: text(draft.notes),
      },
    );
  }
}

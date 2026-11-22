import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/member/member_form_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member_form.dart';

extension MemberEditApiModelMapper on MemberEditApiModel {
  MemberDraft toDraft() {
    final address = this.address;
    return MemberDraft(
      id: id,
      name: (name ?? '').trim(),
      birthDate: _date(birthDate),
      gender: Gender.fromApi(gender),
      nationality: nationality ?? NationalityOption.brazilian.value,
      birthCity: birthCityId == null ? null : CityOption(id: birthCityId!, name: birthCityName ?? '', state: birthCityState),
      profession: professionId == null ? null : NamedOption(id: professionId!, name: professionName ?? ''),
      cpf: cpf ?? '',
      rg: rg ?? '',
      maritalStatus: MaritalStatus.fromApi(maritalStatus),
      spouseName: spouseName ?? '',
      spouseId: spouseId,
      fatherName: fatherName ?? '',
      motherName: motherName ?? '',
      addressId: address?.id,
      postalCode: address?.postalCode ?? '',
      streetType: StreetType.fromApi(address?.streetType),
      streetName: address?.streetName ?? '',
      streetNumber: address?.streetNumber ?? '',
      complement: address?.complement ?? '',
      city: address?.cityId == null ? null : CityOption(id: address!.cityId!, name: address.cityName ?? '', state: address.stateAbbreviation),
      district: address?.district == null ? null : NamedOption(id: address!.district!, name: address.districtName ?? ''),
      contactId: contact?.id,
      phone: contact?.phone ?? '',
      secondaryPhone: contact?.secondaryPhone ?? '',
      email: contact?.email ?? '',
      facebook: contact?.facebook,
      twitter: contact?.twitter,
      instagram: contact?.instagram,
      churchId: churchId,
      ecclesiasticalRoleId: ecclesiasticalRoleId,
      ministryIds: {...?ministryIds},
      baptismDate: _date(baptismDate),
      acceptedJesusDate: _date(acceptedJesusDate),
      notes: notes ?? '',
      status: status ?? 'ACTIVE',
      individualType: individualType ?? 'MEMBER',
      deathDate: _date(deathDate),
    );
  }
}

extension MemberDraftMapper on MemberDraft {
  /// Texto vazio vai como nulo; CPF só com os dígitos.
  MemberInput toInput() => MemberInput(
    id: id,
    name: _text(name),
    birthDate: _iso(birthDate),
    cpf: _text(cpf.replaceAll(RegExp(r'\D'), '')),
    rg: _text(rg),
    gender: gender?.apiValue,
    fatherName: _text(fatherName),
    motherName: _text(motherName),
    maritalStatus: maritalStatus?.apiValue,
    spouseName: canHaveSpouse ? _text(spouseName) : null,
    spouseId: canHaveSpouse ? spouseId : null,
    birthCityId: birthCity?.id,
    nationality: nationality,
    professionId: profession?.id,
    address: MemberAddressInput(
      id: addressId,
      streetType: streetType?.apiValue,
      streetName: _text(streetName),
      streetNumber: _text(streetNumber),
      complement: _text(complement),
      postalCode: _text(postalCode.replaceAll(RegExp(r'\D'), '')),
      district: district?.id,
    ),
    contact: MemberContactInput(
      id: contactId,
      email: _text(email),
      phone: _text(phone),
      secondaryPhone: _text(secondaryPhone),
      facebook: facebook,
      twitter: twitter,
      instagram: instagram,
    ),
    notes: _text(notes),
    status: status,
    ecclesiasticalRoleId: ecclesiasticalRoleId,
    ministryIds: ministryIds.toList(),
    churchId: churchId,
    deathDate: _iso(deathDate),
    acceptedJesusDate: _iso(acceptedJesusDate),
    baptismDate: _iso(baptismDate),
    individualType: individualType,
  );
}

extension MemberOptionsApiModelMapper on MemberOptionsApiModel {
  MemberFormOptions toDomain() => MemberFormOptions(
    roles: _options(ecclesiasticalRoles),
    ministries: _options(ministries),
    nationalities: [
      for (final item in nationalityOptions ?? const <NationalityApiModel>[]) NationalityOption(value: item.value, label: item.label ?? item.value),
    ].ifEmpty([NationalityOption.brazilian]),
  );

  static List<NamedOption> _options(List<MemberOptionApiModel>? items) => [
    for (final item in items ?? const <MemberOptionApiModel>[])
      if ((item.name ?? '').trim().isNotEmpty) NamedOption(id: item.id, name: item.name!.trim()),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

extension CepApiModelMapper on CepApiModel {
  CepAddress toDomain(String postalCode) {
    final (type, street) = StreetType.split(logradouro ?? '');
    return CepAddress(
      postalCode: postalCode,
      streetType: type,
      street: street,
      complement: (complemento ?? '').trim(),
      district: (bairro ?? '').trim(),
      city: (localidade ?? '').trim(),
      state: (uf ?? '').trim(),
      cityId: cityId,
      districtId: districtId,
    );
  }
}

extension on List<NationalityOption> {
  List<NationalityOption> ifEmpty(List<NationalityOption> fallback) => isEmpty ? fallback : this;
}

String? _text(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String? _iso(DateTime? date) => date == null ? null : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? _date(String? value) => value == null ? null : DateTime.tryParse(value);

import 'package:echurch_desktop/data/services/api/model/member/member_api_model.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';

extension MemberRowApiModelMapper on MemberRowApiModel {
  MemberRow toDomain() => MemberRow(
    id: id,
    name: (name ?? '').trim(),
    status: MemberStatus.fromApi(status),
    ecclesiasticalRoleName: _text(ecclesiasticalRoleName),
    churchId: churchId,
    churchName: _text(churchName),
    phone: _text(phone),
    birthDay: birthDay,
    birthMonth: birthMonth,
    credentialPrinted: credentialPrinted ?? false,
    deactivationReason: DeactivationReason.fromApi(deactivationReason),
  );
}

extension MemberPageApiModelMapper on MemberPageApiModel {
  MemberPage toDomain() => MemberPage(items: [for (final item in items) item.toDomain()], total: total, page: page, size: size);
}

extension MemberDetailsApiModelMapper on MemberDetailsApiModel {
  /// A versão reduzida (quem só consulta) não tem `contact`: o contato vem no topo.
  MemberDetails toDomain() => MemberDetails(
    id: id,
    name: (name ?? '').trim(),
    status: MemberStatus.fromApi(status),
    ecclesiasticalRoleName: _text(ecclesiasticalRoleName),
    ministryNames: ministryNames ?? const [],
    churchName: _text(churchName),
    birthDate: _date(birthDate),
    birthDay: birthDay,
    birthMonth: birthMonth,
    gender: switch (gender) {
      'M' => 'Masculino',
      'F' => 'Feminino',
      _ => null,
    },
    maritalStatus: switch (maritalStatus) {
      'SINGLE' => 'Solteiro(a)',
      'MARRIED' => 'Casado(a)',
      'DIVORCED' => 'Divorciado(a)',
      'WIDOWED' => 'Viúvo(a)',
      'SEPARATED' => 'Separado(a)',
      _ => null,
    },
    spouseName: _text(spouseName),
    fatherName: _text(fatherName),
    motherName: _text(motherName),
    cpf: _text(cpf),
    rg: _text(rg),
    phone: _text(contact?.phone ?? phone),
    secondaryPhone: _text(contact?.secondaryPhone ?? secondaryPhone),
    email: _text(contact?.email ?? email),
    address: address?.toLine(),
    baptismDate: _date(baptismDate),
    acceptedJesusDate: _date(acceptedJesusDate),
    notes: _text(notes),
    deactivationReason: DeactivationReason.fromApi(deactivationReason),
    deactivationDescription: _text(deactivationDescription),
    deactivatedAt: _date(deactivatedAt),
    deactivatedByName: _text(deactivatedByName),
  );
}

extension MemberAddressApiModelMapper on MemberAddressApiModel {
  /// "Rua das Flores, 120 - Apto 3 - Centro, Rolândia/PR - CEP 86600-000"; nulo quando vazio.
  String? toLine() {
    final type = switch (streetType) {
      'AVENUE' => 'Avenida',
      'ROAD' => 'Estrada',
      'MARGINAL' => 'Marginal',
      'HIGHWAY' => 'Rodovia',
      'STREET' => 'Rua',
      'LANE' => 'Travessa',
      _ => null,
    };
    final street = [?type, ?_text(streetName)].join(' ');
    final city = [?_text(cityName), ?_text(stateAbbreviation)].join('/');
    final parts = [
      [if (street.isNotEmpty) street, ?_text(streetNumber)].join(', '),
      ?_text(complement),
      [?_text(districtName), if (city.isNotEmpty) city].join(', '),
      if (_text(postalCode) case final cep?) 'CEP $cep',
    ].where((part) => part.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' - ');
  }
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(String? value) => value == null ? null : DateTime.tryParse(value);

import 'package:echurch_desktop/data/services/api/model/user/password_reset_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/user/user_summary_api_model.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';

extension UserSummaryApiModelMapper on UserSummaryApiModel {
  ManagedUser toDomain() => ManagedUser(
    id: id,
    login: login,
    name: (name ?? '').trim().isEmpty ? login : name!.trim(),
    active: active ?? false,
    firstAccess: firstAccess ?? false,
    groups: groups ?? const [],
    groupIds: groupIds ?? const [],
    churchId: churchId,
    churchName: (churchName ?? '').trim().isEmpty ? null : churchName!.trim(),
  );
}

extension PasswordResetApiModelMapper on PasswordResetApiModel {
  PasswordReset toDomain() => PasswordReset(login: login, temporaryPassword: temporaryPassword);
}

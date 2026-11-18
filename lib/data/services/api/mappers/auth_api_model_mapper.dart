import 'package:echurch_desktop/data/services/api/model/auth/token_api_model.dart';
import 'package:echurch_desktop/data/services/api/model/auth/user_me_api_model.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';

extension TokenApiModelMapper on TokenApiModel {
  AuthTokens toDomain() => AuthTokens(
    accessToken: accessToken,
    accessTokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(accessTokenExpiresAt),
    refreshToken: refreshToken,
    refreshTokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(refreshTokenExpiresAt),
  );
}

extension UserMeApiModelMapper on UserMeApiModel {
  AuthSessionUser toDomain() => AuthSessionUser(
    login: login,
    name: name.trim().isEmpty ? login : name.trim(),
    firstAccess: firstAccess ?? false,
    churchId: churchId,
  );
}

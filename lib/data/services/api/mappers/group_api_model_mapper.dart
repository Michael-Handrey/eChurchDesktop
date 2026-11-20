import 'package:echurch_desktop/data/services/api/model/group/group_api_model.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';

extension GroupApiModelMapper on GroupApiModel {
  SecurityGroup toDomain() => SecurityGroup(id: id, name: name, permissions: permissions ?? const [], userCount: userCount ?? 0);
}

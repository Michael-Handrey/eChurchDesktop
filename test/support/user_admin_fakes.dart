import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/exceptions/app_exception.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/data/repositories/church/church_repository.dart';
import 'package:echurch_desktop/data/repositories/group_admin/group_admin_repository.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/repositories/user_admin/user_admin_repository.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/domain/models/user/managed_user.dart';
import 'package:echurch_desktop/domain/models/user/security_group.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_restore_session_use_case.dart';

import 'auth_fakes.dart';

const admin = AuthSessionUser(login: 'admin', name: 'Administrador', firstAccess: false, roles: [AuthSessionUser.adminRole]);
const secretary = AuthSessionUser(login: 'maria', name: 'Maria Silva', firstAccess: false, roles: ['ROLE_SECRETARIA', 'ROLE_USER']);

const groups = [
  SecurityGroup(id: 1, name: 'ADMIN', permissions: ['ROLE_ADMIN'], userCount: 1),
  SecurityGroup(id: 3, name: 'SECRETARIA', permissions: ['ROLE_SECRETARIA'], userCount: 1),
  SecurityGroup(id: 2, name: 'USUARIO', permissions: ['ROLE_USER'], userCount: 2),
];

const churches = [
  ChurchSummary(id: 1, name: 'Sede - Rolândia', headquarters: true),
  ChurchSummary(id: 2, name: 'Filial - Londrina'),
  ChurchSummary(id: 3, name: 'Filial - Maringá'),
];

const permissionsCatalog = ['ROLE_ADMIN', 'ROLE_SECRETARIA', 'ROLE_USER'];

const users = [
  ManagedUser(id: 1, login: 'admin', name: 'Administrador', active: true, firstAccess: false, groups: ['ADMIN'], groupIds: [1], churchId: 1, churchName: 'Sede - Rolândia'),
  ManagedUser(id: 2, login: 'maria', name: 'Maria Silva', active: true, firstAccess: false, groups: ['SECRETARIA', 'USUARIO'], groupIds: [3, 2], churchId: 2, churchName: 'Filial - Londrina'),
  ManagedUser(id: 3, login: 'joao', name: 'João Souza', active: false, firstAccess: false, groups: ['USUARIO'], groupIds: [2], churchId: 1, churchName: 'Sede - Rolândia'),
];

/// Sessão já iniciada com [user] (sem passar pela restauração do storage).
AuthSessionNotifier sessionSignedInAs(AuthSessionUser user) {
  final sessions = AuthSessionRepositoryLocal(storage: FakeSecureStorage());
  final auth = FakeAuthRepository();
  return AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(authRepository: auth, authSessionRepository: sessions),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: sessions,
      authRefreshSessionUseCase: AuthRefreshSessionUseCase(authRepository: auth, authSessionRepository: sessions),
    ),
    sessionEnded: const Stream.empty(),
  )..signedIn(user);
}

class FakeUserAdminRepository implements UserAdminRepository {
  List<ManagedUser> stored = [...users];
  AppException? listError;
  AppException? resetError;
  AppException? groupsError;
  AppException? activeError;
  AppException? churchError;
  final churchCalls = <({int userId, int churchId})>[];
  final activeCalls = <({int userId, bool active})>[];
  final resetCalls = <({int userId, String? temporaryPassword})>[];
  final groupCalls = <({int userId, Set<int> groupIds})>[];
  final personCalls = <({int userId, int? personId})>[];
  AppException? personError;

  @override
  Future<Result<List<ManagedUser>>> list() async => listError == null ? Result.ok(stored) : Result.error(listError!);

  @override
  Future<Result<PasswordReset>> resetPassword({required int userId, String? temporaryPassword}) async {
    resetCalls.add((userId: userId, temporaryPassword: temporaryPassword));
    if (resetError case final error?) return Result.error(error);
    final login = stored.firstWhere((user) => user.id == userId).login;
    return Result.ok(PasswordReset(login: login, temporaryPassword: temporaryPassword ?? 'Gerada@1234'));
  }

  @override
  Future<Result<ManagedUser>> setActive({required int userId, required bool active}) async {
    activeCalls.add((userId: userId, active: active));
    if (activeError case final error?) return Result.error(error);
    final updated = stored.firstWhere((user) => user.id == userId).copyWith(active: active);
    stored = [for (final user in stored) user.id == userId ? updated : user];
    return Result.ok(updated);
  }

  @override
  Future<Result<ManagedUser>> setChurch({required int userId, required int churchId}) async {
    churchCalls.add((userId: userId, churchId: churchId));
    if (churchError case final error?) return Result.error(error);
    final church = churches.firstWhere((church) => church.id == churchId);
    final current = stored.firstWhere((user) => user.id == userId);
    final updated = ManagedUser(
      id: current.id,
      login: current.login,
      name: current.name,
      active: current.active,
      firstAccess: current.firstAccess,
      groups: current.groups,
      groupIds: current.groupIds,
      churchId: church.id,
      churchName: church.name,
    );
    stored = [for (final user in stored) user.id == userId ? updated : user];
    return Result.ok(updated);
  }

  @override
  Future<Result<ManagedUser>> setPerson({required int userId, int? personId}) async {
    personCalls.add((userId: userId, personId: personId));
    if (personError case final error?) return Result.error(error);
    final current = stored.firstWhere((user) => user.id == userId);
    final updated = ManagedUser(
      id: current.id,
      login: current.login,
      name: current.name,
      active: current.active,
      firstAccess: current.firstAccess,
      groups: current.groups,
      groupIds: current.groupIds,
      churchId: current.churchId,
      churchName: current.churchName,
      personId: personId,
      personName: personId == null ? null : 'Membro $personId',
    );
    stored = [for (final user in stored) user.id == userId ? updated : user];
    return Result.ok(updated);
  }

  @override
  Future<Result<ManagedUser>> updateGroups({required int userId, required Set<int> groupIds}) async {
    groupCalls.add((userId: userId, groupIds: groupIds));
    if (groupsError case final error?) return Result.error(error);
    final chosen = [
      for (final group in groups)
        if (groupIds.contains(group.id)) group,
    ];
    final updated = stored.firstWhere((user) => user.id == userId).copyWith(groups: [for (final group in chosen) group.name], groupIds: [for (final group in chosen) group.id]);
    stored = [for (final user in stored) user.id == userId ? updated : user];
    return Result.ok(updated);
  }
}

class FakeGroupAdminRepository implements GroupAdminRepository {
  List<SecurityGroup> stored = [...groups];
  AppException? listError;
  AppException? saveError;
  AppException? deleteError;
  final saveCalls = <({int? id, String name, Set<String> permissions})>[];
  final deleteCalls = <int>[];

  @override
  Future<Result<List<SecurityGroup>>> list() async => listError == null ? Result.ok(stored) : Result.error(listError!);

  @override
  Future<Result<List<String>>> permissions() async => const Result.ok(permissionsCatalog);

  @override
  Future<Result<SecurityGroup>> save({int? id, required String name, required Set<String> permissions}) async {
    saveCalls.add((id: id, name: name, permissions: permissions));
    if (saveError case final error?) return Result.error(error);
    final previous = stored.where((group) => group.id == id).firstOrNull;
    final saved = SecurityGroup(id: id ?? 10, name: name, permissions: permissions.toList()..sort(), userCount: previous?.userCount ?? 0);
    stored = previous == null ? [...stored, saved] : [for (final group in stored) group.id == id ? saved : group];
    return Result.ok(saved);
  }

  @override
  Future<Result<void>> delete(int id) async {
    deleteCalls.add(id);
    if (deleteError case final error?) return Result.error(error);
    stored = [
      for (final group in stored)
        if (group.id != id) group,
    ];
    return Result.done;
  }
}

/// [stored]: as igrejas que a API devolveria para o usuário logado (todas, por padrão).
class FakeChurchRepository([final List<ChurchSummary> stored = churches]) implements ChurchRepository {
  AppException? listError;

  @override
  Future<Result<List<ChurchSummary>>> list() async => listError == null ? Result.ok(stored) : Result.error(listError!);
}

/// Busca de membros para ligar ao usuário (só `search` é usado nas telas de usuários).
class FakeMemberSearchRepository implements MemberRepository {
  final texts = <String>[];

  @override
  Future<Result<MemberPage>> search({int? churchId, MemberStatus? status, String? text, int? ecclesiasticalRoleId, int page = 0, int size = 20}) async {
    texts.add(text ?? '');
    return const Result.ok(
      MemberPage(
        items: [MemberRow(id: 10, name: 'João Pedro', status: MemberStatus.active, churchName: 'Sede - Rolândia')],
        total: 1,
        page: 0,
        size: 8,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

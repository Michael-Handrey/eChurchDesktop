import 'package:dio/dio.dart';
import 'package:echurch_desktop/data/repositories/dashboard/dashboard_repository.dart';
import 'package:echurch_desktop/data/services/api/dashboard_api.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository.dart';
import 'package:echurch_desktop/data/repositories/ministry/ministry_repository_remote.dart';
import 'package:echurch_desktop/data/services/api/ministry_api.dart';
import 'package:echurch_desktop/data/repositories/member/lookup_repository.dart';
import 'package:echurch_desktop/data/repositories/member/lookup_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository_remote.dart';
import 'package:echurch_desktop/data/services/api/lookup_api.dart';
import 'package:echurch_desktop/data/services/api/member_api.dart';
import 'package:echurch_desktop/config/environment.dart';
import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository.dart';
import 'package:echurch_desktop/data/repositories/account/account_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/data/repositories/church/church_repository.dart';
import 'package:echurch_desktop/data/repositories/church/church_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/group_admin/group_admin_repository.dart';
import 'package:echurch_desktop/data/repositories/group_admin/group_admin_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/prayer_request/prayer_request_repository.dart';
import 'package:echurch_desktop/data/repositories/prayer_request/prayer_request_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/user_admin/user_admin_repository.dart';
import 'package:echurch_desktop/data/repositories/user_admin/user_admin_repository_remote.dart';
import 'package:echurch_desktop/data/services/api/account_api.dart';
import 'package:echurch_desktop/data/services/api/auth_api.dart';
import 'package:echurch_desktop/data/services/api/church_api.dart';
import 'package:echurch_desktop/data/services/api/group_admin_api.dart';
import 'package:echurch_desktop/data/services/api/interceptors/auth_interceptor.dart';
import 'package:echurch_desktop/data/services/api/prayer_request_api.dart';
import 'package:echurch_desktop/data/services/api/user_admin_api.dart';
import 'package:echurch_desktop/data/services/local/secure_storage_service.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_refresh_session_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:echurch_desktop/routing/router.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

BaseOptions _apiOptions() => BaseOptions(
  baseUrl: Environment.baseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 20),
);

/// Dependências globais do app (serviços, repositórios, notifiers e router).
/// ViewModels de tela ficam nos `*Bindings` de cada feature em `ui/`.
/// A ordem importa: cada provider lê os anteriores com `context.read()`.
class const ApplicationBindings({super.key, required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => SecureStorageService()),
        Provider<AuthSessionRepository>(create: (context) => AuthSessionRepositoryLocal(storage: context.read())),

        // Dio próprio da AuthApi, sem AuthInterceptor: o interceptor depende do refresh,
        // que usa esta API (evita ciclo e renovação dentro de renovação).
        Provider(create: (context) => AuthApi(Dio(_apiOptions()))),
        Provider<AuthRepository>(create: (context) => AuthRepositoryRemote(authApi: context.read())),
        Provider(
          create: (context) => AuthRefreshSessionUseCase(authRepository: context.read(), authSessionRepository: context.read()),
        ),

        Provider(
          create: (context) => AuthInterceptor(
            sessions: context.read(),
            refreshSession: context.read<AuthRefreshSessionUseCase>().refresh,
            retryClient: Dio(_apiOptions()),
          ),
          dispose: (context, interceptor) => interceptor.dispose(),
        ),

        // Dio das demais APIs (membros, igrejas...): Bearer automático e renovação no 401.
        Provider(create: (context) => Dio(_apiOptions())..interceptors.add(context.read<AuthInterceptor>())),

        Provider(create: (context) => AccountApi(context.read())),
        Provider<AccountRepository>(create: (context) => AccountRepositoryRemote(accountApi: context.read())),

        Provider(create: (context) => UserAdminApi(context.read())),
        Provider<UserAdminRepository>(create: (context) => UserAdminRepositoryRemote(userAdminApi: context.read())),

        Provider(create: (context) => ChurchApi(context.read())),
        Provider<ChurchRepository>(create: (context) => ChurchRepositoryRemote(churchApi: context.read())),

        Provider(create: (context) => MemberApi(context.read())),
        Provider(create: (context) => LookupApi(context.read())),
        Provider<LookupRepository>(create: (context) => LookupRepositoryRemote(api: context.read())),
        Provider<MemberRepository>(create: (context) => MemberRepositoryRemote(api: context.read())),

        Provider(create: (context) => DashboardApi(context.read())),
        Provider<DashboardRepository>(create: (context) => DashboardRepositoryRemote(api: context.read())),

        Provider(create: (context) => MinistryApi(context.read())),
        Provider<MinistryRepository>(create: (context) => MinistryRepositoryRemote(api: context.read())),

        Provider(create: (context) => PrayerRequestApi(context.read())),
        Provider<PrayerRequestRepository>(create: (context) => PrayerRequestRepositoryRemote(api: context.read())),

        Provider(create: (context) => GroupAdminApi(context.read())),
        Provider<GroupAdminRepository>(create: (context) => GroupAdminRepositoryRemote(groupAdminApi: context.read())),

        Provider(
          create: (context) => AuthLogoutUseCase(authRepository: context.read(), authSessionRepository: context.read()),
        ),
        Provider(
          create: (context) => AuthRestoreSessionUseCase(authSessionRepository: context.read(), authRefreshSessionUseCase: context.read()),
        ),

        ChangeNotifierProvider(
          lazy: false,
          create: (context) => AuthSessionNotifier(
            authLogoutUseCase: context.read(),
            authRestoreSessionUseCase: context.read(),
            sessionEnded: context.read<AuthInterceptor>().onUnauthorized,
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => ChurchContextNotifier(churchRepository: context.read(), sessionNotifier: context.read()),
        ),
        Provider<GoRouter>(create: (context) => router(context.read())),
      ],
      child: child,
    );
  }
}

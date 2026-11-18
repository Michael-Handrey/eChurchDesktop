import 'package:dio/dio.dart';
import 'package:echurch_desktop/config/environment.dart';
import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository.dart';
import 'package:echurch_desktop/data/repositories/auth/auth_repository_remote.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository.dart';
import 'package:echurch_desktop/data/repositories/auth_session/auth_session_repository_local.dart';
import 'package:echurch_desktop/data/services/api/auth_api.dart';
import 'package:echurch_desktop/data/services/api/interceptors/auth_interceptor.dart';
import 'package:echurch_desktop/data/services/local/secure_storage_service.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:echurch_desktop/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:echurch_desktop/routing/router.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Dependências globais do app (serviços, repositórios, notifiers e router).
/// ViewModels de tela ficam nos `*Bindings` de cada feature em `ui/`.
/// A ordem importa: cada provider lê os anteriores com `context.read()`.
class const ApplicationBindings({super.key, required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => SecureStorageService()),

        Provider(
          create: (context) => AuthInterceptor(storage: context.read()),
          dispose: (context, interceptor) => interceptor.dispose(),
        ),

        Provider(
          create: (context) => Dio(
            BaseOptions(
              baseUrl: Environment.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
          )..interceptors.add(context.read<AuthInterceptor>()),
        ),

        Provider(create: (context) => AuthApi(context.read())),
        Provider<AuthRepository>(create: (context) => AuthRepositoryRemote(authApi: context.read())),
        Provider<AuthSessionRepository>(create: (context) => AuthSessionRepositoryLocal(storage: context.read())),

        Provider(create: (context) => AuthLogoutUseCase(authRepository: context.read(), authSessionRepository: context.read())),
        Provider(create: (context) => AuthRestoreSessionUseCase(authRepository: context.read(), authSessionRepository: context.read())),

        ChangeNotifierProvider(
          lazy: false,
          create: (context) => AuthSessionNotifier(
            authLogoutUseCase: context.read(),
            authRestoreSessionUseCase: context.read(),
            sessionEnded: context.read<AuthInterceptor>().onUnauthorized,
          ),
        ),
        Provider<GoRouter>(create: (context) => router(context.read())),
      ],
      child: child,
    );
  }
}

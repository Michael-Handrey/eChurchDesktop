import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/routing/routes.dart';
import 'package:echurch_desktop/ui/auth/first_access/first_access_bindings.dart';
import 'package:echurch_desktop/ui/auth/first_access/first_access_screen.dart';
import 'package:echurch_desktop/ui/auth/login/login_bindings.dart';
import 'package:echurch_desktop/ui/auth/login/login_screen.dart';
import 'package:echurch_desktop/ui/main/main_bindings.dart';
import 'package:echurch_desktop/ui/main/main_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter router(AuthSessionNotifier session) => GoRouter(
  initialLocation: Routes.login,
  refreshListenable: session,
  redirect: (_, state) {
    // Enquanto restaura a sessão guardada, fica onde está (login).
    if (!session.isRestored) return null;

    final location = state.matchedLocation;
    final isPublic = Routes.public.contains(location);

    if (!session.isSignedIn) return isPublic ? null : Routes.login;

    // Senha provisória: nenhuma outra tela até trocar.
    if (session.mustChangePassword) return location == Routes.firstAccess ? null : Routes.firstAccess;

    return isPublic || location == Routes.firstAccess ? Routes.dashboard : null;
  },
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (_, _) => LoginBindings(
        screenBuilder: (context) => LoginScreen(viewModel: context.read(), session: context.read()),
      ),
    ),
    GoRoute(
      path: Routes.firstAccess,
      builder: (_, _) => FirstAccessBindings(
        screenBuilder: (context) => FirstAccessScreen(viewModel: context.read()),
      ),
    ),
    GoRoute(
      path: Routes.dashboard,
      builder: (_, _) => MainBindings(
        screenBuilder: (context) => const MainScreen(),
      ),
    ),
  ],
);

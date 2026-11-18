import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/routing/routes.dart';
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

    final isPublic = Routes.public.contains(state.matchedLocation);

    if (!session.isSignedIn) return isPublic ? null : Routes.login;

    return isPublic ? Routes.dashboard : null;
  },
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (_, _) => LoginBindings(
        screenBuilder: (context) => LoginScreen(viewModel: context.read(), session: context.read()),
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

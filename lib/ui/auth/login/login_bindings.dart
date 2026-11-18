import 'package:echurch_desktop/domain/use_cases/auth/auth_login_use_case.dart';
import 'package:echurch_desktop/ui/auth/login/login_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class const LoginBindings({
  super.key,
  required final WidgetBuilder screenBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => AuthLoginUseCase(authRepository: context.read(), authSessionRepository: context.read()),
        ),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(loginUseCase: context.read(), sessionNotifier: context.read()),
        ),
      ],
      builder: (context, child) => screenBuilder(context),
    );
  }
}

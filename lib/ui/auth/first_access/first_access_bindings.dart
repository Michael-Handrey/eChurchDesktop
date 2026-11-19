import 'package:echurch_desktop/domain/use_cases/auth/auth_change_password_use_case.dart';
import 'package:echurch_desktop/ui/auth/first_access/first_access_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class const FirstAccessBindings({
  super.key,
  required final WidgetBuilder screenBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => AuthChangePasswordUseCase(accountRepository: context.read(), authRefreshSessionUseCase: context.read()),
        ),
        ChangeNotifierProvider(
          create: (context) => FirstAccessViewModel(changePasswordUseCase: context.read(), sessionNotifier: context.read()),
        ),
      ],
      builder: (context, child) => screenBuilder(context),
    );
  }
}

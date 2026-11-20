import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/ui/users/groups_viewmodel.dart';
import 'package:echurch_desktop/ui/users/users_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Tela de usuários: aba de usuários e aba de grupos e permissões.
class const UsersBindings({
  super.key,
  required final WidgetBuilder screenBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UsersViewModel(
            userAdminRepository: context.read(),
            groupAdminRepository: context.read(),
            churchRepository: context.read(),
            sessionNotifier: context.read(),
          ).initialized(),
        ),
        ChangeNotifierProvider(create: (context) => GroupsViewModel(groupAdminRepository: context.read()).initialized()),
      ],
      builder: (context, child) => screenBuilder(context),
    );
  }
}

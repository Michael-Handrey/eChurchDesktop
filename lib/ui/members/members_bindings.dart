import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class const MembersBindings({super.key, required final WidgetBuilder screenBuilder}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MembersViewModel(repository: context.read(), churchContext: context.read(), session: context.read()).initialized(),
        ),
      ],
      builder: (context, child) => screenBuilder(context),
    );
  }
}

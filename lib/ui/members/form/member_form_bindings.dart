import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/ui/members/form/member_form_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Formulário de membro: [memberId] nulo cadastra; com id, edita.
class const MemberFormBindings({super.key, final int? memberId, required final WidgetBuilder screenBuilder}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MemberFormViewModel(members: context.read(), lookup: context.read(), churchContext: context.read(), memberId: memberId).initialized(),
        ),
      ],
      builder: (context, child) => screenBuilder(context),
    );
  }
}

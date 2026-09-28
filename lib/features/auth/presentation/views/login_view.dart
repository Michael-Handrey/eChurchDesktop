import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/login_brand_panel_widget.dart';
import '../widgets/login_form_widget.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: LoginBrandPanelWidget(),
          ),
          Expanded(
            flex: 6,
            child: LoginFormWidget(),
          ),
        ],
      ),
    );
  }
}

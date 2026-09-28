import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';

abstract final class AppDependencies {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
    ChangeNotifierProvider(create: (_) => DashboardViewModel()),
  ];
}

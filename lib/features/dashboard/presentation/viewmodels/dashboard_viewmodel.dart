import 'package:flutter/widgets.dart';
import '../../../../domain/models/quick_stat_model.dart';
import '../../../../domain/models/recent_activity_model.dart';

class DashboardViewModel extends ChangeNotifier {
  String _selectedNavItem = 'membros';
  bool _isSecretariaExpanded = true;
  String _searchQuery = '';

  final List<QuickStatModel> _stats = const [
    QuickStatModel(
      label: 'Membros Ativos',
      count: 248,
      type: QuickStatType.members,
    ),
    QuickStatModel(
      label: 'Crianças Cadastradas',
      count: 72,
      type: QuickStatType.children,
    ),
    QuickStatModel(
      label: 'Pedidos de Oração',
      count: 18,
      type: QuickStatType.prayers,
    ),
  ];

  final List<RecentActivityModel> _activities = const [
    RecentActivityModel(
      id: '1',
      title: 'João da Silva',
      type: ActivityType.member,
      timeAgo: 'Há 2 horas',
    ),
    RecentActivityModel(
      id: '2',
      title: 'Ana Beatriz Santos',
      type: ActivityType.child,
      timeAgo: 'Há 3 horas',
    ),
    RecentActivityModel(
      id: '3',
      title: 'Pedido de oração - Família Oliveira',
      type: ActivityType.prayer,
      timeAgo: 'Há 4 horas',
    ),
    RecentActivityModel(
      id: '4',
      title: 'Maria Fernandes',
      type: ActivityType.member,
      timeAgo: 'Há 5 horas',
    ),
    RecentActivityModel(
      id: '5',
      title: 'Lucas Almeida',
      type: ActivityType.child,
      timeAgo: 'Há 6 horas',
    ),
  ];

  String get selectedNavItem => _selectedNavItem;
  bool get isSecretariaExpanded => _isSecretariaExpanded;
  String get searchQuery => _searchQuery;
  List<QuickStatModel> get stats => _stats;
  List<RecentActivityModel> get activities => _activities;

  void selectNavItem(String itemKey) {
    if (_selectedNavItem != itemKey) {
      _selectedNavItem = itemKey;
      notifyListeners();
    }
  }

  void toggleSecretaria() {
    _isSecretariaExpanded = !_isSecretariaExpanded;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/domain/models/dashboard/recent_activity.dart';
import 'package:flutter/widgets.dart';

class DashboardViewModel extends ChangeNotifier {
  /// Item da sidebar que abre a tela de usuários (só administrador).
  static const usersNavItem = 'usuarios';

  String _selectedNavItem = 'inicio';
  bool _isSecretariaExpanded = false;
  bool _isSettingsExpanded = false;
  bool _isReportsExpanded = false;
  String _searchQuery = '';

  final List<QuickStat> _stats = const [
    QuickStat(
      label: 'Membros Ativos',
      count: 248,
      type: QuickStatType.members,
    ),
    QuickStat(
      label: 'Crianças Cadastradas',
      count: 72,
      type: QuickStatType.children,
    ),
    QuickStat(
      label: 'Pedidos de Oração',
      count: 18,
      type: QuickStatType.prayers,
    ),
  ];

  final List<RecentActivity> _activities = const [
    RecentActivity(
      id: '1',
      title: 'João da Silva',
      type: ActivityType.member,
      timeAgo: 'Há 2 horas',
    ),
    RecentActivity(
      id: '2',
      title: 'Ana Beatriz Santos',
      type: ActivityType.child,
      timeAgo: 'Há 3 horas',
    ),
    RecentActivity(
      id: '3',
      title: 'Pedido de oração - Família Oliveira',
      type: ActivityType.prayer,
      timeAgo: 'Há 4 horas',
    ),
    RecentActivity(
      id: '4',
      title: 'Maria Fernandes',
      type: ActivityType.member,
      timeAgo: 'Há 5 horas',
    ),
    RecentActivity(
      id: '5',
      title: 'Lucas Almeida',
      type: ActivityType.child,
      timeAgo: 'Há 6 horas',
    ),
  ];

  String get selectedNavItem => _selectedNavItem;
  bool get isSecretariaExpanded => _isSecretariaExpanded;
  bool get isSettingsExpanded => _isSettingsExpanded;
  bool get isReportsExpanded => _isReportsExpanded;
  String get searchQuery => _searchQuery;
  List<QuickStat> get stats => _stats;
  List<RecentActivity> get activities => _activities;

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

  void toggleReports() {
    _isReportsExpanded = !_isReportsExpanded;
    notifyListeners();
  }

  void toggleSettings() {
    _isSettingsExpanded = !_isSettingsExpanded;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

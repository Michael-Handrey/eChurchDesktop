import 'package:echurch_desktop/domain/models/dashboard/birthday.dart';
import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/domain/models/dashboard/recent_activity.dart';
import 'package:flutter/widgets.dart';

class DashboardViewModel extends ChangeNotifier {
  /// [birthdaysToday] e [birthdaysNext]: para testes (nulo = os dados fixos de hoje).
  DashboardViewModel({List<Birthday>? birthdaysToday, List<Birthday>? birthdaysNext}) : _birthdaysTodayOverride = birthdaysToday, _birthdaysNextOverride = birthdaysNext;

  final List<Birthday>? _birthdaysTodayOverride;
  final List<Birthday>? _birthdaysNextOverride;

  /// Item da sidebar que abre a tela de usuários (só administrador).
  static const usersNavItem = 'usuarios';
  static const prayerRequestsNavItem = 'oracao';

  String _selectedNavItem = 'inicio';
  bool _isSecretariaExpanded = false;
  bool _isSettingsExpanded = false;
  bool _isReportsExpanded = false;
  String _searchQuery = '';

  // Números fixos por enquanto: virão da API, da igreja em uso (FEAT-6 no TASKS do backend).
  final List<QuickStat> _stats = const [
    QuickStat(label: 'membros ativos', count: 248, type: QuickStatType.members),
    QuickStat(label: 'cadastradas', count: 72, type: QuickStatType.children),
    QuickStat(label: 'novos', count: 18, type: QuickStatType.prayers),
  ];

  // Aniversariantes fixos por enquanto: virão da API (membros e crianças ativos da igreja em uso).
  late final List<Birthday> _birthdaysToday =
      _birthdaysTodayOverride ??
      [
        Birthday(name: 'Maria Souza', date: _today, age: 34),
        Birthday(name: 'Pedro Lima', date: _today, age: 8, isChild: true),
        Birthday(name: 'Antônio Ferreira', date: _today, age: 61),
      ];

  late final List<Birthday> _birthdaysNext =
      _birthdaysNextOverride ??
      [
        Birthday(name: 'Carla Dias', date: _today.add(const Duration(days: 1)), age: 27),
        Birthday(name: 'Lucas Almeida', date: _today.add(const Duration(days: 3)), age: 12, isChild: true),
        Birthday(name: 'Joana Ribeiro', date: _today.add(const Duration(days: 5)), age: 45),
      ];

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

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

  /// Número do card de cima (membros, crianças ou pedidos de oração).
  QuickStat statOf(QuickStatType type) => _stats.firstWhere((stat) => stat.type == type);

  /// Quem faz aniversário hoje e nos próximos 7 dias (sem hoje).
  List<Birthday> get birthdaysToday => _birthdaysToday;
  List<Birthday> get birthdaysNext => _birthdaysNext;
  List<RecentActivity> get activities => _activities;

  void selectNavItem(String itemKey) {
    if (_selectedNavItem != itemKey) {
      _selectedNavItem = itemKey;
      notifyListeners();
    }
  }

  /// Abre uma tela a partir da tela inicial (cards): seleciona o item e abre a seção dele no
  /// menu lateral, para o item aparecer marcado.
  void openFromHome(String itemKey) {
    if (itemKey == prayerRequestsNavItem) _isSecretariaExpanded = true;
    _selectedNavItem = itemKey;
    notifyListeners();
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

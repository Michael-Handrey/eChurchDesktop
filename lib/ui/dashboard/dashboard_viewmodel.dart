import 'package:flutter/widgets.dart';

/// Menu lateral e navegação do shell. Os dados da tela inicial ficam no `HomeViewModel`.
class DashboardViewModel extends ChangeNotifier {
  /// Item da sidebar que abre a tela de usuários (só administrador).
  static const usersNavItem = 'usuarios';
  static const membersNavItem = 'membros';
  static const ministriesNavItem = 'ministerios';
  static const prayerRequestsNavItem = 'oracao';

  String _selectedNavItem = 'inicio';
  bool _isSecretariaExpanded = false;
  bool _isSettingsExpanded = false;
  bool _isReportsExpanded = false;
  String get selectedNavItem => _selectedNavItem;
  bool get isSecretariaExpanded => _isSecretariaExpanded;
  bool get isSettingsExpanded => _isSettingsExpanded;
  bool get isReportsExpanded => _isReportsExpanded;
  void selectNavItem(String itemKey) {
    if (_selectedNavItem != itemKey) {
      _selectedNavItem = itemKey;
      notifyListeners();
    }
  }

  /// Abre uma tela a partir da tela inicial (cards): seleciona o item e abre a seção dele no
  /// menu lateral, para o item aparecer marcado.
  void openFromHome(String itemKey) {
    if (itemKey == prayerRequestsNavItem || itemKey == membersNavItem) _isSecretariaExpanded = true;
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
}

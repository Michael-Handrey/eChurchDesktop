import 'package:echurch_desktop/core/church/church_context_notifier.dart';
import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/dashboard/dashboard_repository.dart';
import 'package:echurch_desktop/domain/models/dashboard/birthday.dart';
import 'package:echurch_desktop/domain/models/dashboard/quick_stat.dart';
import 'package:echurch_desktop/domain/models/dashboard/recent_activity.dart';
import 'package:flutter/foundation.dart';

/// Dados da tela inicial da igreja em uso: números dos cards, aniversariantes (hoje e próximos 7 dias)
/// e últimos registros. Busca ao abrir a tela e quando a igreja muda no seletor.
class HomeViewModel({required final DashboardRepository _repository, required final ChurchContextNotifier _churchContext}) extends ChangeNotifier implements ViewModelInitializable {
  final _log = AppLogger('HomeViewModel');

  late final load = Command0<void>(_load);

  var _data = const HomeData();
  int? _loadedChurchId;

  @override
  void init() {
    _churchContext.addListener(_onChurchChanged);
    _onChurchChanged();
  }

  /// Já carregou alguma vez (antes disso, os cards mostram "—").
  bool get loaded => _loadedChurchId != null && load.result is Ok;
  List<Birthday> get birthdaysToday => _data.birthdaysToday;
  List<Birthday> get birthdaysNext => _data.birthdaysNext;
  List<RecentActivity> get activities => _data.activities;

  /// Número do card (nulo enquanto não carregou).
  QuickStat? statOf(QuickStatType type) => _data.stats.where((stat) => stat.type == type).firstOrNull;

  void _onChurchChanged() {
    final id = _churchContext.selected?.id;
    if (id == null || id == _loadedChurchId) return;
    _loadedChurchId = id;
    load.execute();
  }

  Future<Result<void>> _load() async {
    final id = _churchContext.selected?.id;
    if (id == null) return Result.done;
    try {
      switch (await _repository.load(id)) {
        case Ok<HomeData>(:final value):
          _data = value;
          return Result.done;
        case Error<HomeData>(:final error):
          _log.error('Falha ao carregar o painel inicial', error: error, stackTrace: error.stackTrace);
          return Result.error(error);
      }
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _churchContext.removeListener(_onChurchChanged);
    load.dispose();
    super.dispose();
  }
}

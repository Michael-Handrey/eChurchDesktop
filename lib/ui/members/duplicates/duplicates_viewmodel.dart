import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/logging/app_logger.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/core/view_model_initializable.dart';
import 'package:echurch_desktop/data/repositories/member/member_repository.dart';
import 'package:echurch_desktop/domain/models/member/duplicate.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:flutter/foundation.dart';

/// Cadastros duplicados, um caso por vez: a secretaria escolhe qual cadastro fica e, nos campos
/// diferentes, de qual cadastro vem o valor. Junta de dois em dois (grupo com 3+: o próximo par
/// aparece depois de juntar).
class DuplicatesViewModel({required final MemberRepository _repository}) extends ChangeNotifier implements ViewModelInitializable {
  final _log = AppLogger('DuplicatesViewModel');

  late final load = Command0<void>(_load);
  late final merge = Command0<void>(_merge);
  late final dismiss = Command0<void>(_dismiss);

  var _groups = const <DuplicateGroup>[];
  var _index = 0;
  int? _keepId;

  /// Campos em que o valor vem do outro cadastro (o que será desativado).
  final _takeFromOther = <MergeField>{};

  /// Juntou ou separou algo (a lista de membros precisa recarregar ao voltar).
  var _changed = false;

  @override
  void init() => load.execute();

  List<DuplicateGroup> get groups => _groups;
  bool get isEmpty => _groups.isEmpty;
  int get index => _index;
  bool get changed => _changed;

  DuplicateGroup? get current => _groups.isEmpty ? null : _groups[_index];

  /// Os dois cadastros comparados agora (os dois primeiros do grupo).
  (DuplicateRecord, DuplicateRecord)? get pair {
    final group = current;
    if (group == null || group.records.length < 2) return null;
    return (group.records[0], group.records[1]);
  }

  /// Cadastros a mais no grupo (3 ou mais com o mesmo CPF), juntados depois.
  int get extraRecords => (current?.records.length ?? 0) > 2 ? current!.records.length - 2 : 0;

  int? get keepId => _keepId;
  DuplicateRecord? get keep => pair == null ? null : (pair!.$1.id == _keepId ? pair!.$1 : pair!.$2);
  DuplicateRecord? get remove => pair == null ? null : (pair!.$1.id == _keepId ? pair!.$2 : pair!.$1);

  /// Campos com valores diferentes nos dois cadastros (os que pedem escolha).
  List<MergeField> get differences {
    final (a, b) = pair ?? (null, null);
    if (a == null || b == null) return const [];
    return [
      for (final field in MergeField.values)
        if (_normalized(a.values[field]) != _normalized(b.values[field])) field,
    ];
  }

  /// O valor que fica, no campo: do cadastro [recordId]?
  bool isChosen(MergeField field, int recordId) => _takeFromOther.contains(field) ? recordId != _keepId : recordId == _keepId;

  /// Valor final de cada campo, depois de juntar.
  String? finalValue(MergeField field) => (_takeFromOther.contains(field) ? remove : keep)?.values[field];

  void setKeep(int id) {
    if (id == _keepId) return;
    _keepId = id;
    _suggestChoices();
    notifyListeners();
  }

  /// Escolhe de qual cadastro vem o valor do campo.
  void choose(MergeField field, int recordId) {
    recordId == _keepId ? _takeFromOther.remove(field) : _takeFromOther.add(field);
    notifyListeners();
  }

  void next() {
    if (_groups.length < 2) return;
    _index = (_index + 1) % _groups.length;
    _startCase();
    notifyListeners();
  }

  void previous() {
    if (_groups.length < 2) return;
    _index = (_index - 1 + _groups.length) % _groups.length;
    _startCase();
    notifyListeners();
  }

  /// Sugestão de qual fica: o ativo; depois o mais completo; depois o mais recente.
  void _startCase() {
    final (a, b) = pair ?? (null, null);
    if (a == null || b == null) {
      _keepId = null;
      _takeFromOther.clear();
      return;
    }
    int score(DuplicateRecord record) => (record.status == MemberStatus.active ? 1000 : 0) + record.filled;
    final scoreA = score(a);
    final scoreB = score(b);
    if (scoreA != scoreB) {
      _keepId = scoreA > scoreB ? a.id : b.id;
    } else {
      final dateA = a.createdAt ?? DateTime(1900);
      final dateB = b.createdAt ?? DateTime(1900);
      _keepId = dateB.isAfter(dateA) ? b.id : a.id;
    }
    _suggestChoices();
  }

  /// Nos campos diferentes, fica o valor do cadastro escolhido; se ele estiver vazio, vem do outro.
  void _suggestChoices() {
    _takeFromOther.clear();
    final keep = this.keep;
    final other = remove;
    if (keep == null || other == null) return;
    for (final field in differences) {
      if (_normalized(keep.values[field]).isEmpty && _normalized(other.values[field]).isNotEmpty) _takeFromOther.add(field);
    }
  }

  static String _normalized(String? value) => (value ?? '').trim().toLowerCase();

  Future<Result<void>> _load() async {
    final result = await _repository.duplicates();
    switch (result) {
      case Ok<List<DuplicateGroup>>(:final value):
        _groups = value;
        if (_index >= _groups.length) _index = 0;
        _startCase();
        notifyListeners();
        return Result.done;
      case Error<List<DuplicateGroup>>(:final error):
        _log.error('Falha ao carregar os cadastros duplicados', error: error, stackTrace: error.stackTrace);
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _merge() async {
    final keep = this.keep;
    final other = remove;
    if (keep == null || other == null) return Result.done;
    final result = await _repository.mergeDuplicates(keepId: keep.id, removeId: other.id, takeFromRemoved: {..._takeFromOther});
    if (result case Error<void>(:final error)) {
      _log.error('Falha ao juntar os cadastros ${keep.id} e ${other.id}', error: error, stackTrace: error.stackTrace);
      return result;
    }
    _log.info('Cadastros juntados: fica ${keep.id}, desativado ${other.id}');
    _changed = true;
    return _load();
  }

  Future<Result<void>> _dismiss() async {
    final (a, b) = pair ?? (null, null);
    if (a == null || b == null || current?.kind != DuplicateKind.nameBirth) return Result.done;
    final result = await _repository.dismissDuplicate(a.id, b.id);
    if (result case Error<void>(:final error)) {
      _log.error('Falha ao separar os cadastros ${a.id} e ${b.id}', error: error, stackTrace: error.stackTrace);
      return result;
    }
    _changed = true;
    return _load();
  }

  @override
  void dispose() {
    load.dispose();
    merge.dispose();
    dismiss.dispose();
    super.dispose();
  }
}

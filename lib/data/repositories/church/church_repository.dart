import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';

abstract interface class ChurchRepository {
  /// Igrejas que o usuário logado alcança (a API aplica a regra "sede supervisiona"):
  /// administrador, todas; secretaria da sede, sede e filiais; os demais, só a própria.
  /// Sede primeiro, depois as filiais.
  Future<Result<List<ChurchSummary>>> list();
}

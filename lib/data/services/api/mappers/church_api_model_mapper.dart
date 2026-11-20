import 'package:echurch_desktop/data/services/api/model/church/church_summary_api_model.dart';
import 'package:echurch_desktop/domain/models/church/church_summary.dart';

extension ChurchSummaryApiModelMapper on ChurchSummaryApiModel {
  ChurchSummary toDomain() => ChurchSummary(id: id, name: (name ?? '').trim().isEmpty ? 'Igreja $id' : name!.trim(), headquarters: headquarters ?? false);
}

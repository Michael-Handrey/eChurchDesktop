enum QuickStatType {
  members,
  children,
  prayers,
}

/// Número de um card da tela inicial, ex.: 248 "membros ativos".
class QuickStat {
  final String label;

  /// Nulo enquanto não carregou (o card mostra "—").
  final int? count;
  final QuickStatType type;

  const QuickStat({
    required this.label,
    this.count,
    required this.type,
  });
}

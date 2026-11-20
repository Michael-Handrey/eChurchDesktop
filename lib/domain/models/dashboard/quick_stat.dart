enum QuickStatType {
  members,
  birthdays,
  children,
  prayers,
}

class QuickStat {
  final String label;
  final int count;
  final QuickStatType type;

  const QuickStat({
    required this.label,
    required this.count,
    required this.type,
  });
}

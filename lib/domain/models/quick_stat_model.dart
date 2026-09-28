enum QuickStatType {
  members,
  children,
  prayers,
}

class QuickStatModel {
  final String label;
  final int count;
  final QuickStatType type;

  const QuickStatModel({
    required this.label,
    required this.count,
    required this.type,
  });
}

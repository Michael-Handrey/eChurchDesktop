enum ActivityType {
  member,
  child,
  prayer,
}

class RecentActivityModel {
  final String id;
  final String title;
  final ActivityType type;
  final String timeAgo;

  const RecentActivityModel({
    required this.id,
    required this.title,
    required this.type,
    required this.timeAgo,
  });

  String get typeLabel {
    switch (type) {
      case ActivityType.member:
        return 'Membro';
      case ActivityType.child:
        return 'Criança';
      case ActivityType.prayer:
        return 'Oração';
    }
  }
}

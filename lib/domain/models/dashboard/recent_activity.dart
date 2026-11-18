enum ActivityType {
  member,
  child,
  prayer,
}

class RecentActivity {
  final String id;
  final String title;
  final ActivityType type;
  final String timeAgo;

  const RecentActivity({
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

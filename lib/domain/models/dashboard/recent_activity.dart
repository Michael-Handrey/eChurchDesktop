import 'package:equatable/equatable.dart';

enum ActivityType {
  member,
  child,
  prayer,
}

/// Último registro da igreja (membro cadastrado ou pedido de oração), com quando foi.
class const RecentActivity({required final int id, required final String title, required final ActivityType type, required final DateTime at}) extends Equatable {
  String get typeLabel => switch (type) {
    ActivityType.member => 'Membro',
    ActivityType.child => 'Criança',
    ActivityType.prayer => 'Oração',
  };

  /// "Agora", "Há 5 minutos", "Há 2 horas", "Ontem", "Há 3 dias" ou a data (mais de uma semana).
  static String timeAgo(DateTime at, DateTime now) {
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return diff.inMinutes == 1 ? 'Há 1 minuto' : 'Há ${diff.inMinutes} minutos';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final days = today.difference(day).inDays;
    if (days == 0) return diff.inHours == 1 ? 'Há 1 hora' : 'Há ${diff.inHours} horas';
    if (days == 1) return 'Ontem';
    if (days < 7) return 'Há $days dias';
    return '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}';
  }

  @override
  List<Object?> get props => [id, title, type, at];
}

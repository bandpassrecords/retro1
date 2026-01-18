import 'package:hive/hive.dart';

part 'daily_entry.g.dart';

@HiveType(typeId: 0)
class DailyEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String mediaType; // 'video' or 'photo'

  @HiveField(3)
  String originalPath;

  @HiveField(4)
  int startTimeMs; // Tempo de início no vídeo original (em ms)

  @HiveField(5)
  int durationMs; // Duração do clipe (sempre 1000ms para 1 segundo)

  @HiveField(6)
  String? caption;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String timezone;

  @HiveField(9)
  String? thumbnailPath; // Caminho para thumbnail

  @HiveField(10)
  bool hasAudio; // Se o vídeo tem áudio

  DailyEntry({
    required this.id,
    required this.date,
    required this.mediaType,
    required this.originalPath,
    required this.startTimeMs,
    this.durationMs = 1000,
    this.caption,
    required this.createdAt,
    required this.timezone,
    this.thumbnailPath,
    this.hasAudio = true,
  });

  // Método para obter apenas a data (sem hora)
  DateTime get dateOnly {
    return DateTime(date.year, date.month, date.day);
  }

  // Verificar se é do dia de hoje
  bool get isToday {
    final now = DateTime.now();
    return dateOnly.year == now.year &&
        dateOnly.month == now.month &&
        dateOnly.day == now.day;
  }

  // Verificar se é de um dia específico
  bool isOnDate(DateTime date) {
    return dateOnly.year == date.year &&
        dateOnly.month == date.month &&
        dateOnly.day == date.day;
  }
}

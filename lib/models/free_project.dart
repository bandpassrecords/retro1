import 'package:hive/hive.dart';

part 'free_project.g.dart';

@HiveType(typeId: 2)
class FreeProject extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  List<String> mediaItemIds; // IDs dos ProjectMediaItem

  @HiveField(6)
  String? thumbnailPath;

  @HiveField(7)
  String? coverImagePath;

  FreeProject({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    List<String>? mediaItemIds,
    this.thumbnailPath,
    this.coverImagePath,
  }) : mediaItemIds = mediaItemIds ?? [];

  // Obter duração total do projeto (em segundos)
  int get totalDurationSeconds {
    return mediaItemIds.length; // Cada item é 1 segundo
  }
}

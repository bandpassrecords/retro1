import 'package:hive/hive.dart';

part 'rendered_video.g.dart';

@HiveType(typeId: 4)
class RenderedVideo extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String videoPath; // Caminho do vídeo renderizado

  @HiveField(2)
  String title; // Título do vídeo (ex: "Janeiro 2024", "2024", "01-01-2024_-_31-01-2024")

  @HiveField(3)
  String type; // 'calendar' ou 'project'

  @HiveField(4)
  DateTime createdAt; // Quando foi gerado

  @HiveField(5)
  String? thumbnailPath; // Thumbnail do vídeo

  @HiveField(6)
  int durationSeconds; // Duração em segundos

  @HiveField(7)
  String? projectId; // ID do projeto (se type == 'project'), null se for calendário

  @HiveField(8)
  Map<String, dynamic>? metadata; // Metadados adicionais (ano, mês, datas, etc.)

  RenderedVideo({
    required this.id,
    required this.videoPath,
    required this.title,
    required this.type,
    required this.createdAt,
    this.thumbnailPath,
    required this.durationSeconds,
    this.projectId,
    this.metadata,
  });
}

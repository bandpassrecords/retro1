import 'package:hive/hive.dart';

part 'project_media_item.g.dart';

@HiveType(typeId: 3)
class ProjectMediaItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String mediaType; // 'video' or 'photo'

  @HiveField(2)
  String originalPath;

  @HiveField(3)
  String? editedPath; // Caminho do arquivo editado

  @HiveField(4)
  int startTimeMs; // Para vídeos: tempo de início (em ms)

  @HiveField(5)
  int durationMs; // Duração (em ms, padrão 1000ms = 1 segundo)

  @HiveField(6)
  int order; // Ordem no projeto

  @HiveField(7)
  String? caption;

  @HiveField(8)
  DateTime createdAt;

  // Edições de foto
  @HiveField(9)
  int rotation; // Rotação em graus (0, 90, 180, 270)

  @HiveField(10)
  String? animationType; // 'none', 'zoom', 'pan', 'fade', 'ken_burns'

  @HiveField(11)
  Map<String, dynamic>? animationParams; // Parâmetros da animação

  // Edições de vídeo
  @HiveField(12)
  double? playbackSpeed; // Velocidade de reprodução (0.5x, 1.0x, 2.0x, etc.)

  @HiveField(13)
  bool? muteAudio; // Se deve mutar o áudio

  @HiveField(14)
  String? filter; // Filtro aplicado ('none', 'vintage', 'blackwhite', etc.)

  @HiveField(15)
  double? brightness; // Brilho (-1.0 a 1.0)

  @HiveField(16)
  double? contrast; // Contraste (-1.0 a 1.0)

  @HiveField(17)
  double? saturation; // Saturação (-1.0 a 1.0)

  @HiveField(18)
  String? thumbnailPath;

  ProjectMediaItem({
    required this.id,
    required this.mediaType,
    required this.originalPath,
    this.editedPath,
    this.startTimeMs = 0,
    this.durationMs = 1000,
    required this.order,
    this.caption,
    required this.createdAt,
    this.rotation = 0,
    this.animationType = 'none',
    this.animationParams,
    this.playbackSpeed = 1.0,
    this.muteAudio = false,
    this.filter = 'none',
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.thumbnailPath,
  });

  // Verificar se tem edições aplicadas
  bool get hasEdits {
    return rotation != 0 ||
        (animationType != null && animationType != 'none') ||
        (playbackSpeed != null && playbackSpeed != 1.0) ||
        (muteAudio == true) ||
        (filter != null && filter != 'none') ||
        (brightness != null && brightness != 0.0) ||
        (contrast != null && contrast != 0.0) ||
        (saturation != null && saturation != 0.0) ||
        editedPath != null;
  }
}

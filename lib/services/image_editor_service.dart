import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class ImageEditorService {
  static const _uuid = Uuid();

  // Obter dimensões da imagem
  static Future<Map<String, int>?> getImageDimensions(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return null;
      }

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      print('[ImageEditor] Error getting image dimensions: $e');
      return null;
    }
  }

  // Rotacionar imagem
  static Future<String?> rotateImage({
    required String inputPath,
    required int degrees, // 90, 180, 270
    String? outputPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'edited_images'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final fileName = outputPath ?? 'rotated_${_uuid.v4()}.jpg';
      final finalOutputPath = path.join(outputDir.path, fileName);

      // Ler imagem
      final imageBytes = await File(inputPath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('[ImageEditor] Failed to decode image');
        return null;
      }

      // Rotacionar
      img.Image rotated;
      switch (degrees) {
        case 90:
          rotated = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotated = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotated = img.copyRotate(image, angle: 270);
          break;
        default:
          rotated = image;
      }

      // Salvar
      final rotatedBytes = img.encodeJpg(rotated, quality: 95);
      await File(finalOutputPath).writeAsBytes(rotatedBytes);

      print('[ImageEditor] Image rotated $degrees degrees: $finalOutputPath');
      return finalOutputPath;
    } catch (e) {
      print('[ImageEditor] Error rotating image: $e');
      return null;
    }
  }

  // Aplicar filtros de imagem
  static Future<String?> applyFilter({
    required String inputPath,
    required String filterType, // 'vintage', 'blackwhite', 'sepia', 'bright', 'warm', 'cool'
    String? outputPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'edited_images'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final fileName = outputPath ?? 'filtered_${_uuid.v4()}.jpg';
      final finalOutputPath = path.join(outputDir.path, fileName);

      // Ler imagem
      final imageBytes = await File(inputPath).readAsBytes();
      var image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('[ImageEditor] Failed to decode image');
        return null;
      }

      // Aplicar filtro
      switch (filterType) {
        case 'vintage':
          image = img.sepia(image);
          image = img.adjustColor(image, contrast: 0.8, saturation: 0.7);
          break;
        case 'blackwhite':
          image = img.grayscale(image);
          break;
        case 'sepia':
          image = img.sepia(image);
          break;
        case 'bright':
          image = img.adjustColor(image, brightness: 0.2, contrast: 1.1);
          break;
        case 'warm':
          // Warm filter: aumentar saturação e contraste para efeito quente
          image = img.adjustColor(image, saturation: 1.3, contrast: 1.1, brightness: 0.05);
          break;
        case 'cool':
          // Cool filter: aumentar saturação azulada, diminuir brilho
          image = img.adjustColor(image, saturation: 1.2, brightness: -0.05, contrast: 1.05);
          break;
        default:
          // Sem filtro
          break;
      }

      // Salvar
      final filteredBytes = img.encodeJpg(image, quality: 95);
      await File(finalOutputPath).writeAsBytes(filteredBytes);

      print('[ImageEditor] Filter $filterType applied: $finalOutputPath');
      return finalOutputPath;
    } catch (e) {
      print('[ImageEditor] Error applying filter: $e');
      return null;
    }
  }

  // Ajustar brilho, contraste e saturação
  static Future<String?> adjustImage({
    required String inputPath,
    double brightness = 0.0, // -1.0 a 1.0
    double contrast = 0.0,   // -1.0 a 1.0
    double saturation = 0.0, // -1.0 a 1.0
    String? outputPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'edited_images'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final fileName = outputPath ?? 'adjusted_${_uuid.v4()}.jpg';
      final finalOutputPath = path.join(outputDir.path, fileName);

      // Ler imagem
      final imageBytes = await File(inputPath).readAsBytes();
      var image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('[ImageEditor] Failed to decode image');
        return null;
      }

      // Ajustar
      image = img.adjustColor(
        image,
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
      );

      // Salvar
      final adjustedBytes = img.encodeJpg(image, quality: 95);
      await File(finalOutputPath).writeAsBytes(adjustedBytes);

      print('[ImageEditor] Image adjusted: brightness=$brightness, contrast=$contrast, saturation=$saturation');
      return finalOutputPath;
    } catch (e) {
      print('[ImageEditor] Error adjusting image: $e');
      return null;
    }
  }

  // Converter foto para vídeo com animação
  static Future<String?> convertPhotoToVideoWithAnimation({
    required String inputPath,
    required String animationType, // 'none', 'zoom', 'pan', 'fade', 'ken_burns'
    Map<String, dynamic>? animationParams,
    int durationSeconds = 1,
    int fps = 30,
    String? outputPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'animated_videos'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final fileName = outputPath ?? 'animated_${_uuid.v4()}.mp4';
      final finalOutputPath = path.join(outputDir.path, fileName);

      // Construir comando FFmpeg baseado no tipo de animação
      String filter = '';
      
      switch (animationType) {
        case 'zoom':
          final zoomStart = animationParams?['zoomStart'] ?? 1.0;
          final zoomEnd = animationParams?['zoomEnd'] ?? 1.2;
          filter = 'scale=iw*${zoomEnd}:ih*${zoomEnd},zoompan=z=\'if(lte(zoom,${zoomStart}),${zoomStart}+(on/${fps * durationSeconds})*($zoomEnd-${zoomStart}),${zoomEnd})\':d=${fps * durationSeconds}:x=iw/2-(iw/zoom/2):y=ih/2-(ih/zoom/2):s=1920x1080';
          break;
        case 'pan':
          final panX = animationParams?['panX'] ?? 0.1;
          filter = 'crop=iw*0.9:ih:iw*${panX}*t/${durationSeconds}:0,scale=1920:1080';
          break;
        case 'ken_burns':
          // Ken Burns effect: zoom + pan
          filter = 'scale=iw*1.2:ih*1.2,crop=iw*0.9:ih*0.9:iw*0.1*on/${fps * durationSeconds}:ih*0.05*on/${fps * durationSeconds},scale=1920:1080';
          break;
        case 'fade':
          // Fade in/out
          filter = 'fade=t=in:st=0:d=0.3,fade=t=out:st=${durationSeconds - 0.3}:d=0.3,scale=1920:1080';
          break;
        default:
          filter = 'scale=1920:1080';
      }

      // Comando FFmpeg
      final command = '-loop 1 -i "$inputPath" '
          '-vf "$filter" '
          '-t $durationSeconds '
          '-r $fps '
          '-pix_fmt yuv420p '
          '-y "$finalOutputPath"';

      print('[ImageEditor] Converting photo to video with animation: $animationType');
      print('[ImageEditor] FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('[ImageEditor] Photo converted to video with animation: $finalOutputPath');
        return finalOutputPath;
      } else {
        final logs = await session.getLogs();
        print('[ImageEditor] FFmpeg error: ${logs.map((l) => l.getMessage()).join('\n')}');
        return null;
      }
    } catch (e) {
      print('[ImageEditor] Error converting photo to video: $e');
      return null;
    }
  }
}

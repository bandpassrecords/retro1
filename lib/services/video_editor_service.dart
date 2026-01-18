import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class VideoEditorService {
  static const _uuid = Uuid();

  // Obter duração do vídeo
  static Future<Duration?> getVideoDuration(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      return null;
    }
  }

  // Extrair 1 segundo do vídeo
  static Future<String?> extractOneSecond({
    required String inputPath,
    required int startTimeMs,
    String? outputPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'clips'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final fileName = outputPath ?? '${_uuid.v4()}.mp4';
      final finalOutputPath = path.join(outputDir.path, fileName);

      // Converter startTimeMs para formato HH:MM:SS.mmm
      final seconds = startTimeMs ~/ 1000;
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      final ms = startTimeMs % 1000;
      final startTime = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}.'
          '${ms.toString().padLeft(3, '0')}';

      // Comando FFmpeg para extrair 1 segundo
      final command = '-i "$inputPath" '
          '-ss $startTime '
          '-t 00:00:01.000 '
          '-c:v libx264 '
          '-c:a aac '
          '-preset fast '
          '-y '
          '"$finalOutputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return finalOutputPath;
      } else {
        final logs = await session.getLogs();
        print('FFmpeg error: ${logs.map((e) => e.getMessage()).join('\n')}');
        return null;
      }
    } catch (e) {
      print('Error extracting video: $e');
      return null;
    }
  }

  // Converter foto para vídeo de 1 segundo
  static Future<String?> convertPhotoToVideo({
    required String photoPath,
    String? outputPath,
  }) async {
    print('[VideoEditor] Converting photo to video: $photoPath');
    try {
      // Verificar se o arquivo da foto existe
      final photoFile = File(photoPath);
      if (!await photoFile.exists()) {
        print('[VideoEditor] ERROR: Photo file does not exist: $photoPath');
        return null;
      }
      
      // Verificar se é realmente uma imagem (não um vídeo)
      final fileExtension = path.extension(photoPath).toLowerCase();
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp'];
      if (!imageExtensions.contains(fileExtension)) {
        print('[VideoEditor] WARNING: File extension "$fileExtension" may not be an image. Expected: $imageExtensions');
        print('[VideoEditor] Proceeding anyway...');
      }
      
      print('[VideoEditor] Photo file exists, size: ${await photoFile.length()} bytes, extension: $fileExtension');

      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'clips'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        print('[VideoEditor] Created clips directory');
      }

      final fileName = outputPath ?? '${_uuid.v4()}.mp4';
      final finalOutputPath = path.join(outputDir.path, fileName);
      print('[VideoEditor] Output video path: $finalOutputPath');

      // Converter caminhos para formato Unix (FFmpeg no Android usa /)
      final photoPathUnix = photoPath.replaceAll('\\', '/');
      final outputPathUnix = finalOutputPath.replaceAll('\\', '/');

      // Comando FFmpeg para converter foto em vídeo de exatamente 1 segundo
      // Usar -loop 1 (opção de input) para fazer loop da imagem infinitamente
      // -framerate 30 no input para ler a imagem como 30 fps
      // -t 1.0 garante duração de exatamente 1 segundo
      // -r 30 no output para garantir 30 fps
      // Esta é a abordagem mais confiável e compatível
      var command = '-loop 1 '
          '-framerate 30 '
          '-i "$photoPathUnix" '
          '-vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" '
          '-t 1.0 '
          '-r 30 '
          '-c:v libx264 '
          '-pix_fmt yuv420p '
          '-preset fast '
          '-fps_mode cfr '
          '-y '
          '"$outputPathUnix"';

      print('[VideoEditor] FFmpeg command: $command');
      print('[VideoEditor] Executing FFmpeg...');
      
      var session = await FFmpegKit.execute(command);
      var returnCode = await session.getReturnCode();
      print('[VideoEditor] FFmpeg return code: $returnCode');

      // Se falhar, tentar abordagem alternativa usando filtro loop no video filter
      if (!ReturnCode.isSuccess(returnCode)) {
        print('[VideoEditor] First attempt failed, trying alternative approach with loop filter...');
        command = '-i "$photoPathUnix" '
            '-vf "loop=loop=-1:size=1:start=0,fps=30,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" '
            '-t 1.0 '
            '-c:v libx264 '
            '-pix_fmt yuv420p '
            '-preset fast '
            '-fps_mode cfr '
            '-y '
            '"$outputPathUnix"';
        
        print('[VideoEditor] Alternative FFmpeg command: $command');
        session = await FFmpegKit.execute(command);
        returnCode = await session.getReturnCode();
        print('[VideoEditor] Alternative FFmpeg return code: $returnCode');
      }
      
      // Se ainda falhar, tentar abordagem mais simples sem filtros complexos
      if (!ReturnCode.isSuccess(returnCode)) {
        print('[VideoEditor] Second attempt failed, trying simple approach...');
        command = '-framerate 1 '
            '-i "$photoPathUnix" '
            '-vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" '
            '-r 30 '
            '-t 1.0 '
            '-c:v libx264 '
            '-pix_fmt yuv420p '
            '-preset fast '
            '-fps_mode cfr '
            '-y '
            '"$outputPathUnix"';
        
        print('[VideoEditor] Simple FFmpeg command: $command');
        session = await FFmpegKit.execute(command);
        returnCode = await session.getReturnCode();
        print('[VideoEditor] Simple FFmpeg return code: $returnCode');
      }

      if (ReturnCode.isSuccess(returnCode)) {
        // Verificar se o arquivo foi criado
        final outputFile = File(finalOutputPath);
        if (await outputFile.exists()) {
          final fileSize = await outputFile.length();
          
          // Verificar duração do vídeo gerado
          try {
            final duration = await getVideoDuration(finalOutputPath);
            if (duration != null) {
              print('[VideoEditor] SUCCESS: Video created at $finalOutputPath');
              print('[VideoEditor] Video file size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
              print('[VideoEditor] Video duration: ${duration.inMilliseconds}ms (expected: 1000ms)');
              
              // Se a duração estiver muito diferente de 1 segundo, avisar
              final durationDiff = (duration.inMilliseconds - 1000).abs();
              if (durationDiff > 100) {
                print('[VideoEditor] WARNING: Video duration is ${duration.inMilliseconds}ms, expected 1000ms (difference: ${durationDiff}ms)');
              } else {
                print('[VideoEditor] Video duration is correct (within 100ms tolerance)');
              }
            } else {
              print('[VideoEditor] SUCCESS: Video created but could not verify duration');
            }
          } catch (e) {
            print('[VideoEditor] SUCCESS: Video created but could not verify duration: $e');
          }
          
          return finalOutputPath;
        } else {
          print('[VideoEditor] ERROR: Return code was success but file does not exist');
          return null;
        }
      } else {
        final logs = await session.getLogs();
        final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
        print('[VideoEditor] FFmpeg ERROR - Return code: $returnCode');
        print('[VideoEditor] FFmpeg error logs:');
        for (var log in errorMessages) {
          print('[VideoEditor]   $log');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('[VideoEditor] EXCEPTION converting photo to video: $e');
      print('[VideoEditor] Stack trace: $stackTrace');
      return null;
    }
  }

  // Gerar thumbnail do vídeo
  static Future<String?> generateThumbnail({
    required String videoPath,
    String? outputPath,
    int timeMs = 0,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailsDir = Directory(path.join(appDir.path, 'thumbnails'));
      
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final fileName = outputPath ?? '${_uuid.v4()}.jpg';
      final finalOutputPath = path.join(thumbnailsDir.path, fileName);

      // Converter timeMs para formato HH:MM:SS.mmm
      final seconds = timeMs ~/ 1000;
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      final ms = timeMs % 1000;
      final time = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}.'
          '${ms.toString().padLeft(3, '0')}';

      // Comando FFmpeg para gerar thumbnail
      final command = '-i "$videoPath" '
          '-ss $time '
          '-vframes 1 '
          '-vf "scale=320:-1" '
          '-q:v 2 '
          '-y '
          '"$finalOutputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return finalOutputPath;
      } else {
        return null;
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }
}

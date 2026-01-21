import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/daily_entry.dart';
import '../models/project_media_item.dart';
import '../services/hive_service.dart';
import 'video_editor_service.dart';

class VideoGeneratorService {
  static const _uuid = Uuid();

  // Gerar vídeo compilado de um mês
  static Future<String?> generateMonthVideo({
    required int year,
    required int month,
    String quality = '1080p',
    bool showDateOverlay = true,
    String? externalAudioPath,
    String? locale,
  }) async {
    final entries = HiveService.getEntriesByMonth(year, month);
    if (entries.isEmpty) {
      return null;
    }

    // Usar locale fornecido ou padrão 'en'
    final localeToUse = locale ?? 'en';
    return await _generateCompiledVideo(
      entries: entries,
      title: '${DateFormat('MMMM yyyy', localeToUse).format(DateTime(year, month, 1))}',
      quality: quality,
      showDateOverlay: showDateOverlay,
      externalAudioPath: externalAudioPath,
    );
  }

  // Gerar vídeo compilado de um ano
  static Future<String?> generateYearVideo({
    required int year,
    String quality = '1080p',
    bool showDateOverlay = true,
    String? externalAudioPath,
  }) async {
    final entries = HiveService.getEntriesByYear(year);
    if (entries.isEmpty) {
      return null;
    }

    return await _generateCompiledVideo(
      entries: entries,
      title: year.toString(),
      quality: quality,
      showDateOverlay: showDateOverlay,
      externalAudioPath: externalAudioPath,
    );
  }

  // Gerar vídeo compilado de um intervalo customizado
  static Future<String?> generateCustomVideo({
    required DateTime startDate,
    required DateTime endDate,
    String quality = '1080p',
    bool showDateOverlay = true,
    String? externalAudioPath,
    String? locale,
  }) async {
    final entries = HiveService.getEntriesByDateRange(startDate, endDate);
    if (entries.isEmpty) {
      return null;
    }

    // Usar formato de data sem barras para evitar problemas no nome do arquivo
    // Usar locale fornecido ou padrão 'en'
    final localeToUse = locale ?? 'en';
    final dateFormat = DateFormat('dd-MM-yyyy', localeToUse);
    final title = '${dateFormat.format(startDate)}_-_${dateFormat.format(endDate)}';

    return await _generateCompiledVideo(
      entries: entries,
      title: title,
      quality: quality,
      showDateOverlay: showDateOverlay,
      externalAudioPath: externalAudioPath,
    );
  }

  // Função principal para gerar vídeo compilado
  static Future<String?> _generateCompiledVideo({
    required List<DailyEntry> entries,
    required String title,
    String quality = '1080p',
    bool showDateOverlay = true,
    String? externalAudioPath,
  }) async {
    print('[VideoGenerator] Starting video generation for: $title');
    print('[VideoGenerator] Entries count: ${entries.length}');
    print('[VideoGenerator] Quality: $quality, ShowDateOverlay: $showDateOverlay');
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'exports'));
      
      print('[VideoGenerator] App directory: ${appDir.path}');
      print('[VideoGenerator] Output directory: ${outputDir.path}');
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        print('[VideoGenerator] Created output directory');
      }

      // Limpar título para nome de arquivo seguro (remover caracteres problemáticos)
      final safeTitle = title
          .replaceAll(' ', '_')
          .replaceAll('/', '-')
          .replaceAll('\\', '-')
          .replaceAll(':', '-')
          .replaceAll('|', '-')
          .replaceAll('*', '-')
          .replaceAll('?', '-')
          .replaceAll('"', '-')
          .replaceAll('<', '-')
          .replaceAll('>', '-');
      
      final fileName = '${safeTitle}_${_uuid.v4()}.mp4';
      final finalOutputPath = path.join(outputDir.path, fileName);
      print('[VideoGenerator] Output file: $finalOutputPath');

      // Criar arquivo de lista para concatenação
      print('[VideoGenerator] Creating concat file...');
      final concatFile = await _createConcatFile(entries);
      if (concatFile == null) {
        print('[VideoGenerator] ERROR: Failed to create concat file');
        return null;
      }
      print('[VideoGenerator] Concat file created: $concatFile');

      // Resolução baseada na qualidade (separar largura e altura)
      int width = 1920;
      int height = 1080;
      String videoBitrate = '5000k';
      
      switch (quality) {
        case '720p':
          width = 1280;
          height = 720;
          videoBitrate = '3000k';
          break;
        case '1080p':
          width = 1920;
          height = 1080;
          videoBitrate = '5000k';
          break;
        case '4K':
          width = 3840;
          height = 2160;
          videoBitrate = '20000k';
          break;
      }

      // Construir comando FFmpeg usando melhores práticas do Mux
      // Converter caminhos para formato Unix (FFmpeg no Android usa /)
      final concatPathUnix = concatFile.replaceAll('\\', '/');
      final outputPathUnix = finalOutputPath.replaceAll('\\', '/');
      
      String command;
      ReturnCode? returnCode;
      Session? session;
      
      if (externalAudioPath != null && externalAudioPath.isNotEmpty) {
        // Se há áudio externo, remover áudio original e usar o externo
        final audioPathUnix = externalAudioPath.replaceAll('\\', '/');
        print('[VideoGenerator] Using external audio: $audioPathUnix');
        
        // Primeiro, gerar vídeo sem áudio usando filter complex para normalização
        final tempVideoPath = path.join(
          (await getApplicationDocumentsDirectory()).path,
          'temp',
          'temp_video_${_uuid.v4()}.mp4'
        );
        final tempVideoPathUnix = tempVideoPath.replaceAll('\\', '/');
        
        // Criar diretório temp se não existir
        final tempDir = Directory(path.dirname(tempVideoPath));
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        
        // Usar concat demuxer com normalização via -vf (método recomendado pelo Mux)
        // Adicionar setsar=1 para garantir aspect ratio correto
        final videoCommand = '-f concat -safe 0 -i "$concatPathUnix" '
            '-c:v libx264 '
            '-preset medium '
            '-crf 23 '
            '-vf "scale=$width:$height:force_original_aspect_ratio=decrease,'
            'pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1" '
            '-b:v $videoBitrate '
            '-r 30 '
            '-vsync cfr ' // Constant frame rate
            '-pix_fmt yuv420p '
            '-an ' // Sem áudio
            '-y '
            '"$tempVideoPathUnix"';
        
        print('[VideoGenerator] Step 1: Generating video without audio using concat demuxer with normalization...');
        print('[VideoGenerator] FFmpeg command (step 1): $videoCommand');
        
        session = await FFmpegKit.execute(videoCommand);
        returnCode = await session.getReturnCode();
        
        if (!ReturnCode.isSuccess(returnCode)) {
          final logs = await session.getLogs();
          final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
          print('[VideoGenerator] ERROR in step 1 - Return code: $returnCode');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
          return null;
        }
        
        // Segundo, combinar vídeo sem áudio com áudio externo
        command = '-i "$tempVideoPathUnix" '
            '-i "$audioPathUnix" '
            '-c:v copy ' // Copiar vídeo sem re-encodar
            '-c:a aac '
            '-b:a 192k '
            '-shortest ' // Terminar quando o vídeo terminar
            '-map 0:v:0 ' // Usar vídeo do primeiro input
            '-map 1:a:0 ' // Usar áudio do segundo input
            '-y '
            '"$outputPathUnix"';
        
        print('[VideoGenerator] Step 2: Combining video with external audio...');
        print('[VideoGenerator] FFmpeg command (step 2): $command');
        
        // Limpar arquivo temporário após uso
        session = await FFmpegKit.execute(command);
        returnCode = await session.getReturnCode();
        
        // Tentar deletar arquivo temporário (mesmo se falhar, continuar)
        try {
          await File(tempVideoPath).delete();
          print('[VideoGenerator] Temporary video file deleted');
        } catch (e) {
          print('[VideoGenerator] Warning: Could not delete temp file: $e');
        }
      } else {
        // Comando normal com áudio original usando concat demuxer com normalização
        // Adicionar setsar=1 para garantir aspect ratio correto (recomendado pelo Mux)
        command = '-f concat -safe 0 -i "$concatPathUnix" '
            '-c:v libx264 '
            '-preset medium '
            '-crf 23 '
            '-vf "scale=$width:$height:force_original_aspect_ratio=decrease,'
            'pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1" '
            '-b:v $videoBitrate '
            '-c:a aac '
            '-b:a 192k '
            '-r 30 '
            '-vsync cfr ' // Constant frame rate (recomendado pelo Mux)
            '-pix_fmt yuv420p '
            '-y '
            '"$outputPathUnix"';
        
        print('[VideoGenerator] FFmpeg command (using concat demuxer with normalization): $command');
      }
      
      print('[VideoGenerator] Resolution: ${width}x${height}, Bitrate: $videoBitrate');

      // Se mostrar overlay de data, adicionar filtro
      if (showDateOverlay) {
        // Nota: Overlay de data seria mais complexo, 
        // por enquanto geramos sem overlay
        // Pode ser implementado depois com filtros de texto do FFmpeg
        print('[VideoGenerator] Date overlay requested but not implemented yet');
      }

      // Se já executamos o comando em duas etapas (com áudio externo), não executar novamente
      ReturnCode? finalReturnCode;
      
      if (externalAudioPath == null || externalAudioPath.isEmpty) {
        print('[VideoGenerator] Executing FFmpeg...');
        final session = await FFmpegKit.execute(command);
        finalReturnCode = await session.getReturnCode();
        print('[VideoGenerator] FFmpeg return code: $finalReturnCode');
        
        // Verificar resultado
        if (!ReturnCode.isSuccess(finalReturnCode)) {
          final logs = await session.getLogs();
          final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
          print('[VideoGenerator] FFmpeg ERROR - Return code: $finalReturnCode');
          print('[VideoGenerator] FFmpeg error logs:');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
          
          // Limpar arquivo de concatenação
          try {
            await File(concatFile).delete();
            print('[VideoGenerator] Concat file deleted');
          } catch (e) {
            print('[VideoGenerator] Warning: Could not delete concat file: $e');
          }
          
          return null;
        }
      } else {
        // returnCode já foi obtido na etapa anterior, verificar resultado
        finalReturnCode = returnCode;
        if (!ReturnCode.isSuccess(finalReturnCode!)) {
          final logs = await session!.getLogs();
          final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
          print('[VideoGenerator] FFmpeg ERROR (step 2) - Return code: $finalReturnCode');
          print('[VideoGenerator] FFmpeg error logs:');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
          
          // Limpar arquivo de concatenação
          try {
            await File(concatFile).delete();
            print('[VideoGenerator] Concat file deleted');
          } catch (e) {
            print('[VideoGenerator] Warning: Could not delete concat file: $e');
          }
          
          return null;
        }
      }

      // Limpar arquivo de concatenação
      try {
        await File(concatFile).delete();
        print('[VideoGenerator] Concat file deleted');
      } catch (e) {
        print('[VideoGenerator] Warning: Could not delete concat file: $e');
      }

      // Usar finalReturnCode se foi definido, senão usar returnCode
      final checkReturnCode = finalReturnCode ?? returnCode!;
      
      if (ReturnCode.isSuccess(checkReturnCode)) {
        // Verificar se o arquivo foi criado
        final outputFile = File(finalOutputPath);
        if (await outputFile.exists()) {
          final fileSize = await outputFile.length();
          print('[VideoGenerator] SUCCESS: Video generated at $finalOutputPath');
          print('[VideoGenerator] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
          return finalOutputPath;
        } else {
          print('[VideoGenerator] ERROR: Return code was success but file does not exist');
          return null;
        }
      } else {
        if (session != null) {
          final logs = await session.getLogs();
          final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
          print('[VideoGenerator] FFmpeg ERROR - Return code: $returnCode');
          print('[VideoGenerator] FFmpeg error logs:');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
        } else {
          print('[VideoGenerator] FFmpeg ERROR - Return code: $returnCode (no session available)');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('[VideoGenerator] EXCEPTION: $e');
      print('[VideoGenerator] Stack trace: $stackTrace');
      return null;
    }
  }

  // Criar arquivo de concatenação para FFmpeg
  static Future<String?> _createConcatFile(List<DailyEntry> entries) async {
    print('[VideoGenerator] Creating concat file for ${entries.length} entries');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory(path.join(appDir.path, 'temp'));
      
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
        print('[VideoGenerator] Created temp directory');
      }

      final concatFile = File(path.join(tempDir.path, 'concat_${_uuid.v4()}.txt'));
      final buffer = StringBuffer();
      int validEntries = 0;
      int invalidEntries = 0;

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        print('[VideoGenerator] Processing entry $i/${entries.length}: ${entry.id} (${entry.mediaType})');
        
        // Verificar se o arquivo existe
        String clipPath = entry.originalPath;
        final file = File(clipPath);
        
        if (!await file.exists()) {
          print('[VideoGenerator] WARNING: Entry ${entry.id} - File does not exist: $clipPath');
          invalidEntries++;
          continue;
        }
        
        // Se for foto, precisamos converter para vídeo primeiro
        if (entry.mediaType == 'photo') {
          print('[VideoGenerator] Entry ${entry.id} is a photo, converting to video...');
          // Usar thumbnailPath se disponível (foto original), senão usar originalPath
          final photoPath = entry.thumbnailPath ?? entry.originalPath;
          print('[VideoGenerator] Using photo path: $photoPath');
          
          // Verificar se o arquivo existe e é realmente uma imagem
          final photoFile = File(photoPath);
          if (!await photoFile.exists()) {
            print('[VideoGenerator] ERROR: Photo file does not exist: $photoPath');
            invalidEntries++;
            continue;
          }
          
          // Verificar extensão
          final fileExtension = path.extension(photoPath).toLowerCase();
          final imageExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp'];
          if (!imageExtensions.contains(fileExtension)) {
            print('[VideoGenerator] WARNING: File extension "$fileExtension" is not an image. Skipping conversion.');
            invalidEntries++;
            continue;
          }
          
          // Converter foto para vídeo de 1 segundo usando VideoEditorService
          final videoPath = await VideoEditorService.convertPhotoToVideo(photoPath: photoPath);
          if (videoPath == null) {
            print('[VideoGenerator] ERROR: Failed to convert photo to video for entry ${entry.id}');
            invalidEntries++;
            continue;
          }
          clipPath = videoPath;
          print('[VideoGenerator] Photo converted to video: $clipPath');
        }

        // Escapar barras invertidas e aspas no caminho para FFmpeg
        // FFmpeg no Android espera caminhos Unix-style
        final escapedPath = clipPath.replaceAll('\\', '/').replaceAll("'", "\\'");
        print('[VideoGenerator] Adding to concat: $escapedPath');
        buffer.writeln("file '$escapedPath'");
        validEntries++;
        print('[VideoGenerator] Added entry $i to concat file: $escapedPath');
      }

      if (validEntries == 0) {
        print('[VideoGenerator] ERROR: No valid entries found for concat file');
        return null;
      }

      print('[VideoGenerator] Concat file summary: $validEntries valid, $invalidEntries invalid');
      await concatFile.writeAsString(buffer.toString());
      
      // Log do conteúdo do arquivo concat (primeiras linhas)
      final content = await concatFile.readAsString();
      final lines = content.split('\n').take(5).toList();
      print('[VideoGenerator] Concat file content (first 5 lines):');
      for (var line in lines) {
        print('[VideoGenerator]   $line');
      }
      
      return concatFile.path;
    } catch (e, stackTrace) {
      print('[VideoGenerator] ERROR creating concat file: $e');
      print('[VideoGenerator] Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Obter diretório de exportação
  static Future<Directory> getExportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(path.join(appDir.path, 'exports'));
    
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    return outputDir;
  }

  // Gerar vídeo de um projeto livre
  static Future<String?> generateProjectVideo({
    required List<ProjectMediaItem> mediaItems,
    required String projectName,
    String quality = '1080p',
    String? externalAudioPath,
  }) async {
    if (mediaItems.isEmpty) {
      return null;
    }

    print('[VideoGenerator] Starting project video generation for: $projectName');
    print('[VideoGenerator] Media items count: ${mediaItems.length}');

    return await _generateProjectCompiledVideo(
      mediaItems: mediaItems,
      title: projectName,
      quality: quality,
      externalAudioPath: externalAudioPath,
    );
  }

  // Função para gerar vídeo compilado de um projeto
  static Future<String?> _generateProjectCompiledVideo({
    required List<ProjectMediaItem> mediaItems,
    required String title,
    String quality = '1080p',
    String? externalAudioPath,
  }) async {
    print('[VideoGenerator] Starting project video generation for: $title');
    print('[VideoGenerator] Media items count: ${mediaItems.length}');
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(appDir.path, 'exports'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // Limpar título para nome de arquivo seguro (mesmo método do calendário)
      final safeTitle = title
          .replaceAll(' ', '_')
          .replaceAll('/', '-')
          .replaceAll('\\', '-')
          .replaceAll(':', '-')
          .replaceAll('|', '-')
          .replaceAll('*', '-')
          .replaceAll('?', '-')
          .replaceAll('"', '-')
          .replaceAll('<', '-')
          .replaceAll('>', '-');
      
      final fileName = 'project_${safeTitle}_${_uuid.v4()}.mp4';
      final finalOutputPath = path.join(outputDir.path, fileName);
      print('[VideoGenerator] Output file: $finalOutputPath');

      // Criar arquivo de lista para concatenação
      print('[VideoGenerator] Creating concat file...');
      final concatFile = await _createProjectConcatFile(mediaItems);
      if (concatFile == null) {
        print('[VideoGenerator] ERROR: Failed to create concat file');
        return null;
      }
      print('[VideoGenerator] Concat file created: $concatFile');

      // Resolução baseada na qualidade (separar largura e altura)
      // Usar os mesmos valores do método _generateCompiledVideo
      int width = 1920;
      int height = 1080;
      String videoBitrate = '5000k';
      
      switch (quality) {
        case '720p':
          width = 1280;
          height = 720;
          videoBitrate = '3000k'; // Mesmo valor do calendário
          break;
        case '1080p':
          width = 1920;
          height = 1080;
          videoBitrate = '5000k';
          break;
        case '4K':
          width = 3840;
          height = 2160;
          videoBitrate = '20000k';
          break;
      }

      final concatPathUnix = concatFile.replaceAll('\\', '/');
      final outputPathUnix = finalOutputPath.replaceAll('\\', '/');
      
      String command;
      ReturnCode? returnCode;
      Session? session;
      
      if (externalAudioPath != null && externalAudioPath.isNotEmpty) {
        // Se há áudio externo, remover áudio original e usar o externo
        final audioPathUnix = externalAudioPath.replaceAll('\\', '/');
        print('[VideoGenerator] Using external audio: $audioPathUnix');
        
        // Primeiro, gerar vídeo sem áudio usando filter complex para normalização
        final tempVideoPath = path.join(
          (await getApplicationDocumentsDirectory()).path,
          'temp',
          'temp_project_video_${_uuid.v4()}.mp4'
        );
        final tempVideoPathUnix = tempVideoPath.replaceAll('\\', '/');
        
        // Criar diretório temp se não existir
        final tempDir = Directory(path.dirname(tempVideoPath));
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        
        // Usar concat demuxer com normalização via -vf (método recomendado pelo Mux)
        // Adicionar setsar=1 para garantir aspect ratio correto
        final videoCommand = '-f concat -safe 0 -i "$concatPathUnix" '
            '-c:v libx264 '
            '-preset medium '
            '-crf 23 '
            '-vf "scale=$width:$height:force_original_aspect_ratio=decrease,'
            'pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1" '
            '-b:v $videoBitrate '
            '-r 30 '
            '-vsync cfr ' // Constant frame rate
            '-pix_fmt yuv420p '
            '-an ' // Sem áudio
            '-y '
            '"$tempVideoPathUnix"';
        
        print('[VideoGenerator] Step 1: Generating video without audio using concat demuxer with normalization...');
        print('[VideoGenerator] FFmpeg command (step 1): $videoCommand');
        
        session = await FFmpegKit.execute(videoCommand);
        returnCode = await session.getReturnCode();
        
        if (!ReturnCode.isSuccess(returnCode)) {
          final logs = await session.getLogs();
          final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
          print('[VideoGenerator] ERROR in step 1 - Return code: $returnCode');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
          return null;
        }
        
        // Segundo, combinar vídeo sem áudio com áudio externo
        command = '-i "$tempVideoPathUnix" '
            '-i "$audioPathUnix" '
            '-c:v copy ' // Copiar vídeo sem re-encodar
            '-c:a aac '
            '-b:a 192k '
            '-shortest ' // Terminar quando o vídeo terminar
            '-map 0:v:0 ' // Usar vídeo do primeiro input
            '-map 1:a:0 ' // Usar áudio do segundo input
            '-y '
            '"$outputPathUnix"';
        
        print('[VideoGenerator] Step 2: Combining video with external audio...');
        print('[VideoGenerator] FFmpeg command (step 2): $command');
        
        // Limpar arquivo temporário após uso
        session = await FFmpegKit.execute(command);
        returnCode = await session.getReturnCode();
        
        // Tentar deletar arquivo temporário (mesmo se falhar, continuar)
        try {
          await File(tempVideoPath).delete();
          print('[VideoGenerator] Temporary video file deleted');
        } catch (e) {
          print('[VideoGenerator] Warning: Could not delete temp file: $e');
        }
      } else {
        // Comando normal com áudio original usando concat demuxer com normalização
        // Adicionar setsar=1 para garantir aspect ratio correto (recomendado pelo Mux)
        command = '-f concat -safe 0 -i "$concatPathUnix" '
            '-c:v libx264 '
            '-preset medium '
            '-crf 23 '
            '-vf "scale=$width:$height:force_original_aspect_ratio=decrease,'
            'pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1" '
            '-b:v $videoBitrate '
            '-c:a aac '
            '-b:a 192k '
            '-r 30 '
            '-vsync cfr ' // Constant frame rate (recomendado pelo Mux)
            '-pix_fmt yuv420p '
            '-y '
            '"$outputPathUnix"';
        
        print('[VideoGenerator] FFmpeg command (using concat demuxer with normalization): $command');
      }
      
      print('[VideoGenerator] Resolution: ${width}x${height}, Bitrate: $videoBitrate');

      // Se já executamos o comando em duas etapas (com áudio externo), não executar novamente
      ReturnCode? finalReturnCode;
      
      if (externalAudioPath == null || externalAudioPath.isEmpty) {
        print('[VideoGenerator] Executing FFmpeg...');
        final session = await FFmpegKit.execute(command);
        finalReturnCode = await session.getReturnCode();
        print('[VideoGenerator] FFmpeg return code: $finalReturnCode');
        
        // Verificar resultado
        if (!ReturnCode.isSuccess(finalReturnCode)) {
          final logs = await session.getLogs();
          final errorMessages = logs.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList();
          print('[VideoGenerator] FFmpeg ERROR - Return code: $finalReturnCode');
          print('[VideoGenerator] FFmpeg error logs:');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
          
          // Limpar arquivo de concatenação
          try {
            await File(concatFile).delete();
            print('[VideoGenerator] Concat file deleted');
          } catch (e) {
            print('[VideoGenerator] Warning: Could not delete concat file: $e');
          }
          
          return null;
        }
      } else {
        // Se usamos áudio externo, o returnCode já foi verificado acima
        finalReturnCode = returnCode;
        
        if (!ReturnCode.isSuccess(finalReturnCode)) {
          final logs = await session?.getLogs();
          final errorMessages = logs?.map((e) => e.getMessage()).where((msg) => msg.isNotEmpty).toList() ?? [];
          print('[VideoGenerator] FFmpeg ERROR - Return code: $finalReturnCode');
          print('[VideoGenerator] FFmpeg error logs:');
          for (var log in errorMessages) {
            print('[VideoGenerator]   $log');
          }
          
          // Limpar arquivo de concatenação
          try {
            await File(concatFile).delete();
            print('[VideoGenerator] Concat file deleted');
          } catch (e) {
            print('[VideoGenerator] Warning: Could not delete concat file: $e');
          }
          
          return null;
        }
      }

      // Limpar arquivo de concatenação após sucesso
      try {
        await File(concatFile).delete();
        print('[VideoGenerator] Concat file deleted');
      } catch (e) {
        print('[VideoGenerator] Warning: Could not delete concat file: $e');
      }

      print('[VideoGenerator] SUCCESS: Video generated at $finalOutputPath');
      return finalOutputPath;
    } catch (e) {
      print('[VideoGenerator] ERROR: Exception during video generation: $e');
      return null;
    }
  }

  // Criar arquivo de concatenação para ProjectMediaItem
  static Future<String?> _createProjectConcatFile(List<ProjectMediaItem> mediaItems) async {
    print('[VideoGenerator] Creating concat file for ${mediaItems.length} media items');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory(path.join(appDir.path, 'temp'));
      
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      final concatFile = File(path.join(tempDir.path, 'project_concat_${_uuid.v4()}.txt'));
      final buffer = StringBuffer();
      int validItems = 0;
      int invalidItems = 0;

      for (var i = 0; i < mediaItems.length; i++) {
        final item = mediaItems[i];
        print('[VideoGenerator] Processing item $i/${mediaItems.length}: ${item.id} (${item.mediaType})');
        
        // Para fotos: usar editedPath (vídeo convertido) se disponível, senão originalPath
        // Para vídeos: usar originalPath (já cortado para 1 segundo no VideoEditScreen)
        String clipPath = item.mediaType == 'photo' 
            ? (item.editedPath ?? item.originalPath)
            : item.originalPath;
        final file = File(clipPath);
        
        if (!await file.exists()) {
          print('[VideoGenerator] WARNING: Item ${item.id} - File does not exist: $clipPath');
          invalidItems++;
          continue;
        }
        
        // Se for foto e não tiver editedPath (vídeo convertido), converter agora
        // Isso é um fallback caso a conversão não tenha sido feita anteriormente
        if (item.mediaType == 'photo' && item.editedPath == null) {
          print('[VideoGenerator] Item ${item.id} is a photo, converting to video...');
          print('[VideoGenerator] Using photo path: $clipPath');
          
          // Verificar extensão
          final fileExtension = path.extension(clipPath).toLowerCase();
          final imageExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp'];
          if (!imageExtensions.contains(fileExtension)) {
            print('[VideoGenerator] WARNING: File extension "$fileExtension" is not an image. Skipping conversion.');
            invalidItems++;
            continue;
          }
          
          // Converter foto para vídeo de 1 segundo usando VideoEditorService
          final videoPath = await VideoEditorService.convertPhotoToVideo(photoPath: clipPath);
          if (videoPath == null) {
            print('[VideoGenerator] ERROR: Failed to convert photo to video for item ${item.id}');
            invalidItems++;
            continue;
          }
          clipPath = videoPath;
          print('[VideoGenerator] Photo converted to video: $clipPath');
        }

        // Escapar barras invertidas e aspas no caminho para FFmpeg
        // FFmpeg no Android espera caminhos Unix-style
        final escapedPath = clipPath.replaceAll('\\', '/').replaceAll("'", "\\'");
        print('[VideoGenerator] Adding to concat: $escapedPath');
        buffer.writeln("file '$escapedPath'");
        validItems++;
        print('[VideoGenerator] Added item $i to concat file: $escapedPath');
      }

      if (validItems == 0) {
        print('[VideoGenerator] ERROR: No valid media items found for concat file');
        return null;
      }

      print('[VideoGenerator] Concat file summary: $validItems valid, $invalidItems invalid');
      await concatFile.writeAsString(buffer.toString());
      
      // Log do conteúdo do arquivo concat (primeiras linhas)
      final content = await concatFile.readAsString();
      final lines = content.split('\n').take(5).toList();
      print('[VideoGenerator] Concat file content (first 5 lines):');
      for (var line in lines) {
        print('[VideoGenerator]   $line');
      }
      
      return concatFile.path;
    } catch (e, stackTrace) {
      print('[VideoGenerator] ERROR creating concat file: $e');
      print('[VideoGenerator] Stack trace: $stackTrace');
      return null;
    }
  }
}

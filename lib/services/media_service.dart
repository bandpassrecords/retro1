import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  // Solicitar permissões
  static Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;

    if (cameraStatus.isDenied || storageStatus.isDenied || photosStatus.isDenied) {
      final cameraResult = await Permission.camera.request();
      final storageResult = await Permission.storage.request();
      final photosResult = await Permission.photos.request();

      return cameraResult.isGranted &&
          (storageResult.isGranted || photosResult.isGranted);
    }

    return cameraStatus.isGranted &&
        (storageStatus.isGranted || photosStatus.isGranted);
  }

  // Capturar vídeo da câmera
  static Future<XFile?> captureVideo() async {
    if (!await requestPermissions()) {
      return null;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      return null;
    }
  }

  // Capturar foto da câmera
  static Future<XFile?> capturePhoto() async {
    if (!await requestPermissions()) {
      return null;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      return photo;
    } catch (e) {
      return null;
    }
  }

  // Selecionar vídeo da galeria
  static Future<XFile?> pickVideoFromGallery() async {
    if (!await requestPermissions()) {
      return null;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      return video;
    } catch (e) {
      return null;
    }
  }

  // Selecionar foto da galeria
  static Future<XFile?> pickPhotoFromGallery() async {
    if (!await requestPermissions()) {
      return null;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      return photo;
    } catch (e) {
      return null;
    }
  }

  // Copiar arquivo para diretório do app
  static Future<String> copyToAppDirectory(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'media'));
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final fileName = '${_uuid.v4()}${path.extension(sourcePath)}';
    final destPath = path.join(mediaDir.path, fileName);
    
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);

    return destPath;
  }

  // Obter diretório de mídia do app
  static Future<Directory> getMediaDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'media'));
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    return mediaDir;
  }

  // Deletar arquivo
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Verificar se arquivo existe
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  // PermissionStatus.granted OR .limited both count as accessible.
  static bool _isMediaAccessible(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }

  /// Request only camera (+ microphone for video) — no photo library needed.
  static Future<bool> _requestCameraPermission({bool withMic = false}) async {
    final camera = await Permission.camera.request();
    if (!camera.isGranted) return false;
    if (withMic) {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) return false;
    }
    return true;
  }

  /// Request photo library access for gallery operations.
  static Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final results = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();
      final storageOk = results[Permission.storage]?.isGranted ?? false;
      final photosOk = _isMediaAccessible(results[Permission.photos]);
      final videosOk = _isMediaAccessible(results[Permission.videos]);
      return storageOk || photosOk || videosOk;
    } else if (Platform.isIOS) {
      final photosResult = await Permission.photos.request();
      return _isMediaAccessible(photosResult);
    }
    return true;
  }

  // Capturar vídeo da câmera
  static Future<XFile?> captureVideo() async {
    if (!await _requestCameraPermission(withMic: true)) return null;
    try {
      return await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (_) {
      return null;
    }
  }

  // Capturar foto da câmera
  static Future<XFile?> capturePhoto() async {
    if (!await _requestCameraPermission()) return null;
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
    } catch (_) {
      return null;
    }
  }

  // Selecionar vídeo da galeria
  static Future<XFile?> pickVideoFromGallery() async {
    if (!await _requestGalleryPermission()) return null;
    try {
      return await _picker.pickVideo(source: ImageSource.gallery);
    } catch (_) {
      return null;
    }
  }

  // Selecionar foto da galeria
  static Future<XFile?> pickPhotoFromGallery() async {
    if (!await _requestGalleryPermission()) return null;
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
    } catch (_) {
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

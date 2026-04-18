import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/daily_entry.dart';
import '../models/app_settings.dart';
import '../models/free_project.dart';
import '../models/project_media_item.dart';
import 'hive_service.dart';

class BackupService {
  static const String _backupFolder = 'appDataFolder';
  static const String _backupPrefix = 'retro1_backup_';
  static const String _backupMimeType = 'application/zip';

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  static const String _serverClientId =
      '25911193590-7mq2h3okddocs1nnhrbsgs6hcm550dsp.apps.googleusercontent.com';

  static bool _initialized = false;
  static GoogleSignInAccount? _currentAccount;

  // ─── Auth ───────────────────────────────────────────────────────────────────

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  static Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      _currentAccount = await GoogleSignIn.instance.authenticate();
      await _currentAccount!.authorizationClient.authorizeScopes(_scopes);
      return _currentAccount;
    } catch (e) {
      print('[BackupService] Sign-in error: $e');
      _currentAccount = null;
      return null;
    }
  }

  static Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    _currentAccount = null;
  }

  static Future<GoogleSignInAccount?> get currentUser async {
    if (_currentAccount != null) return _currentAccount;
    await _ensureInitialized();
    try {
      // attemptLightweightAuthentication returns Future<Account?>? (nullable Future)
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      _currentAccount = future != null ? await future : null;
      return _currentAccount;
    } catch (_) {
      return null;
    }
  }

  static bool get isSignedIn => _currentAccount != null;

  // ─── Backup ─────────────────────────────────────────────────────────────────

  static Future<void> performBackup() async {
    final account = await currentUser;
    if (account == null) throw Exception('Not signed in to Google');

    print('[BackupService] Starting backup...');
    final driveApi = await _getDriveApi(account);

    final zipPath = await _createBackupZip();
    try {
      await _uploadToDrive(zipPath, driveApi);
      // Save last backup time
      final settings = HiveService.getSettings();
      settings.lastBackupTime = DateTime.now();
      await HiveService.saveSettings(settings);
      print('[BackupService] Backup complete');
    } finally {
      File(zipPath).deleteSync();
    }
  }

  static Future<String> _createBackupZip() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/temp');
    await tempDir.create(recursive: true);
    final zipPath = '${tempDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.zip';

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // ── Serialize Hive data to JSON ──
    final dataJson = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'daily_entries': HiveService.getAllEntries().map(_serializeEntry).toList(),
      'app_settings': _serializeSettings(HiveService.getSettings()),
      'free_projects': HiveService.getAllProjects().map(_serializeProject).toList(),
      'project_media_items': HiveService.getAllProjects()
          .expand((p) => HiveService.getAllMediaItemsForProject(p.id))
          .map(_serializeMediaItem)
          .toList(),
    });

    final dataFile = File('${tempDir.path}/data.json');
    await dataFile.writeAsString(dataJson);
    encoder.addFile(dataFile, 'data/backup.json');
    await dataFile.delete();

    // ── Add media files ──
    final mediaDir = Directory('${appDir.path}/media');
    if (await mediaDir.exists()) {
      final files = mediaDir.listSync().whereType<File>().toList();
      print('[BackupService] Adding ${files.length} media files to backup');
      for (final file in files) {
        encoder.addFile(file, 'media/${p.basename(file.path)}');
      }
    }

    encoder.close();
    print('[BackupService] Zip created: $zipPath');
    return zipPath;
  }

  static Future<void> _uploadToDrive(String zipPath, drive.DriveApi driveApi) async {
    final fileName = '$_backupPrefix${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip';

    // Delete previous backups to save space
    await _deletePreviousBackups(driveApi);

    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = [_backupFolder];

    final media = drive.Media(
      File(zipPath).openRead(),
      File(zipPath).lengthSync(),
      contentType: _backupMimeType,
    );

    print('[BackupService] Uploading $fileName to Drive...');
    await driveApi.files.create(fileMetadata, uploadMedia: media);
    print('[BackupService] Upload complete');
  }

  static Future<void> _deletePreviousBackups(drive.DriveApi driveApi) async {
    final result = await driveApi.files.list(
      spaces: _backupFolder,
      q: "name contains '$_backupPrefix'",
      $fields: 'files(id,name)',
    );
    for (final file in result.files ?? []) {
      print('[BackupService] Deleting old backup: ${file.name}');
      await driveApi.files.delete(file.id!);
    }
  }

  // ─── Restore ────────────────────────────────────────────────────────────────

  static Future<void> performRestore() async {
    final account = await currentUser;
    if (account == null) throw Exception('Not signed in to Google');

    print('[BackupService] Starting restore...');
    final driveApi = await _getDriveApi(account);

    final zipPath = await _downloadLatestBackup(driveApi);
    if (zipPath == null) throw Exception('No backup found in Google Drive');

    try {
      await _restoreFromZip(zipPath);
      print('[BackupService] Restore complete');
    } finally {
      File(zipPath).deleteSync();
    }
  }

  static Future<String?> _downloadLatestBackup(drive.DriveApi driveApi) async {
    final result = await driveApi.files.list(
      spaces: _backupFolder,
      q: "name contains '$_backupPrefix'",
      orderBy: 'createdTime desc',
      $fields: 'files(id,name)',
    );

    final files = result.files ?? [];
    if (files.isEmpty) return null;

    final latest = files.first;
    print('[BackupService] Downloading backup: ${latest.name}');

    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/temp');
    await tempDir.create(recursive: true);
    final zipPath = '${tempDir.path}/restore_${DateTime.now().millisecondsSinceEpoch}.zip';

    final media = await driveApi.files.get(
      latest.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final sink = File(zipPath).openWrite();
    await sink.addStream(media.stream);
    await sink.close();

    print('[BackupService] Downloaded to $zipPath');
    return zipPath;
  }

  static Future<void> _restoreFromZip(String zipPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // ── Extract media files ──
    final mediaDir = Directory('${appDir.path}/media');
    await mediaDir.create(recursive: true);

    for (final file in archive) {
      if (file.name.startsWith('media/') && file.isFile) {
        final outPath = '${appDir.path}/${file.name}';
        File(outPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      }
    }

    // ── Restore Hive data ──
    final dataFile = archive.findFile('data/backup.json');
    if (dataFile == null) throw Exception('Backup data file not found in archive');

    final json = jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map<String, dynamic>;
    final appDirPath = appDir.path;

    // Clear existing data
    for (final entry in HiveService.getAllEntries()) {
      await HiveService.deleteEntry(entry.id);
    }
    for (final project in HiveService.getAllProjects()) {
      await HiveService.deleteProject(project.id);
    }

    // Restore entries
    for (final raw in (json['daily_entries'] as List)) {
      await HiveService.saveEntry(_deserializeEntry(raw as Map<String, dynamic>, appDirPath));
    }

    // Restore projects
    for (final raw in (json['free_projects'] as List)) {
      await HiveService.saveProject(_deserializeProject(raw as Map<String, dynamic>, appDirPath));
    }

    // Restore project media items
    for (final raw in (json['project_media_items'] as List)) {
      await HiveService.saveProjectMediaItem(_deserializeMediaItem(raw as Map<String, dynamic>, appDirPath));
    }

    // Restore settings (preserve current notification/backup prefs)
    final current = HiveService.getSettings();
    final restored = _deserializeSettings(json['app_settings'] as Map<String, dynamic>);
    restored.notificationsEnabled = current.notificationsEnabled;
    restored.notificationHour = current.notificationHour;
    restored.notificationMinute = current.notificationMinute;
    restored.autoBackup = current.autoBackup;
    restored.backupFrequency = current.backupFrequency;
    await HiveService.saveSettings(restored);

    print('[BackupService] Restored ${(json['daily_entries'] as List).length} entries, '
        '${(json['free_projects'] as List).length} projects');
  }

  // ─── Serialization ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _serializeEntry(DailyEntry e) => {
    'id': e.id,
    'date': e.date.toIso8601String(),
    'mediaType': e.mediaType,
    'originalPath': p.basename(e.originalPath),
    'startTimeMs': e.startTimeMs,
    'durationMs': e.durationMs,
    'caption': e.caption,
    'createdAt': e.createdAt.toIso8601String(),
    'timezone': e.timezone,
    'thumbnailPath': e.thumbnailPath != null ? p.basename(e.thumbnailPath!) : null,
    'hasAudio': e.hasAudio,
  };

  static DailyEntry _deserializeEntry(Map<String, dynamic> j, String appDir) => DailyEntry(
    id: j['id'],
    date: DateTime.parse(j['date']),
    mediaType: j['mediaType'],
    originalPath: '$appDir/media/${j['originalPath']}',
    startTimeMs: j['startTimeMs'],
    durationMs: j['durationMs'],
    caption: j['caption'],
    createdAt: DateTime.parse(j['createdAt']),
    timezone: j['timezone'],
    thumbnailPath: j['thumbnailPath'] != null ? '$appDir/media/${j['thumbnailPath']}' : null,
    hasAudio: j['hasAudio'] ?? false,
  );

  static Map<String, dynamic> _serializeSettings(AppSettings s) => {
    'videoQuality': s.videoQuality,
    'themeMode': s.themeMode,
    'language': s.language,
    'showDateOverlay': s.showDateOverlay,
    'notificationUseQuotes': s.notificationUseQuotes,
    'dateFormat': s.dateFormat,
  };

  static AppSettings _deserializeSettings(Map<String, dynamic> j) => AppSettings(
    videoQuality: j['videoQuality'] ?? '1080p',
    themeMode: j['themeMode'] ?? 'system',
    language: j['language'] ?? 'en',
    showDateOverlay: j['showDateOverlay'] ?? true,
    notificationUseQuotes: j['notificationUseQuotes'] ?? true,
    dateFormat: j['dateFormat'] ?? 'dd/MM/yyyy',
  );

  static Map<String, dynamic> _serializeProject(FreeProject proj) => {
    'id': proj.id,
    'name': proj.name,
    'description': proj.description,
    'createdAt': proj.createdAt.toIso8601String(),
    'updatedAt': proj.updatedAt.toIso8601String(),
    'mediaItemIds': proj.mediaItemIds,
    'thumbnailPath': proj.thumbnailPath != null ? p.basename(proj.thumbnailPath!) : null,
    'coverImagePath': proj.coverImagePath != null ? p.basename(proj.coverImagePath!) : null,
  };

  static FreeProject _deserializeProject(Map<String, dynamic> j, String appDir) => FreeProject(
    id: j['id'],
    name: j['name'],
    description: j['description'],
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
    mediaItemIds: List<String>.from(j['mediaItemIds']),
    thumbnailPath: j['thumbnailPath'] != null ? '$appDir/media/${j['thumbnailPath']}' : null,
    coverImagePath: j['coverImagePath'] != null ? '$appDir/media/${j['coverImagePath']}' : null,
  );

  static Map<String, dynamic> _serializeMediaItem(ProjectMediaItem item) => {
    'id': item.id,
    'mediaType': item.mediaType,
    'originalPath': p.basename(item.originalPath),
    'editedPath': item.editedPath != null ? p.basename(item.editedPath!) : null,
    'startTimeMs': item.startTimeMs,
    'durationMs': item.durationMs,
    'order': item.order,
    'caption': item.caption,
    'createdAt': item.createdAt.toIso8601String(),
    'rotation': item.rotation,
    'animationType': item.animationType,
    'animationParams': item.animationParams,
    'playbackSpeed': item.playbackSpeed,
    'muteAudio': item.muteAudio,
    'filter': item.filter,
    'brightness': item.brightness,
    'contrast': item.contrast,
    'saturation': item.saturation,
    'thumbnailPath': item.thumbnailPath != null ? p.basename(item.thumbnailPath!) : null,
  };

  static ProjectMediaItem _deserializeMediaItem(Map<String, dynamic> j, String appDir) => ProjectMediaItem(
    id: j['id'],
    mediaType: j['mediaType'],
    originalPath: '$appDir/media/${j['originalPath']}',
    editedPath: j['editedPath'] != null ? '$appDir/media/${j['editedPath']}' : null,
    startTimeMs: j['startTimeMs'] ?? 0,
    durationMs: j['durationMs'] ?? 1000,
    order: j['order'] ?? 0,
    caption: j['caption'],
    createdAt: DateTime.parse(j['createdAt']),
    rotation: j['rotation'] ?? 0,
    animationType: j['animationType'] ?? 'none',
    animationParams: j['animationParams'] != null
        ? Map<String, dynamic>.from(j['animationParams'])
        : null,
    playbackSpeed: (j['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
    muteAudio: j['muteAudio'] ?? false,
    filter: j['filter'] ?? 'none',
    brightness: (j['brightness'] as num?)?.toDouble() ?? 0.0,
    contrast: (j['contrast'] as num?)?.toDouble() ?? 0.0,
    saturation: (j['saturation'] as num?)?.toDouble() ?? 0.0,
    thumbnailPath: j['thumbnailPath'] != null ? '$appDir/media/${j['thumbnailPath']}' : null,
  );

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static Future<drive.DriveApi> _getDriveApi(GoogleSignInAccount account) async {
    final headers = await account.authorizationClient.authorizationHeaders(_scopes);
    if (headers == null) throw Exception('Failed to get Drive authorization. Please sign in again.');
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  /// Returns info about the latest backup on Drive, or null if none exists.
  static Future<drive.File?> getLatestBackupInfo() async {
    final account = await currentUser;
    if (account == null) return null;
    try {
      final driveApi = await _getDriveApi(account);
      final result = await driveApi.files.list(
        spaces: _backupFolder,
        q: "name contains '$_backupPrefix'",
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,createdTime,size)',
      );
      return (result.files?.isNotEmpty == true) ? result.files!.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Checks if auto backup should run based on frequency setting.
  static Future<void> checkAndRunAutoBackup() async {
    final settings = HiveService.getSettings();
    if (!settings.autoBackup || settings.backupFrequency == 'manual') return;

    final last = settings.lastBackupTime;
    final now = DateTime.now();
    final shouldRun = last == null ||
        (settings.backupFrequency == 'daily' && now.difference(last).inHours >= 24) ||
        (settings.backupFrequency == 'weekly' && now.difference(last).inDays >= 7);

    if (shouldRun) {
      try {
        await performBackup();
      } catch (e) {
        print('[BackupService] Auto backup failed: $e');
      }
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_entry.dart';
import '../models/app_settings.dart';
import '../models/free_project.dart';
import '../models/project_media_item.dart';

class HiveService {
  static const String _entriesBoxName = 'daily_entries';
  static const String _settingsBoxName = 'app_settings';
  static const String _projectsBoxName = 'free_projects';
  static const String _projectMediaBoxName = 'project_media_items';
  static const String _settingsKey = 'settings';

  static Box<DailyEntry>? _entriesBox;
  static Box<AppSettings>? _settingsBox;
  static Box<FreeProject>? _projectsBox;
  static Box<ProjectMediaItem>? _projectMediaBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registrar adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DailyEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FreeProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProjectMediaItemAdapter());
    }

    // Abrir boxes
    _entriesBox = await Hive.openBox<DailyEntry>(_entriesBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
    _projectsBox = await Hive.openBox<FreeProject>(_projectsBoxName);
    _projectMediaBox = await Hive.openBox<ProjectMediaItem>(_projectMediaBoxName);

    // Inicializar configurações padrão se não existirem
    if (_settingsBox!.isEmpty) {
      await saveSettings(AppSettings());
    }
  }

  // ========== Daily Entries ==========

  static Future<void> saveEntry(DailyEntry entry) async {
    await _entriesBox!.put(entry.id, entry);
  }

  static DailyEntry? getEntry(String id) {
    return _entriesBox!.get(id);
  }

  static DailyEntry? getEntryByDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (var entry in _entriesBox!.values) {
      if (entry.dateOnly == dateOnly) {
        return entry;
      }
    }
    return null;
  }

  static List<DailyEntry> getAllEntries() {
    return _entriesBox!.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<DailyEntry> getEntriesByYear(int year) {
    return _entriesBox!.values
        .where((entry) => entry.date.year == year)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<DailyEntry> getEntriesByMonth(int year, int month) {
    return _entriesBox!.values
        .where((entry) =>
            entry.date.year == year && entry.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<DailyEntry> getEntriesByDateRange(
      DateTime start, DateTime end) {
    return _entriesBox!.values
        .where((entry) =>
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static Future<void> deleteEntry(String id) async {
    await _entriesBox!.delete(id);
  }

  static Future<void> deleteEntryByDate(DateTime date) async {
    final entry = getEntryByDate(date);
    if (entry != null) {
      await deleteEntry(entry.id);
    }
  }

  static int getTotalEntries() {
    return _entriesBox!.length;
  }

  static int getEntriesCountForYear(int year) {
    return getEntriesByYear(year).length;
  }

  static int getEntriesCountForMonth(int year, int month) {
    return getEntriesByMonth(year, month).length;
  }

  static bool hasEntryForDate(DateTime date) {
    return getEntryByDate(date) != null;
  }

  // ========== Settings ==========

  static AppSettings getSettings() {
    return _settingsBox!.get(_settingsKey) ?? AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox!.put(_settingsKey, settings);
  }

  // ========== Free Projects ==========

  static Future<void> saveProject(FreeProject project) async {
    project.updatedAt = DateTime.now();
    await _projectsBox!.put(project.id, project);
  }

  static FreeProject? getProject(String id) {
    return _projectsBox!.get(id);
  }

  static List<FreeProject> getAllProjects() {
    return _projectsBox!.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> deleteProject(String id) async {
    final project = getProject(id);
    if (project != null) {
      // Deletar todos os media items do projeto
      for (var mediaId in project.mediaItemIds) {
        await deleteProjectMediaItem(mediaId);
      }
      await _projectsBox!.delete(id);
    }
  }

  static int getTotalProjects() {
    return _projectsBox!.length;
  }

  // ========== Project Media Items ==========

  static Future<void> saveProjectMediaItem(ProjectMediaItem item) async {
    await _projectMediaBox!.put(item.id, item);
  }

  static ProjectMediaItem? getProjectMediaItem(String id) {
    return _projectMediaBox!.get(id);
  }

  static List<ProjectMediaItem> getProjectMediaItems(List<String> ids) {
    return ids
        .map((id) => _projectMediaBox!.get(id))
        .whereType<ProjectMediaItem>()
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  static List<ProjectMediaItem> getAllMediaItemsForProject(String projectId) {
    final project = getProject(projectId);
    if (project == null) return [];
    return getProjectMediaItems(project.mediaItemIds);
  }

  static Future<void> deleteProjectMediaItem(String id) async {
    await _projectMediaBox!.delete(id);
  }

  static Future<void> addMediaItemToProject(String projectId, String mediaItemId) async {
    final project = getProject(projectId);
    if (project != null) {
      if (!project.mediaItemIds.contains(mediaItemId)) {
        project.mediaItemIds.add(mediaItemId);
        await saveProject(project);
      }
    }
  }

  static Future<void> removeMediaItemFromProject(String projectId, String mediaItemId) async {
    final project = getProject(projectId);
    if (project != null) {
      project.mediaItemIds.remove(mediaItemId);
      await saveProject(project);
      await deleteProjectMediaItem(mediaItemId);
    }
  }

  static Future<void> reorderProjectMediaItems(String projectId, List<String> newOrder) async {
    final project = getProject(projectId);
    if (project != null) {
      project.mediaItemIds = newOrder;
      // Atualizar ordem nos items
      for (int i = 0; i < newOrder.length; i++) {
        final item = getProjectMediaItem(newOrder[i]);
        if (item != null) {
          item.order = i;
          await saveProjectMediaItem(item);
        }
      }
      await saveProject(project);
    }
  }

  // ========== Cleanup ==========

  static Future<void> close() async {
    await _entriesBox?.close();
    await _settingsBox?.close();
    await _projectsBox?.close();
    await _projectMediaBox?.close();
  }
}

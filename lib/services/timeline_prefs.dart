import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts the user's preferred timeline view.
/// Values: [calendarView] (default) or [gridView].
class TimelinePrefs {
  static const String _key = 'timeline_view';
  static const String calendarView = 'calendar';
  static const String gridView = 'grid';

  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getString(_key);
  }

  static Future<void> set(String view) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, view);
    notifier.value = view;
  }

  static String get current => notifier.value ?? calendarView;
}

/// Persists and broadcasts the user's preferred thumbnail size.
/// Values: [small] (default, 3 columns) or [large] (2 columns).
class ThumbnailSizePrefs {
  static const String _key = 'thumbnail_size';
  static const String small = 'small';
  static const String large = 'large';

  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getString(_key);
  }

  static Future<void> set(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, size);
    notifier.value = size;
  }

  static String get current => notifier.value ?? small;
  static int get crossAxisCount => current == large ? 3 : 4;
}

/// Persists and broadcasts the user's preferred media picker style.
/// Values: [customPicker] (default) or [systemPicker].
class MediaPickerPrefs {
  static const String _key = 'media_picker_style';
  static const String customPicker = 'custom';
  static const String systemPicker = 'system';

  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getString(_key);
  }

  static Future<void> set(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style);
    notifier.value = style;
  }

  static String get current => notifier.value ?? customPicker;
}

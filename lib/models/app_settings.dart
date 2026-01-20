import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  int notificationHour;

  @HiveField(1)
  int notificationMinute;

  @HiveField(2)
  bool notificationsEnabled;

  @HiveField(3)
  String videoQuality; // '720p', '1080p', '4K'

  @HiveField(4)
  bool autoBackup;

  @HiveField(5)
  String themeMode; // 'light', 'dark', 'system'

  @HiveField(6)
  String language;

  @HiveField(7)
  bool autoExportYearEnd;

  @HiveField(8)
  bool showDateOverlay;

  @HiveField(9)
  int reminderDelayHours; // Horas após notificação principal

  @HiveField(10)
  double? lastCalendarScrollPosition; // Posição de scroll do calendário

  AppSettings({
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.notificationsEnabled = true,
    this.videoQuality = '1080p',
    this.autoBackup = false,
    this.themeMode = 'system',
    this.language = 'en', // Default to English
    this.autoExportYearEnd = false,
    this.showDateOverlay = true,
    this.reminderDelayHours = 3,
    this.lastCalendarScrollPosition,
  });

  // Getter para lastCalendarScrollPosition com valor padrão
  double get lastCalendarScrollPositionOrDefault {
    return lastCalendarScrollPosition ?? 0.0;
  }

  // Getter para TimeOfDay
  TimeOfDay get notificationTime {
    return TimeOfDay(hour: notificationHour, minute: notificationMinute);
  }

  // Setter para TimeOfDay
  set notificationTime(TimeOfDay time) {
    notificationHour = time.hour;
    notificationMinute = time.minute;
  }
}

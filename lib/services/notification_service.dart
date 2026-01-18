import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../services/hive_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    print('[NotificationService] Initializing...');
    
    // 1. Inicializar timezones primeiro
    tz.initializeTimeZones();
    
    // 2. Configurar timezone local do sistema
    try {
      // Obter o offset do timezone do sistema
      final systemOffset = DateTime.now().timeZoneOffset;
      final offsetHours = systemOffset.inHours;
      final offsetMinutes = systemOffset.inMinutes % 60;
      
      print('[NotificationService] System timezone offset: $systemOffset (${offsetHours >= 0 ? '+' : ''}$offsetHours:${offsetMinutes.toString().padLeft(2, '0')})');
      
      // Mapear offset para timezone IANA comum
      // Usar timezones reais em vez de Etc/GMT para melhor suporte a DST
      final timezoneMap = {
        0: 'UTC',
        1: 'Europe/Paris',      // UTC+1 (CET/CEST)
        -1: 'Atlantic/Azores',   // UTC-1
        2: 'Europe/Berlin',      // UTC+2 (CEST)
        -2: 'Atlantic/South_Georgia', // UTC-2
        3: 'Europe/Moscow',      // UTC+3
        -3: 'America/Sao_Paulo', // UTC-3 (BRT)
        4: 'Asia/Dubai',         // UTC+4
        -4: 'America/New_York',  // UTC-4 (EDT) ou UTC-5 (EST)
        5: 'Asia/Karachi',       // UTC+5
        -5: 'America/Chicago',   // UTC-5 (CDT) ou UTC-6 (CST)
        -6: 'America/Denver',    // UTC-6 (MDT) ou UTC-7 (MST)
        -7: 'America/Los_Angeles', // UTC-7 (PDT) ou UTC-8 (PST)
        8: 'Asia/Shanghai',      // UTC+8
        -8: 'Pacific/Pitcairn',  // UTC-8
        9: 'Asia/Tokyo',         // UTC+9
        -9: 'Pacific/Gambier',   // UTC-9
        10: 'Australia/Sydney',  // UTC+10 (AEDT) ou UTC+11 (AEST)
        -10: 'Pacific/Honolulu', // UTC-10
      };
      
      // Tentar usar timezone baseado no offset
      final suggestedTimezone = timezoneMap[offsetHours];
      if (suggestedTimezone != null) {
        try {
          final suggestedLocation = tz.getLocation(suggestedTimezone);
          tz.setLocalLocation(suggestedLocation);
          final suggestedOffset = suggestedLocation.currentTimeZone.offset;
          final suggestedOffsetHours = suggestedOffset ~/ 3600;
          print('[NotificationService] Set timezone to: $suggestedTimezone (offset: $suggestedOffset seconds, $suggestedOffsetHours hours)');
        } catch (e) {
          print('[NotificationService] Could not set suggested timezone $suggestedTimezone: $e');
          // Usar Etc/GMT como fallback
          _setTimezoneByOffset(offsetHours);
        }
      } else {
        // Se não houver mapeamento, usar Etc/GMT baseado no offset
        _setTimezoneByOffset(offsetHours);
      }
      
      // Verificar se o timezone foi configurado corretamente
      final localLocation = tz.local;
      final locationOffset = localLocation.currentTimeZone.offset;
      // currentTimeZone.offset retorna int (segundos) na versão nova do timezone
      final locationOffsetHours = locationOffset ~/ 3600; // Converter segundos para horas
      print('[NotificationService] Configured timezone: ${localLocation.name}');
      print('[NotificationService] Configured timezone offset: $locationOffset seconds (${locationOffsetHours} hours)');
      
      // Verificar se o offset corresponde ao sistema
      // Permitir diferença de até 1 hora devido a DST (Daylight Saving Time)
      final offsetDiff = (locationOffsetHours - offsetHours).abs();
      if (offsetDiff > 1) {
        print('[NotificationService] WARNING: Timezone offset mismatch! System: $offsetHours, Configured: $locationOffsetHours');
        print('[NotificationService] Attempting to fix...');
        _setTimezoneByOffset(offsetHours);
        
        // Verificar novamente após correção
        final correctedLocation = tz.local;
        final correctedOffset = correctedLocation.currentTimeZone.offset;
        final correctedOffsetHours = correctedOffset ~/ 3600; // Converter segundos para horas
        print('[NotificationService] After correction - Timezone: ${correctedLocation.name}, Offset: $correctedOffset seconds ($correctedOffsetHours hours)');
      } else {
        print('[NotificationService] Timezone configured correctly (offset difference: $offsetDiff hours, may be due to DST)');
      }
    } catch (e) {
      print('[NotificationService] WARNING: Could not configure local timezone: $e');
      // Fallback para UTC se não conseguir detectar
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        print('[NotificationService] Fallback to UTC timezone');
      } catch (e2) {
        print('[NotificationService] ERROR setting UTC timezone: $e2');
      }
    }
    
    // 3. Configurar inicialização do plugin (apenas Android)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    print('[NotificationService] Initialized: $initialized');

    if (initialized != true) {
      print('[NotificationService] WARNING: Plugin initialization failed');
      return;
    }

    // 4. Solicitar permissões
    await _requestPermissions();
    
    // 5. Agendar notificações
    await scheduleNotifications();
    print('[NotificationService] Initialization complete');
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Solicitar permissão de notificações (Android 13+)
        final notificationPermission = await androidPlugin.requestNotificationsPermission();
        print('[NotificationService] Notification permission granted: $notificationPermission');
        
        // Verificar se as notificações estão habilitadas
        final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
        print('[NotificationService] Are notifications enabled: $areNotificationsEnabled');
        
        if (areNotificationsEnabled == false) {
          print('[NotificationService] WARNING: Notifications are disabled in system settings');
        }
      }
    }
  }

  // Helper para configurar timezone baseado no offset
  static void _setTimezoneByOffset(int offsetHours) {
    try {
      // Etc/GMT usa sinal invertido: GMT+1 = Etc/GMT-1
      String timezoneName;
      if (offsetHours == 0) {
        timezoneName = 'UTC';
      } else if (offsetHours > 0) {
        timezoneName = 'Etc/GMT-$offsetHours';
      } else {
        timezoneName = 'Etc/GMT+${-offsetHours}';
      }
      
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      print('[NotificationService] Set timezone to: $timezoneName (offset: $offsetHours)');
    } catch (e) {
      print('[NotificationService] ERROR setting timezone by offset: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('[NotificationService] Notification tapped: ${response.payload}');
    // Ação quando notificação é tocada
    // Pode navegar para a tela de captura
  }

  // Agendar notificações baseado nas configurações
  static Future<void> scheduleNotifications() async {
    print('[NotificationService] Scheduling notifications...');
    
    // Cancelar todas as notificações existentes primeiro
    await cancelAllNotifications();
    
    final settings = HiveService.getSettings();
    if (!settings.notificationsEnabled) {
      print('[NotificationService] Notifications are disabled in settings');
      return;
    }

    final time = TimeOfDay(
      hour: settings.notificationHour,
      minute: settings.notificationMinute,
    );
    print('[NotificationService] Notification time: ${time.hour}:${time.minute}');
    
    // Obter data/hora atual no timezone local
    final systemNow = DateTime.now();
    final now = tz.TZDateTime.now(tz.local);
    
    print('[NotificationService] System time: $systemNow (offset: ${systemNow.timeZoneOffset})');
    print('[NotificationService] Local timezone time: $now');
    print('[NotificationService] Local timezone: ${tz.local.name}');
    final localOffset = tz.local.currentTimeZone.offset;
    final localOffsetHours = localOffset ~/ 3600;
    print('[NotificationService] Local timezone offset: $localOffset seconds ($localOffsetHours hours)');
    
    // Criar data agendada para hoje no horário especificado
    // Usar o timezone local configurado
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    print('[NotificationService] Scheduled date (initial): $scheduledDate');
    print('[NotificationService] Scheduled date timezone: ${scheduledDate.timeZoneName}');
    print('[NotificationService] Scheduled date offset: ${scheduledDate.timeZoneOffset}');

    // Se já passou o horário de hoje, agendar para amanhã
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('[NotificationService] Time already passed, scheduling for tomorrow: $scheduledDate');
    }

    // Notificação diária principal (recorrente)
    print('[NotificationService] Scheduling daily notification for: $scheduledDate');
    await _scheduleDailyNotification(scheduledDate);

    // Lembrete inteligente (se configurado) - também recorrente
    if (settings.reminderDelayHours > 0) {
      // Calcular horário do lembrete baseado no horário da notificação principal
      var reminderDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        time.hour + settings.reminderDelayHours,
        time.minute,
      );
      
      // Se passar da meia-noite, ajustar
      if (reminderDate.hour >= 24) {
        reminderDate = tz.TZDateTime(
          tz.local,
          reminderDate.year,
          reminderDate.month,
          reminderDate.day + 1,
          reminderDate.hour - 24,
          reminderDate.minute,
        );
      }
      
      print('[NotificationService] Scheduling reminder for: $reminderDate (${settings.reminderDelayHours} hours after main notification)');
      await _scheduleReminderNotification(reminderDate);
    }
    
    // Verificar notificações pendentes após agendamento
    await Future.delayed(const Duration(milliseconds: 1000));
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    print('[NotificationService] Total pending notifications: ${pendingNotifications.length}');
    for (var notif in pendingNotifications) {
      print('[NotificationService]   - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
    }
    
    print('[NotificationService] Notifications scheduled successfully');
  }

  // Agendar notificação diária recorrente
  static Future<void> _scheduleDailyNotification(tz.TZDateTime scheduledDate) async {
    print('[NotificationService] Scheduling daily notification at: $scheduledDate');
    print('[NotificationService] Scheduled date timezone: ${scheduledDate.timeZoneName}');
    print('[NotificationService] Scheduled date (ISO): ${scheduledDate.toIso8601String()}');

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Lembrete Diário',
      channelDescription: 'Notificações para lembrar de registrar seu segundo do dia',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    try {
      // Cancelar notificação anterior com mesmo ID antes de agendar nova
      await _notifications.cancel(0);
      
      // Agendar notificação diária recorrente usando matchDateTimeComponents
      // Isso fará com que a notificação seja repetida diariamente no mesmo horário
      await _notifications.zonedSchedule(
        0,
        'Você já registrou seu segundo de hoje?',
        'Não esqueça de capturar seu momento especial!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente no mesmo horário
      );
      
      print('[NotificationService] Daily notification scheduled successfully');
      print('[NotificationService] Scheduled for: $scheduledDate (${scheduledDate.timeZoneName})');
      print('[NotificationService] Will repeat daily at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}');
    } catch (e, stackTrace) {
      print('[NotificationService] ERROR scheduling daily notification: $e');
      print('[NotificationService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Agendar notificação de lembrete (também recorrente)
  static Future<void> _scheduleReminderNotification(tz.TZDateTime scheduledDate) async {
    print('[NotificationService] Scheduling reminder notification at: $scheduledDate');
    print('[NotificationService] Reminder date timezone: ${scheduledDate.timeZoneName}');
    print('[NotificationService] Reminder date (ISO): ${scheduledDate.toIso8601String()}');

    const androidDetails = AndroidNotificationDetails(
      'reminder',
      'Lembrete',
      channelDescription: 'Lembretes adicionais',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    try {
      // Cancelar notificação anterior com mesmo ID antes de agendar nova
      await _notifications.cancel(1);
      
      // Agendar lembrete também como recorrente diário
      await _notifications.zonedSchedule(
        1,
        'Ainda não registrou hoje?',
        'Que tal capturar um momento agora?',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente no mesmo horário
      );
      
      print('[NotificationService] Reminder notification scheduled successfully');
      print('[NotificationService] Will repeat daily at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}');
    } catch (e, stackTrace) {
      print('[NotificationService] ERROR scheduling reminder notification: $e');
      print('[NotificationService] Stack trace: $stackTrace');
    }
  }

  // Enviar notificação de resumo semanal
  static Future<void> sendWeeklySummary() async {
    final settings = HiveService.getSettings();
    if (!settings.weeklySummaryEnabled) {
      return;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final entries = HiveService.getEntriesByDateRange(
      weekStart,
      now,
    );

    final completedDays = entries.length;
    final totalDays = now.weekday;

    const androidDetails = AndroidNotificationDetails(
      'weekly_summary',
      'Resumo Semanal',
      channelDescription: 'Resumos semanais do seu progresso',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      2,
      'Resumo da Semana',
      'Você completou $completedDays de $totalDays dias!',
      details,
    );
  }

  // Enviar notificação de conclusão de período
  static Future<void> sendPeriodCompletionNotification({
    required String period,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'period_completion',
      'Período Concluído',
      channelDescription: 'Notificações quando um período é concluído',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      3,
      'Seu vídeo de $period está pronto!',
      message,
      details,
    );
  }

  // Enviar notificação de teste manualmente
  static Future<void> sendTestNotification() async {
    print('[NotificationService] Sending test notification...');
    
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Lembrete Diário',
      channelDescription: 'Notificações para lembrar de registrar seu segundo do dia',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(
        999, // ID único para notificação de teste
        'Teste de Notificação',
        'Esta é uma notificação de teste. Se você está vendo isso, as notificações estão funcionando!',
        details,
      );
      print('[NotificationService] Test notification sent successfully');
    } catch (e) {
      print('[NotificationService] ERROR sending test notification: $e');
      rethrow;
    }
  }

  // Cancelar todas as notificações
  static Future<void> cancelAllNotifications() async {
    print('[NotificationService] Cancelling all notifications...');
    await _notifications.cancelAll();
    print('[NotificationService] All notifications cancelled');
  }

  // Cancelar notificação específica
  static Future<void> cancelNotification(int id) async {
    print('[NotificationService] Cancelling notification with id: $id');
    await _notifications.cancel(id);
    print('[NotificationService] Notification $id cancelled');
  }

  // Obter notificações pendentes (útil para debug)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

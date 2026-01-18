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

  // Verificar e cancelar notificações para dias que já têm entrada
  // Este método deve ser chamado quando uma entrada é adicionada
  static Future<void> checkAndCancelNotificationsForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final hasEntry = HiveService.hasEntryForDate(dateOnly);
    
    if (hasEntry) {
      print('[NotificationService] Entry exists for $dateOnly, canceling notifications for this date');
      
      // Calcular o offset do dia (quantos dias a partir de hoje)
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final dayOffset = dateOnly.difference(todayOnly).inDays;
      
      if (dayOffset >= 0 && dayOffset < 30) {
        // Cancelar notificação principal (ID 0-29)
        await _notifications.cancel(dayOffset);
        // Cancelar notificação de lembrete (ID 100-129)
        await _notifications.cancel(100 + dayOffset);
        print('[NotificationService] Canceled notifications for day offset: $dayOffset');
      }
    }
  }
  
  // Reagendar notificações após uma entrada ser adicionada
  static Future<void> rescheduleNotificationsAfterEntryAdded() async {
    print('[NotificationService] Rescheduling notifications after entry added');
    // Reagendar todas as notificações para garantir que estão corretas
    await scheduleNotifications();
  }

  // Agendar notificações baseado nas configurações
  // Agora verifica se a entrada existe antes de agendar
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
    
    // Agendar notificações para os próximos 30 dias, mas apenas para dias que não têm entrada
    // Isso garante que notificações só aparecem quando necessário
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
      
      // Verificar se já existe entrada para este dia
      final hasEntry = HiveService.hasEntryForDate(targetDateOnly);
      
      if (hasEntry) {
        print('[NotificationService] Entry exists for ${targetDateOnly}, skipping notification');
        continue;
      }
      
      // Criar data agendada para este dia no horário especificado
      var scheduledDate = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        time.hour,
        time.minute,
      );
      
      // Se já passou o horário de hoje, pular
      if (dayOffset == 0 && (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now))) {
        print('[NotificationService] Time already passed for today, skipping');
        continue;
      }
      
      print('[NotificationService] Scheduling notification for: $scheduledDate (day ${dayOffset})');
      await _scheduleNotificationForDate(scheduledDate, dayOffset);

      // Lembrete inteligente (se configurado)
      if (settings.reminderDelayHours > 0) {
        var reminderDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          time.hour + settings.reminderDelayHours,
          time.minute,
        );
        
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
        
        // Verificar se ainda não tem entrada no dia do lembrete
        final reminderDateOnly = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
        if (!HiveService.hasEntryForDate(reminderDateOnly)) {
          print('[NotificationService] Scheduling reminder for: $reminderDate (day ${dayOffset})');
          await _scheduleReminderNotificationForDate(reminderDate, dayOffset);
        }
      }
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

  // Agendar notificação para uma data específica (sem recorrência automática)
  // Usa um ID único baseado no dia para permitir cancelamento individual
  static Future<void> _scheduleNotificationForDate(tz.TZDateTime scheduledDate, int dayOffset) async {
    print('[NotificationService] Scheduling notification at: $scheduledDate (day offset: $dayOffset)');
    
    // Usar ID único baseado no dia (0-29 para os próximos 30 dias)
    // ID 0-29 para notificações principais, 100-129 para lembretes
    final notificationId = dayOffset;

    // Obter idioma das configurações para traduções
    final settings = HiveService.getSettings();
    final language = settings.language;
    
    // Traduções baseadas no idioma (fallback para inglês)
    final dailyReminderTitle = _getLocalizedString('dailyReminder', language);
    final dailyReminderDescription = _getLocalizedString('dailyReminderDescription', language);
    final notificationTitle = _getLocalizedString('notificationTitle', language);
    final notificationBody = _getLocalizedString('notificationBody', language);

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      dailyReminderTitle,
      channelDescription: dailyReminderDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    try {
      // Agendar notificação única (sem matchDateTimeComponents)
      await _notifications.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'check_entry_$dayOffset',
      );
      
      print('[NotificationService] Notification scheduled successfully for day $dayOffset');
    } catch (e, stackTrace) {
      print('[NotificationService] ERROR scheduling notification: $e');
      print('[NotificationService] Stack trace: $stackTrace');
    }
  }

  // Agendar notificação de lembrete para uma data específica
  static Future<void> _scheduleReminderNotificationForDate(tz.TZDateTime scheduledDate, int dayOffset) async {
    print('[NotificationService] Scheduling reminder notification at: $scheduledDate (day offset: $dayOffset)');
    
    // Usar ID único baseado no dia + 100 para lembretes (100-129)
    final notificationId = 100 + dayOffset;

    // Obter idioma das configurações para traduções
    final settings = HiveService.getSettings();
    final language = settings.language;
    
    // Traduções baseadas no idioma
    final reminderTitle = _getLocalizedString('reminder', language);
    final reminderDescription = _getLocalizedString('reminderChannelDescription', language);
    final reminderNotificationTitle = _getLocalizedString('haventRecordedToday', language);
    final reminderNotificationBody = _getLocalizedString('captureMomentNow', language);

    final androidDetails = AndroidNotificationDetails(
      'reminder',
      reminderTitle,
      channelDescription: reminderDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        notificationId,
        reminderNotificationTitle,
        reminderNotificationBody,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder_$dayOffset',
      );
      
      print('[NotificationService] Reminder notification scheduled successfully for day $dayOffset');
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
    
    // Obter idioma das configurações para traduções
    final settings = HiveService.getSettings();
    final language = settings.language;
    
    final dailyReminderTitle = _getLocalizedString('dailyReminder', language);
    final dailyReminderDescription = _getLocalizedString('dailyReminderDescription', language);
    final testNotificationTitle = _getLocalizedString('testNotificationTitle', language);
    final testNotificationBody = _getLocalizedString('testNotificationBody', language);
    
    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      dailyReminderTitle,
      channelDescription: dailyReminderDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(
        999, // ID único para notificação de teste
        testNotificationTitle,
        testNotificationBody,
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

  // Helper para obter strings traduzidas baseado no idioma
  static String _getLocalizedString(String key, String language) {
    // Mapa de traduções para cada idioma
    final translations = {
      'en': {
        'dailyReminder': 'Daily Reminder',
        'dailyReminderDescription': 'Notifications to remind you to record your moment of the day',
        'notificationTitle': 'Retro1',
        'notificationBody': "Don't forget to record your moment today!",
        'reminder': 'Reminder',
        'reminderChannelDescription': 'Additional reminders',
        'haventRecordedToday': "Haven't recorded today?",
        'captureMomentNow': 'How about capturing a moment now?',
        'testNotificationTitle': 'Test Notification',
        'testNotificationBody': 'This is a test notification. If you\'re seeing this, notifications are working!',
      },
      'pt': {
        'dailyReminder': 'Lembrete Diário',
        'dailyReminderDescription': 'Notificações para lembrar de registrar seu segundo do dia',
        'notificationTitle': 'Retro1',
        'notificationBody': 'Não se esqueça de registrar seu momento de hoje!',
        'reminder': 'Lembrete',
        'reminderChannelDescription': 'Lembretes adicionais',
        'haventRecordedToday': 'Ainda não registrou hoje?',
        'captureMomentNow': 'Que tal capturar um momento agora?',
        'testNotificationTitle': 'Teste de Notificação',
        'testNotificationBody': 'Esta é uma notificação de teste. Se você está vendo isso, as notificações estão funcionando!',
      },
      'es': {
        'dailyReminder': 'Recordatorio Diario',
        'dailyReminderDescription': 'Notificaciones para recordarte de registrar tu momento del día',
        'notificationTitle': 'Retro1',
        'notificationBody': '¡No olvides registrar tu momento de hoy!',
        'reminder': 'Recordatorio',
        'reminderChannelDescription': 'Recordatorios adicionales',
        'haventRecordedToday': '¿Aún no has registrado hoy?',
        'captureMomentNow': '¿Qué tal capturar un momento ahora?',
        'testNotificationTitle': 'Notificación de Prueba',
        'testNotificationBody': 'Esta es una notificación de prueba. Si estás viendo esto, ¡las notificaciones están funcionando!',
      },
      'fr': {
        'dailyReminder': 'Rappel Quotidien',
        'dailyReminderDescription': 'Notifications pour vous rappeler d\'enregistrer votre moment de la journée',
        'notificationTitle': 'Retro1',
        'notificationBody': 'N\'oubliez pas d\'enregistrer votre moment d\'aujourd\'hui !',
        'reminder': 'Rappel',
        'reminderChannelDescription': 'Rappels supplémentaires',
        'haventRecordedToday': 'Vous n\'avez pas encore enregistré aujourd\'hui ?',
        'captureMomentNow': 'Et si vous capturiez un moment maintenant ?',
        'testNotificationTitle': 'Notification de Test',
        'testNotificationBody': 'Ceci est une notification de test. Si vous voyez ceci, les notifications fonctionnent !',
      },
      'de': {
        'dailyReminder': 'Tägliche Erinnerung',
        'dailyReminderDescription': 'Benachrichtigungen, um Sie daran zu erinnern, Ihren Moment des Tages aufzunehmen',
        'notificationTitle': 'Retro1',
        'notificationBody': 'Vergessen Sie nicht, Ihren Moment von heute aufzunehmen!',
        'reminder': 'Erinnerung',
        'reminderChannelDescription': 'Zusätzliche Erinnerungen',
        'haventRecordedToday': 'Haben Sie heute noch nicht aufgenommen?',
        'captureMomentNow': 'Wie wäre es, jetzt einen Moment einzufangen?',
        'testNotificationTitle': 'Testbenachrichtigung',
        'testNotificationBody': 'Dies ist eine Testbenachrichtigung. Wenn Sie dies sehen, funktionieren die Benachrichtigungen!',
      },
      'it': {
        'dailyReminder': 'Promemoria Giornaliero',
        'dailyReminderDescription': 'Notifiche per ricordarti di registrare il tuo momento della giornata',
        'notificationTitle': 'Retro1',
        'notificationBody': 'Non dimenticare di registrare il tuo momento di oggi!',
        'reminder': 'Promemoria',
        'reminderChannelDescription': 'Promemoria aggiuntivi',
        'haventRecordedToday': 'Non hai ancora registrato oggi?',
        'captureMomentNow': 'Che ne dici di catturare un momento ora?',
        'testNotificationTitle': 'Notifica di Test',
        'testNotificationBody': 'Questa è una notifica di test. Se stai vedendo questo, le notifiche funzionano!',
      },
    };

    // Retornar tradução para o idioma ou fallback para inglês
    return translations[language]?[key] ?? translations['en']![key]!;
  }
}

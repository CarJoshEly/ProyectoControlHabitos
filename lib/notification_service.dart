import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============ INICIALIZACIÓN ============
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final String timeZoneName = _getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✅ Zona horaria configurada: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ Error con zona horaria $timeZoneName, usando UTC');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();

    _initialized = true;
    debugPrint('✅ NotificationService inicializado');
  }

  String _getLocalTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inHours;

    final Map<int, String> timezoneMap = {
      -12: 'Etc/GMT+12',
      -11: 'Pacific/Midway',
      -10: 'Pacific/Honolulu',
      -9: 'America/Anchorage',
      -8: 'America/Los_Angeles',
      -7: 'America/Denver',
      -6: 'America/Tegucigalpa',
      -5: 'America/Bogota',
      -4: 'America/Caracas',
      -3: 'America/Sao_Paulo',
      -2: 'Atlantic/South_Georgia',
      -1: 'Atlantic/Azores',
      0: 'UTC',
      1: 'Europe/Paris',
      2: 'Europe/Berlin',
      3: 'Europe/Moscow',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Singapore',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
      11: 'Pacific/Noumea',
      12: 'Pacific/Auckland',
    };

    return timezoneMap[offset] ?? 'UTC';
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
      'habits_reminder_channel',
      'Recordatorios de Hábitos',
      description: 'Notificaciones para recordar tus hábitos diarios',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'habits_alarm_channel',
      'Alarmas de Hábitos',
      description: 'Alarmas para hábitos importantes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);

    debugPrint('✅ Canales de notificaciones creados');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.payload}');
  }

  // ============ PERMISOS ============
  Future<bool> requestPermissions() async {
    bool granted = true;

    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      debugPrint('📱 Permiso notificación: $status');
      granted = status.isGranted;
    }

    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        debugPrint('⏰ Permiso alarma exacta: $status');
      }

      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
        debugPrint('🔔 Permiso system alert window solicitado');
      }
    }

    if (granted) {
      debugPrint('✅ Permisos concedidos');
    } else {
      debugPrint('❌ Permisos denegados');
    }

    return granted;
  }

  // Se llama con delay desde main para no reiniciar la sesión de Firebase
  Future<void> requestBatteryOptimizationPermission() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
      debugPrint('🔋 Permiso optimización de batería solicitado');
    }
  }

  // ============ NOTIFICACIÓN DE PRUEBA ============
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'habits_reminder_channel',
      'Recordatorios de Hábitos',
      channelDescription: 'Notificaciones para recordar tus hábitos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🎉 ¡Notificaciones Activas!',
      'Las notificaciones están funcionando correctamente.',
      details,
    );
    debugPrint('📬 Notificación de prueba enviada');
  }

  // ============ PROGRAMAR RECORDATORIO ============
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
    required String frequency,
    String reminderType = 'notification',
  }) async {
    if (!_initialized) await initialize();
    if (!await _areNotificationsEnabledInPrefs()) {
      debugPrint('⚠️ Notificaciones desactivadas - no se programó: $habitName');
      return;
    }

    final notificationId = _generateNotificationId(habitId);
    await cancelHabitReminder(habitId);
    await _saveHabitNotificationId(habitId, notificationId);

    final scheduledTime = _nextInstanceOfTime(hour, minute);

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('⏰ PROGRAMANDO NOTIFICACIÓN:');
    debugPrint('   Hábito: $habitName');
    debugPrint(
        '   Hora: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    debugPrint('   Tipo: $reminderType');
    debugPrint('   Programada para: $scheduledTime');
    debugPrint('   ID: $notificationId');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final AndroidNotificationDetails androidDetails;

    if (reminderType == 'alarm') {
      androidDetails = AndroidNotificationDetails(
        'habits_alarm_channel',
        'Alarmas de Hábitos',
        channelDescription: 'Alarmas para hábitos importantes',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: false,
        additionalFlags: Int32List.fromList([4, 128]),
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'habits_reminder_channel',
        'Recordatorios de Hábitos',
        channelDescription: 'Recordatorios para completar tus hábitos',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: false,
      );
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    DateTimeComponents? matchComponents;
    switch (frequency.toLowerCase()) {
      case 'diario':
      case 'daily':
        matchComponents = DateTimeComponents.time;
        break;
      case 'semanal':
      case 'weekly':
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case 'mensual':
      case 'monthly':
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      default:
        matchComponents = DateTimeComponents.time;
    }

    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (!exactAlarmStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    try {
      await _notifications.zonedSchedule(
        notificationId,
        reminderType == 'alarm' ? '⏰ ¡Alarma!' : '🔔 ¡Recordatorio!',
        habitName,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
        payload: habitId,
      );

      debugPrint('✅ Recordatorio programado exitosamente');
    } catch (e) {
      debugPrint('❌ Error programando notificación: $e');
    }
  }

  // ============ CANCELAR RECORDATORIO ============
  Future<void> cancelHabitReminder(String habitId) async {
    final notificationId = await _getHabitNotificationId(habitId);

    if (notificationId != null) {
      await _notifications.cancel(notificationId);
      await _removeHabitNotificationId(habitId);
      debugPrint('🗑️ Recordatorio cancelado para: $habitId');
    }
  }

  // ============ HELPERS ============
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  int _generateNotificationId(String habitId) {
    return habitId.hashCode.abs() % 2147483647;
  }

  Future<void> _saveHabitNotificationId(
      String habitId, int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_$habitId', notificationId);
  }

  Future<int?> _getHabitNotificationId(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_$habitId');
  }

  Future<void> _removeHabitNotificationId(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_$habitId');
  }

  // ============ UTILIDADES ============
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ Todas las notificaciones canceladas');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> _areNotificationsEnabledInPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? true;
  }
}
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Inicializar timezone
    tz_data.initializeTimeZones();

    // Obtener zona horaria local basada en el offset del dispositivo
    final String timeZoneName = _getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✅ Zona horaria configurada: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ Error con zona horaria $timeZoneName, usando UTC');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Configuración Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración iOS
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

    // Crear canal de notificaciones para Android
    await _createNotificationChannel();

    _initialized = true;
    debugPrint('✅ NotificationService inicializado');
  }

  // Obtener zona horaria basada en el offset del dispositivo
  String _getLocalTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inHours;

    // Mapa de offsets a zonas horarias comunes
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

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'habits_reminder_channel',
      'Recordatorios de Hábitos',
      description: 'Notificaciones para recordar tus hábitos diarios',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ Canal de notificaciones creado');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.payload}');
  }

  // ============ PERMISOS ============
  Future<bool> requestPermissions() async {
    bool granted = true;

    // Permiso de notificaciones
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      debugPrint('📱 Permiso notificación: $status');
      granted = status.isGranted;
    }

    // Permiso de alarmas exactas (Android 12+)
    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        debugPrint('⏰ Permiso alarma exacta: $status');
      }
    }

    if (granted) {
      debugPrint('✅ Permisos de notificación concedidos');
    } else {
      debugPrint('❌ Permisos de notificación denegados');
    }

    return granted;
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

  // ============ PROGRAMAR RECORDATORIO DE HÁBITO (5 MINUTOS ANTES) ============
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
    required String frequency,
  }) async {
    if (!_initialized) await initialize();
    if (!await _areNotificationsEnabledInPrefs()) {
      debugPrint('⚠️ Notificaciones desactivadas - no se programó: $habitName');
      return;
    }

    // Generar ID numérico único
    final notificationId = _generateNotificationId(habitId);

    // Cancelar notificación anterior si existe
    await cancelHabitReminder(habitId);

    // Guardar relación habitId -> notificationId
    await _saveHabitNotificationId(habitId, notificationId);

    // Usar la hora exacta del hábito (sin modificar)
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('⏰ PROGRAMANDO NOTIFICACIÓN:');
    debugPrint('   Hábito: $habitName');
    debugPrint(
        '   Hora: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    debugPrint('   Programada para: $scheduledTime');
    debugPrint('   ID: $notificationId');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    const androidDetails = AndroidNotificationDetails(
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
      fullScreenIntent: true,
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

    // Determinar repetición según frecuencia
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
      default:
        matchComponents = DateTimeComponents.time;
    }

    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (!exactAlarmStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
        debugPrint('⚠️ Permiso de alarma exacta no concedido');
      }
    }

    try {
      await _notifications.zonedSchedule(
        notificationId,
        '⏰ ¡Recordatorio!',
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

    // Si ya pasó la hora hoy, programar para mañana
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

  // Agregar este método (después de areNotificationsEnabled)
  Future<bool> _areNotificationsEnabledInPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? true;
  }
}

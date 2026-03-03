import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'weather_prediction_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  // NEW: Check and request exact alarm permission for Android 12+
  Future<bool> _canScheduleExactAlarms() async {
    if (Theme.of(buildContext!).platform == TargetPlatform.android) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final canSchedule =
            await androidImplementation.canScheduleExactNotifications();
        return canSchedule ?? false;
      }
    }
    return true; // iOS doesn't need this permission
  }

  // NEW: Request exact alarm permission
  Future<bool> requestExactAlarmPermission() async {
    if (Theme.of(buildContext!).platform == TargetPlatform.android) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.requestExactAlarmsPermission() ??
            false;
      }
    }
    return true;
  }

  // Helper to get context (set this from your main app)
  static BuildContext? buildContext;

  Future<void> scheduleWeatherNotification({
    required String tripId,
    required String destination,
    required DateTime tripDate,
    required double lat,
    required double lng,
  }) async {
    // Check permission first
    final hasPermission = await _canScheduleExactAlarms();
    if (!hasPermission) {
      print('⚠️ Exact alarm permission not granted. Using inexact scheduling.');
      // Continue with inexact scheduling instead of throwing error
    }

    // Schedule notification 1 day before trip at 9 AM
    final notificationDate = DateTime(
      tripDate.year,
      tripDate.month,
      tripDate.day - 1,
      9, // 9 AM
    );

    if (notificationDate.isBefore(DateTime.now())) return;

    final weatherService = WeatherPredictionService();
    await weatherService.initialize();

    final weather = await weatherService.predictWeather(
      latitude: lat,
      longitude: lng,
      date: tripDate,
    );

    final isGood = weather['isGoodForTravel'] as bool;
    final condition = weather['condition'] as String;
    final temp = (weather['temperature'] as num).toStringAsFixed(0);

    final title = isGood
        ? '🌤️ Great Weather Tomorrow!'
        : '⚠️ Weather Alert for $destination';

    final body = isGood
        ? 'Tomorrow: $condition, $temp°C. Perfect for your trip to $destination!'
        : 'Tomorrow: $condition, $temp°C. Consider indoor activities in $destination.';

    // FIXED: Use inexact scheduling if permission not available
    final scheduleMode = hasPermission
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notifications.zonedSchedule(
      tripId.hashCode,
      title,
      body,
      tz.TZDateTime.from(notificationDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_weather_channel',
          'Trip Weather Alerts',
          channelDescription: 'Weather notifications before your trips',
          importance: Importance.high,
          priority: Priority.high,
          color: isGood ? const Color(0xFF00DFD8) : Colors.orange,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode, // FIXED: Dynamic schedule mode
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleActivityReminder({
    required String activityName,
    required DateTime activityDate,
    required String location,
  }) async {
    // Schedule notification 2 hours before activity
    final reminderTime = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
      8, // Assume activity at 10 AM, notify 2 hours before
    ).subtract(const Duration(hours: 2));

    if (reminderTime.isBefore(DateTime.now())) return;

    final notificationId =
        activityName.hashCode + activityDate.millisecondsSinceEpoch;

    // Check permission
    final hasPermission = await _canScheduleExactAlarms();
    final scheduleMode = hasPermission
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notifications.zonedSchedule(
      notificationId,
      '⏰ Activity Reminder',
      'Your activity "$activityName" at $location starts in 2 hours!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Reminders for your planned activities',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00DFD8),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode, // FIXED: Dynamic schedule mode
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleDailyItineraryReminder({
    required String destination,
    required DateTime date,
    required int activityCount,
  }) async {
    // Schedule notification at 8 AM on the day of activities
    final reminderTime = DateTime(
      date.year,
      date.month,
      date.day,
      8, // 8 AM
    );

    if (reminderTime.isBefore(DateTime.now())) return;

    final notificationId = date.millisecondsSinceEpoch;

    // Check permission
    final hasPermission = await _canScheduleExactAlarms();
    final scheduleMode = hasPermission
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notifications.zonedSchedule(
      notificationId,
      '🌅 Good Morning!',
      'You have $activityCount activities planned today in $destination. Check your itinerary!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_itinerary',
          'Daily Itinerary',
          channelDescription: 'Daily reminders for your itinerary',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00DFD8),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode, // FIXED: Dynamic schedule mode
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    bool isSuccess = true,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate_channel',
          'Immediate Notifications',
          channelDescription: 'Immediate app notifications',
          importance: Importance.high,
          priority: Priority.high,
          color: isSuccess ? const Color(0xFF00DFD8) : Colors.orange,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelTripNotifications(String tripId) async {
    await _notifications.cancel(tripId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Version 17 uses a normal positional argument here
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> schedulePreTaskNudge(
    Task task,
    DateTime startTime,
    String aiCondition,
  ) async {
    final reminderTime = startTime.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) return;

    int notificationId = startTime.millisecondsSinceEpoch % 10000;

    // Version 17 uses positional for the first 5, but NAMED for androidScheduleMode
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Upcoming: ${task.description}',
      'Starts in 15 mins. $aiCondition',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pre_task_channel',
          'Pre-Task Reminders',
          channelDescription: 'Gentle nudges before tasks begin',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // <--- NAMED ARGUMENT
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print("🔔 Scheduled 15-min nudge for ${task.description} at $reminderTime");
  }
}

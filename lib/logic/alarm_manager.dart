import 'package:alarm/alarm.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import '../data/hive_service.dart';
import '../data/models/task_model.dart';
import '../main.dart'; // Ensure this points correctly to where your global alarm listener is
import '../ui/alarm_page.dart';
import 'ai_engine.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterTts flutterTts = FlutterTts();
  final HiveService _hiveService = HiveService();
  final AIEngine _aiEngine = AIEngine();

  bool _isInitialized = false;

  int? currentlyRingingAlarmId;
  String? currentlyRingingAlarmTitle;

  Future<void> init() async {
    if (_isInitialized) return;
    await Alarm.init();
    await _initTts();

    // 🚨 FIX: Removed Alarm.ringStream.stream.listen from here!
    // It is already being handled globally in main.dart, which prevents the
    // "Bad state: Stream has already been listened to" crash.

    _isInitialized = true;
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  // --- SET ACTIVE ALARM DATA (Called from main.dart) ---
  // This allows the AlarmService to know what to speak when the user clicks "Stop"
  void setRingingAlarmData(int id, String title) {
    currentlyRingingAlarmId = id;
    currentlyRingingAlarmTitle = title;
  }

  // --- SCHEDULING METHODS ---

  Future<void> setWakeUpAlarm(DateTime wakeUpTime) async {
    final alarmSettings = AlarmSettings(
      id: 1, // ID 1 is reserved for the Morning Briefing
      dateTime: wakeUpTime,
      assetAudioPath: 'assets/alarm.wav',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: const VolumeSettings.fixed(volume: 0.8),
      notificationSettings: const NotificationSettings(
        title: 'Good Morning!',
        body: 'Tap to hear your AI daily briefing.',
        stopButton: 'Stop',
      ),
    );
    await Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> setTaskEndTimeAlarm(
    DateTime time,
    int id,
    String description,
  ) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: time,
      assetAudioPath:
          'assets/alarm2.wav', // A different sound for task completion
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: const VolumeSettings.fixed(volume: 0.8),
      notificationSettings: NotificationSettings(
        title: 'Task Completed?',
        body: 'Did you finish: $description?',
        stopButton: 'Stop',
      ),
    );
    await Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> scheduleStartAndEndAlarms(Task task) async {
    // 🔥 CRITICAL FIX: Align IDs with PlanProvider so cancellations work perfectly!
    // We ensure the ID isn't 0 or 1 (WakeUp) just to be absolutely safe.
    final int startId = task.alarmId < 10 ? task.alarmId + 10 : task.alarmId;
    final int endId = startId + 1;

    // 1. Schedule the Start Alarm
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: startId,
        dateTime: task.scheduledTime,
        assetAudioPath: 'assets/alarm.wav',
        loopAudio: true,
        vibrate: true,
        volumeSettings: const VolumeSettings.fixed(volume: 0.8),
        notificationSettings: NotificationSettings(
          title: 'Task Starting!',
          body: 'Time to begin: ${task.description}',
          stopButton: 'Start',
        ),
      ),
    );

    // 2. Schedule the End Alarm (🔥 FIX: Uses explicit endTime!)
    final DateTime endTime =
        task.endTime ?? task.scheduledTime.add(const Duration(hours: 1));
    await setTaskEndTimeAlarm(endTime, endId, task.description);
  }

  // --- 🔥 NEW: GHOST ALARM CLEANUP ---

  /// Instantly cancels a specific scheduled alarm to prevent it from ringing
  /// after a task is completed early, skipped, or deleted.
  Future<void> cancelAlarm(int id) async {
    try {
      await Alarm.stop(id);
    } catch (e) {
      debugPrint("Alarm Service: Could not cancel alarm ID $id. $e");
    }
  }

  // --- EVENT HANDLING ---

  Future<void> stopActiveAlarmAndSpeak(double lat, double lon) async {
    if (currentlyRingingAlarmId == null) return;

    int idToStop = currentlyRingingAlarmId!;
    String title = currentlyRingingAlarmTitle ?? "";

    await Alarm.stop(idToStop);

    // AI Logic for text-to-speech
    if (idToStop == 1) {
      final tasks = _hiveService.getTasksForDay(DateTime.now());
      String briefing = await _aiEngine.generateMorningBriefing(
        tasks,
        lat,
        lon,
      );
      await flutterTts.speak(briefing);
    } else if (title == 'Task Starting!') {
      await flutterTts.speak("It is time to begin your task. Stay focused.");
    } else {
      final tasks = _hiveService.getTasksForDay(DateTime.now());
      int remaining = tasks.where((t) => t.isSuccessful == null).length;
      String speech =
          "Activity period complete. You have $remaining tasks left.";
      await flutterTts.speak(speech);
    }

    // Reset after speaking
    currentlyRingingAlarmId = null;
    currentlyRingingAlarmTitle = null;
  }
}

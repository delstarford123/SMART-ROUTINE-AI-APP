import 'package:flutter/foundation.dart';
import '../data/models/task_model.dart';
import '../data/hive_service.dart';
import 'ai_engine.dart';
import 'notification_service.dart';
import 'alarm_manager.dart';

class PlanProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final AIEngine _aiEngine = AIEngine();
  final AlarmService _alarmService = AlarmService();
  final NotificationService _notificationService =
      NotificationService(); // Explicit instantiation

  List<Task> _todaysTasks = [];
  bool _isLoading = false;
  DateTime _currentDate = DateTime.now();

  List<Task> get todaysTasks => _todaysTasks;
  bool get isLoading => _isLoading;
  DateTime get currentDate => _currentDate;

  // Load tasks for a specific date
  void loadTasksForDate(DateTime date) {
    _currentDate = date;
    _todaysTasks = _hiveService.getTasksForDay(date);
    notifyListeners();
  }

  // Add a task and immediately get AI feedback
  Future<void> addTaskWithAnalysis(Task task, double lat, double lon) async {
    _setLoading(true);

    try {
      // 1. AI Prediction
      String warning = await _aiEngine.analyzeTask(task, lat, lon);
      task.aiWarning = warning;

      // 2. Save it to local storage
      await _hiveService.addTask(task);

      // 3. Silent Notification (15 mins before)
      await _notificationService.schedulePreTaskNudge(
        task,
        task.scheduledTime,
        warning,
      );

      // 4. Loud Alarms (Start)
      await _alarmService.scheduleStartAndEndAlarms(task);

      // 5. Loud Alarm (End) - If an end time was provided
      if (task.endTime != null) {
        await _alarmService.setTaskEndTimeAlarm(
          task.endTime!,
          task.alarmId + 2, // Offset by 2 to prevent ID collision
          task.description,
        );
      }

      // 6. Refresh UI
      loadTasksForDate(task.scheduledTime);
    } catch (e) {
      debugPrint("❌ Error adding task: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Update success/failure status safely using the Hive Key
  Future<void> updateTaskStatus(int index, bool success) async {
    // Safety check
    if (index < 0 || index >= _todaysTasks.length) return;

    try {
      final task = _todaysTasks[index];

      // Update database
      await _hiveService.updateTaskStatus(task.key, success);

      // 🔥 CRITICAL UX FIX: Prevent "Ghost Alarms"
      // If a task is marked DONE or KILLED early, cancel the upcoming alarms!
      _cancelScheduledEventsForTask(task);

      loadTasksForDate(_currentDate);
    } catch (e) {
      debugPrint("❌ Error updating task status: $e");
    }
  }

  // Delete single task and refresh the screen
  Future<void> removeTask(Task task) async {
    try {
      // 🔥 CRITICAL UX FIX: Clean up OS-level scheduling before deleting
      _cancelScheduledEventsForTask(task);

      // Delete from database
      await _hiveService.deleteTask(task.key);
      loadTasksForDate(_currentDate);
    } catch (e) {
      debugPrint("❌ Error removing task: $e");
    }
  }

  // Clear everything and refresh
  Future<void> nukeHistory() async {
    try {
      _setLoading(true);

      // Cancel any upcoming alarms for today's visible list before nuking
      for (var task in _todaysTasks) {
        _cancelScheduledEventsForTask(task);
      }

      await _hiveService.clearAllHistory();
      _todaysTasks.clear();
      loadTasksForDate(DateTime.now()); // Reset view to today
    } catch (e) {
      debugPrint("❌ Error nuking history: $e");
    } finally {
      _setLoading(false);
    }
  }

  // --- PRIVATE UTILITY METHODS ---

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Cancels all OS-level scheduled events (alarms & notifications) for a specific task.
  void _cancelScheduledEventsForTask(Task task) {
    try {
      // Cancel the Start Alarm
      _alarmService.cancelAlarm(task.alarmId);

      // Cancel End Alarms (Assuming your alarm service uses +1 and +2 offsets)
      _alarmService.cancelAlarm(task.alarmId + 1);
      _alarmService.cancelAlarm(task.alarmId + 2);

      // Note: If you add a cancel method to NotificationService in the future, call it here:
      // _notificationService.cancelNotification(task.alarmId);
    } catch (e) {
      debugPrint("⚠️ Could not cancel some alarms for task: $e");
    }
  }
}

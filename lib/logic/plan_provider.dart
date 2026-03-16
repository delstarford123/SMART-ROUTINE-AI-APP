import 'package:flutter/foundation.dart';
import '../data/models/task_model.dart';
import '../data/hive_service.dart';
import 'ai_engine.dart';
import 'notification_service.dart';
import 'alarm_manager.dart'; // FIX: Imported the alarm manager for dual alarms

class PlanProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final AIEngine _aiEngine = AIEngine();

  List<Task> _todaysTasks = [];
  bool _isLoading = false;

  // Track the exact date the user is viewing
  DateTime _currentDate = DateTime.now();

  List<Task> get todaysTasks => _todaysTasks;
  bool get isLoading => _isLoading;
  DateTime get currentDate => _currentDate;

  // Load tasks for a specific date
  void loadTasksForDate(DateTime date) {
    _currentDate = date; // Remember which day we are looking at
    _todaysTasks = _hiveService.getTasksForDay(date);
    notifyListeners();
  }

  // Add a task and immediately get AI feedback
  Future<void> addTaskWithAnalysis(Task task, double lat, double lon) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ask the local AI model for a prediction
      String warning = await _aiEngine.analyzeTask(task, lat, lon);
      task.aiWarning = warning;

      // 2. Save it to local storage
      await _hiveService.addTask(task);

      // 3. Schedule the 15-minute silent nudge!
      await NotificationService().schedulePreTaskNudge(
        task,
        task.scheduledTime,
        warning,
      );

      // 4. NEW: Schedule the dual loud alarms (Start and End of task)
      await AlarmService().scheduleStartAndEndAlarms(task);

      // 5. Refresh the list for the specific day the task was scheduled
      loadTasksForDate(task.scheduledTime);
    } catch (e) {
      debugPrint("❌ Error adding task: $e");
    } finally {
      // The 'finally' block guarantees the loading spinner ALWAYS disappears
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update success/failure status
  Future<void> updateTaskStatus(int index, bool success) async {
    try {
      await _hiveService.updateTaskStatus(index, success);

      // Reload the list using the date the user is currently viewing
      loadTasksForDate(_currentDate);
    } catch (e) {
      debugPrint("❌ Error updating task status: $e");
    }
  }

  // ==========================================
  // 🛡️ NEW PRIVACY & MANAGEMENT FEATURES 🛡️
  // ==========================================

  // Delete single task and refresh the screen
  Future<void> removeTask(Task task) async {
    await _hiveService.deleteTask(task.key);
    loadTasksForDate(_currentDate); // Refreshes the UI instantly
  }

  // Clear everything and refresh
  Future<void> nukeHistory() async {
    await _hiveService.clearAllHistory();
    _todaysTasks.clear();
    notifyListeners();
  }
}

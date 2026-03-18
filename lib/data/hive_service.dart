import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task_model.dart';
import 'models/journal_model.dart'; // 🔥 NEW: Imported Journal Model
import 'models/goal_model.dart'; // 🔥 NEW: Imported Goal Model
import '../core/constants.dart';

class HiveService {
  // Use a getter to ensure the box is always open and accessible
  Box<Task> get _taskBox => Hive.box<Task>(AppConstants.taskBoxName);
  Box get _settingsBox => Hive.box('settings');

  static Future<void> init() async {
    await Hive.initFlutter();

    // 1. Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    // 🔥 NEW: Register Goal and Journal Adapters
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GoalAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }

    // 2. Open necessary boxes
    await Hive.openBox<Task>(AppConstants.taskBoxName);
    await Hive.openBox('settings'); // Box for AI voice and wake-up time

    // 🔥 NEW: Open the Goal and Journal boxes
    await Hive.openBox<Goal>('goalsBox');
    await Hive.openBox<JournalEntry>('journalBox');
  }

  // --- TASK MANAGEMENT ---

  /// Save a new task
  Future<void> addTask(Task task) async {
    await _taskBox.add(task);
  }

  /// Get all tasks for a specific day
  List<Task> getTasksForDay(DateTime date) {
    return _taskBox.values.where((task) {
      return task.scheduledTime.year == date.year &&
          task.scheduledTime.month == date.month &&
          task.scheduledTime.day == date.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Update task status using Hive key
  Future<void> updateTaskStatus(dynamic key, bool success) async {
    final task = _taskBox.get(key);
    if (task != null) {
      task.isSuccessful = success;
      await task.save();
    }
  }

  /// Get historical data for AI analytics
  List<Task> getTaskHistory() {
    return _taskBox.values.toList();
  }

  // --- SETTINGS MANAGEMENT ---

  /// Save the selected AI voice (stored as a Map)
  Future<void> saveVoice(Map<String, String> voice) async {
    await _settingsBox.put('ai_voice', voice);
  }

  /// Retrieve the saved voice
  Map? getSavedVoice() {
    return _settingsBox.get('ai_voice');
  }

  /// Save wake-up time by breaking it into integers
  Future<void> saveWakeupTime(TimeOfDay time) async {
    await _settingsBox.put('wakeup_hour', time.hour);
    await _settingsBox.put('wakeup_minute', time.minute);
  }

  /// Reconstruct TimeOfDay from saved integers
  TimeOfDay? getWakeupTime() {
    final int? hour = _settingsBox.get('wakeup_hour');
    final int? minute = _settingsBox.get('wakeup_minute');

    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // --- PRIVACY & CLEANUP ---

  /// Delete a specific task using its unique Hive key
  Future<void> deleteTask(dynamic key) async {
    await _taskBox.delete(key);
  }

  /// Wipe the entire database clean
  Future<void> clearAllHistory() async {
    await _taskBox.clear();
    // Optional: await _settingsBox.clear(); // Uncomment if you want to reset settings too
  }

  // --- WAKE-UP PROTOCOL SETTINGS ---
  Future<void> saveWakeupPhrase(String phrase) async {
    var box = Hive.box('settings'); // Ensure you have a settings box opened
    await box.put('wakeupPhrase', phrase.toLowerCase());
  }

  String getWakeupPhrase() {
    var box = Hive.box('settings');
    return box.get('wakeupPhrase', defaultValue: 'thank you smart');
  }

  Future<void> saveStrictness(double value) async {
    var box = Hive.box('settings');
    await box.put('strictness', value);
  }

  double getStrictness() {
    var box = Hive.box('settings');
    return box.get('strictness', defaultValue: 7.5);
  }

  // --- USER PROFILE SETTINGS ---
  Future<void> saveUserName(String name) async {
    var box = Hive.box('settings');
    await box.put('userName', name);
  }

  String getUserName() {
    var box = Hive.box('settings');
    return box.get('userName', defaultValue: 'Friend'); // Default fallback
  }
}

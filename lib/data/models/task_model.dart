import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  DateTime scheduledTime; // Start Time

  @HiveField(2)
  bool? isSuccessful; // null: pending, true: success, false: failed

  @HiveField(3)
  String? aiWarning;

  @HiveField(4)
  DateTime createdAt;

  // 🔥 CRITICAL FIX: Added endTime so tasks aren't forced into 1-hour blocks
  @HiveField(5)
  DateTime? endTime;

  Task({
    required this.description,
    required this.scheduledTime,
    this.isSuccessful,
    this.aiWarning,
    this.endTime, // Make sure this is here!
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // --- PROFESSIONAL ADDITIONS ---

  /// Helper to check if a task is overdue
  bool get isOverdue =>
      scheduledTime.isBefore(DateTime.now()) && isSuccessful == null;

  /// Helper to get a unique ID for the alarm manager
  /// Uses seconds since epoch to guarantee daily recurring tasks don't collide
  int get alarmId => (scheduledTime.millisecondsSinceEpoch ~/ 1000) % 100000;

  /// Utility to copy a task with changes (Useful for state management)
  Task copyWith({
    String? description,
    DateTime? scheduledTime,
    DateTime? endTime, // Added to copyWith
    bool? isSuccessful,
    String? aiWarning,
  }) {
    return Task(
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      endTime: endTime ?? this.endTime,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      aiWarning: aiWarning ?? this.aiWarning,
      createdAt: this.createdAt, // Preserve original creation time
    );
  }
}

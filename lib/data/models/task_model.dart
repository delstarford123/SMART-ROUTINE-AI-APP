import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  DateTime scheduledTime;

  @HiveField(2)
  bool? isSuccessful; // null: pending, true: success, false: failed

  @HiveField(3)
  String? aiWarning;

  @HiveField(4)
  DateTime createdAt;

  Task({
    required this.description,
    required this.scheduledTime,
    this.isSuccessful,
    this.aiWarning,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // --- PROFESSIONAL ADDITIONS ---

  /// Helper to check if a task is overdue
  bool get isOverdue =>
      scheduledTime.isBefore(DateTime.now()) && isSuccessful == null;

  /// Helper to get a unique ID for the alarm manager
  /// (Milliseconds since epoch shortened to fit into an Int32)
  int get alarmId => scheduledTime.millisecondsSinceEpoch % 100000;

  /// Utility to copy a task with changes (Useful for state management)
  Task copyWith({
    String? description,
    DateTime? scheduledTime,
    bool? isSuccessful,
    String? aiWarning,
  }) {
    return Task(
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      aiWarning: aiWarning ?? this.aiWarning,
      createdAt: this.createdAt,
    );
  }
}

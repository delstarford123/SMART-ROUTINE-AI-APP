import 'package:hive/hive.dart';

part 'goal_model.g.dart'; // Run: flutter packages pub run build_runner build

@HiveType(typeId: 2)
class Goal extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime deadline;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  int iconCode;

  @HiveField(5)
  bool isCompleted;

  Goal({
    required this.title,
    required this.description,
    required this.deadline,
    required this.colorValue,
    required this.iconCode,
    this.isCompleted = false,
  });
}

import 'package:hive/hive.dart';

part 'journal_model.g.dart'; // Run: flutter packages pub run build_runner build

@HiveType(typeId: 3)
class JournalEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String biggestWin;

  @HiveField(2)
  String distraction;

  @HiveField(3)
  String tomorrowFrog;

  JournalEntry({
    required this.date,
    required this.biggestWin,
    required this.distraction,
    required this.tomorrowFrog,
  });
}

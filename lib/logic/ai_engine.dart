import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/task_model.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/network_info.dart';
import 'calendar_service.dart';
import '../data/hive_service.dart';
import '../data/models/goal_model.dart';

class AIEngine {
  final ApiClient _apiClient = ApiClient();
  Interpreter? _interpreter;

  Future<void> _initModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.tfliteModelPath);
      debugPrint("✅ Local AI Model Loaded.");
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
    }
  }

  int _categorizeTask(String description) {
    final lowerDesc = description.toLowerCase();
    if (RegExp(r'gym|run|workout|sport|exercise').hasMatch(lowerDesc)) return 0;
    if (RegExp(r'code|study|work|read|focus|meeting|class').hasMatch(lowerDesc))
      return 1;
    return 2; // Chores/Other
  }

  /// Turns coordinates into a City Name for a personal touch
  Future<String> _getCityName(double lat, double lon) async {
    bool hasInternet = await NetworkInfo.isConnected;
    if (!hasInternet) return "your area";

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? "your area";
      }
    } catch (_) {}
    return "your location";
  }

  /// CORE PREDICTION: Used when adding a new task
  Future<String> analyzeTask(Task task, double lat, double lon) async {
    await _initModel();
    if (_interpreter == null) return "AI Analysis Offline.";

    double temp = 25.0;
    int isRaining = 0;

    bool hasInternet = await NetworkInfo.isConnected;

    if (hasInternet) {
      try {
        final weatherData = await _apiClient.fetchWeather(lat, lon);
        var current = weatherData['current'] ?? weatherData['main'];
        temp = current['temp'].toDouble();
        int weatherId = weatherData['weather']?[0]?['id'] ?? 800;
        if (weatherId >= 500 && weatherId < 600) isRaining = 1;
      } catch (e) {
        debugPrint("Weather fallback triggered: $e");
      }
    } else {
      debugPrint("📴 OFFLINE: Using default weather for task analysis.");
    }

    int taskType = _categorizeTask(task.description);
    double hour = task.scheduledTime.hour + (task.scheduledTime.minute / 60.0);

    var input = [
      [taskType.toDouble(), hour, temp, isRaining.toDouble()],
    ];
    var output = List.filled(1, 0.0).reshape([1, 1]);

    try {
      _interpreter!.run(input, output);
      double prob = output[0][0];
      int score = (prob * 100).round();

      // 🔥 UPDATED: Highly actionable, professional AI advice
      if (score >= 75) {
        return "High success probability ($score%). Conditions are optimal. Advice: Capitalize on this momentum and execute the task exactly as planned.";
      } else if (score <= 40) {
        return "Low success probability ($score%). Warning: You are likely to face resistance here due to timing or conditions. Advice: Break this task into 10-minute micro-steps, eliminate all digital distractions, and prepare yourself mentally.";
      } else {
        return "Moderate success chance ($score%). The conditions are fair. Advice: Stay disciplined, put your phone out of reach, and push through the initial friction to get it done.";
      }
    } catch (e) {
      return "Analysis unavailable. Advice: Trust your discipline today.";
    }
  }

  /// 🌟 UPGRADED: Personalized & Faith-Based Quotes
  String _getDailyMotivationalQuote(String userName) {
    int weekday = DateTime.now().weekday;
    String nameToUse = userName.isEmpty ? "my friend" : userName;

    switch (weekday) {
      case 1: // Monday
        return "Happy Monday, $nameToUse! Step out with confidence and set the tone for the week. Remember, Jesus Christ got you, and He will always be good.";
      case 2: // Tuesday
        return "Happy Tuesday, $nameToUse! Keep your momentum going strong. No matter the hurdles, Jesus Christ got you, and He will always be good.";
      case 3: // Wednesday
        return "Happy Wednesday, $nameToUse! You are halfway through the week. Keep pushing forward, trusting that Jesus Christ got you, and He will always be good.";
      case 4: // Thursday
        return "Happy Thursday, $nameToUse! Stay focused and finish your tasks with excellence. Be encouraged today; Jesus Christ got you, and He will always be good.";
      case 5: // Friday
        return "Happy Friday, $nameToUse! Finish strong and look back at what you've achieved. Rejoice, because Jesus Christ got you, and He will always be good.";
      case 6: // Saturday
        return "Happy Saturday, $nameToUse! Take time to execute your plans and also find moments of rest. Breathe easy, Jesus Christ got you, and He will always be good.";
      case 7: // Sunday
        return "Happy Sunday, $nameToUse! Reflect, recharge, and prepare your heart and mind. Walk in peace today, knowing Jesus Christ got you, and He will always be good.";
      default:
        return "Have a wonderful day, $nameToUse! Remember, Jesus Christ got you, and He will always be good.";
    }
  }

  /// 🌟 UPGRADED: Personalized Morning Briefing
  Future<String> generateMorningBriefing(
    List<Task> todaysTasks,
    double lat,
    double lon,
  ) async {
    String userName = HiveService().getUserName();
    String dailyMotivation = _getDailyMotivationalQuote(userName);

    final calendarService = CalendarService();
    final calendarEvents = await calendarService.getEventsForDate(
      DateTime.now(),
    );

    if (todaysTasks.isEmpty && calendarEvents.isEmpty) {
      return "Good morning! You have a clear schedule today. $dailyMotivation";
    }

    bool hasInternet = await NetworkInfo.isConnected;

    String cityName = "your area";
    String weatherContext = "the weather is stable";
    double currentTemp = 25.0;
    bool isRaining = false;

    if (hasInternet) {
      cityName = await _getCityName(lat, lon);
      try {
        final weatherData = await _apiClient.fetchWeather(lat, lon);
        var current = weatherData['current'] ?? weatherData['main'];
        currentTemp = current['temp'].toDouble();
        String condition =
            weatherData['weather']?[0]?['description'] ?? "clear skies";
        weatherContext = "${currentTemp.round()} degrees with $condition";
        isRaining = condition.contains('rain');
      } catch (e) {
        debugPrint("Briefing weather error: $e");
      }
    }

    String scheduleSummary = "";
    String firstActivityName = "";
    String firstActivityTime = "";

    if (calendarEvents.isNotEmpty && todaysTasks.isNotEmpty) {
      scheduleSummary =
          "You have ${todaysTasks.length} personal tasks and ${calendarEvents.length} calendar events today. ";
      firstActivityName = todaysTasks.first.description;
      firstActivityTime =
          "${todaysTasks.first.scheduledTime.hour}:${todaysTasks.first.scheduledTime.minute.toString().padLeft(2, '0')}";
    } else if (calendarEvents.isNotEmpty) {
      scheduleSummary =
          "You have ${calendarEvents.length} calendar events today, but no personal tasks scheduled. ";
      firstActivityName = calendarEvents.first.title ?? "an event";
      final startTime = calendarEvents.first.start!;
      firstActivityTime =
          "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}";
    } else {
      scheduleSummary = "You have ${todaysTasks.length} personal tasks today. ";
      firstActivityName = todaysTasks.first.description;
      firstActivityTime =
          "${todaysTasks.first.scheduledTime.hour}:${todaysTasks.first.scheduledTime.minute.toString().padLeft(2, '0')}";
    }

    await _initModel();
    String aiAdvice = "";
    if (_interpreter != null) {
      var input = [
        [
          _categorizeTask(firstActivityName).toDouble(),
          (DateTime.now().hour).toDouble(),
          currentTemp,
          isRaining ? 1.0 : 0.0,
        ],
      ];
      var output = List.filled(1, 0.0).reshape([1, 1]);
      _interpreter!.run(input, output);

      if (output[0][0] < 0.45) {
        aiAdvice =
            "My model suggests this might be a tough start given the conditions, so take your time and pace yourself.";
      } else {
        aiAdvice = "It's a great time to get started.";
      }
    }

    if (hasInternet) {
      return "Good morning! In $cityName, it is currently $weatherContext. "
          "$scheduleSummary "
          "Your first activity is $firstActivityName at $firstActivityTime. "
          "$aiAdvice "
          "$dailyMotivation";
    } else {
      return "Good morning! You are currently offline, but $scheduleSummary "
          "Your first activity is $firstActivityName at $firstActivityTime. "
          "$aiAdvice "
          "$dailyMotivation";
    }
  }

  /// 🌟 UPGRADED: Humanized & Faith-Based Strategy Review
  Future<String> generateWeeklyStrategyReview() async {
    try {
      final box = Hive.box<Task>(AppConstants.taskBoxName);
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      String userName = HiveService().getUserName();
      String nameToUse = userName.isEmpty ? "my friend" : userName;

      final weeklyTasks = box.values.where((t) {
        return t.scheduledTime.isAfter(oneWeekAgo) && t.isSuccessful != null;
      }).toList();

      if (weeklyTasks.isEmpty) {
        return "Good evening, $nameToUse. I noticed you took a break from tracking this week. "
            "Rest is important, but let's pray for a productive week ahead and start fresh tomorrow.";
      }

      int totalPhysical = 0, successPhysical = 0;
      int totalMental = 0, successMental = 0;
      int totalChores = 0, successChores = 0;

      for (var task in weeklyTasks) {
        int category = _categorizeTask(task.description);
        bool success = task.isSuccessful == true;

        if (category == 0) {
          totalPhysical++;
          if (success) successPhysical++;
        } else if (category == 1) {
          totalMental++;
          if (success) successMental++;
        } else {
          totalChores++;
          if (success) successChores++;
        }
      }

      int totalSuccess = successPhysical + successMental + successChores;
      int overallRate = ((totalSuccess / weeklyTasks.length) * 100).round();

      double physicalRate = totalPhysical == 0
          ? 1.0
          : successPhysical / totalPhysical;
      double mentalRate = totalMental == 0 ? 1.0 : successMental / totalMental;
      double choresRate = totalChores == 0 ? 1.0 : successChores / totalChores;

      // 1. Humanized, dynamic greetings
      final List<String> greetings = [
        "Good evening, $nameToUse. It is time for our weekly review. ",
        "Hello $nameToUse. Let's take a moment to reflect on your week. ",
        "Welcome to your Sunday review, $nameToUse. I've been analyzing your progress. ",
      ];
      String intro = greetings[Random().nextInt(greetings.length)];
      intro +=
          "You accomplished $totalSuccess out of ${weeklyTasks.length} tasks, giving you a $overallRate percent success rate. ";

      // 2. Empathetic Analysis
      String analysis = "";
      if (overallRate >= 80) {
        analysis =
            "You had a truly blessed and highly productive week. Your dedication to your goals is inspiring. ";
      } else if (overallRate >= 50) {
        analysis =
            "You did good work this week, but I know you have the potential for even more. Don't be discouraged by the tasks you missed. ";
      } else {
        analysis =
            "It looks like this was a challenging week for you. Please don't be too hard on yourself. Every week is a new opportunity to learn and grow. ";
      }

      // Practical Advice
      String advice = "";
      if (mentalRate <= physicalRate &&
          mentalRate <= choresRate &&
          totalMental > 0 &&
          mentalRate < 0.7) {
        advice =
            "Next week, let's try the Pomodoro technique. Break your deep work into 25-minute sprints to keep your brain fresh. ";
      } else if (physicalRate <= mentalRate &&
          physicalRate <= choresRate &&
          totalPhysical > 0 &&
          physicalRate < 0.7) {
        advice =
            "Next week, try laying out your workout clothes the night before to help with your physical tasks. ";
      } else if (choresRate < 0.7) {
        advice =
            "Try grouping all your chores into one block on Saturday morning to free up the rest of your week. ";
      } else {
        advice =
            "Your current strategy is working perfectly. Keep this exact momentum going into tomorrow. ";
      }

      // 3. Faith-Based Wisdom (Scriptures)
      final List<String> scriptures = [
        "Remember Proverbs 16 verse 3: Commit thy works unto the Lord, and thy thoughts shall be established.",
        "As you prepare for tomorrow, remember Philippians 4 verse 13: I can do all things through Christ which strengtheneth me.",
        "Keep Alma chapter 37 verse 37 in your heart: Counsel with the Lord in all thy doings, and he will direct thee for good.",
        "Take comfort in Isaiah 40 verse 31: But they that wait upon the Lord shall renew their strength.",
        "Remember Doctrine and Covenants section 58 verse 27: Men should be anxiously engaged in a good cause, and do many things of their own free will.",
      ];

      String spiritualWord = scriptures[Random().nextInt(scriptures.length)];

      String outro =
          "$advice $spiritualWord Take time to rest tonight. God bless you, and I will be here to wake you up tomorrow.";

      return intro + analysis + outro;
    } catch (e) {
      debugPrint("Weekly Review Error: $e");
      String userName = HiveService().getUserName();
      return "Good evening, ${userName.isEmpty ? "my friend" : userName}. I couldn't access your data, but remember that God loves you. Rest well tonight.";
    }
  }

  /// 🌟 NEW: Goal Alignment Checker
  String checkGoalAlignment(List<Task> weeklyTasks, List<Goal> activeGoals) {
    if (activeGoals.isEmpty || weeklyTasks.isEmpty) return "";

    // Simple keyword extraction to check for alignment
    int alignedTasks = 0;
    int distractionTasks = 0;

    // Words that typically signal procrastination or misaligned time-sinks
    final distractionKeywords = [
      'game',
      'netflix',
      'scroll',
      'tv',
      'movie',
      'chill',
      'party',
    ];

    for (var task in weeklyTasks) {
      String desc = task.description.toLowerCase();

      // Check if it matches a distraction
      if (distractionKeywords.any((word) => desc.contains(word))) {
        distractionTasks++;
        continue;
      }

      // Check if it matches a goal keyword
      for (var goal in activeGoals) {
        // Look for matching words between the daily task and the long-term goal
        List<String> goalWords = goal.title
            .toLowerCase()
            .split(' ')
            .where((w) => w.length > 3)
            .toList();
        if (goalWords.any((word) => desc.contains(word))) {
          alignedTasks++;
          break;
        }
      }
    }

    if (distractionTasks > alignedTasks && distractionTasks > 3) {
      return "I noticed you spent a lot of time on low-yield activities this week. Remember your big vision: ${activeGoals.first.title}. Let's refocus our daily tasks to match that milestone. ";
    } else if (alignedTasks >= 3) {
      return "Excellent alignment! Your daily actions are directly driving you toward your milestone: ${activeGoals.first.title}. Keep laying those bricks. ";
    }

    return "";
  }
}

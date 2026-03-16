import 'package:flutter/material.dart'; // Added for debugPrint
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../data/models/task_model.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/network_info.dart';
import 'calendar_service.dart'; // 🔥 NEW: Import the Calendar Service
import 'package:hive_flutter/hive_flutter.dart';

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
    // 🔥 OFFLINE CHECK: Geocoding requires internet
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

    // 🔥 OFFLINE CHECK: Only fetch weather if connected
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

    // TFLite runs 100% offline using whatever temp/rain data we provided
    var input = [
      [taskType.toDouble(), hour, temp, isRaining.toDouble()],
    ];
    var output = List.filled(1, 0.0).reshape([1, 1]);

    try {
      _interpreter!.run(input, output);
      double prob = output[0][0];
      int score = (prob * 100).round();

      if (score > 75)
        return "Great timing! High success probability ($score%).";
      if (score < 40)
        return "Caution: Success probability is low ($score%). Weather or timing may interfere.";
      return "Looks good. Moderate success chance ($score%).";
    } catch (e) {
      return "Analysis unavailable.";
    }
  }

  /// 🌟 NEW: Daily Motivational & Faith-Based Quotes
  String _getDailyMotivationalQuote() {
    int weekday = DateTime.now().weekday;

    switch (weekday) {
      case 1: // Monday
        return "Happy Monday! Step out with confidence and set the tone for the week. Remember, God got you, and He will always be good.";
      case 2: // Tuesday
        return "Happy Tuesday! Keep your momentum going strong. No matter the hurdles, God got you, and He will always be good.";
      case 3: // Wednesday
        return "Happy Wednesday! You are halfway through the week. Keep pushing forward, trusting that God got you, and He will always be good.";
      case 4: // Thursday
        return "Happy Thursday! Stay focused and finish your tasks with excellence. Be encouraged today; God got you, and He will always be good.";
      case 5: // Friday
        return "Happy Friday! Finish strong and look back at what you've achieved. Rejoice, because God got you, and He will always be good.";
      case 6: // Saturday
        return "Happy Saturday! Take time to execute your plans and also find moments of rest. Breathe easy, God got you, and He will always be good.";
      case 7: // Sunday
        return "Happy Sunday! Reflect, recharge, and prepare your heart and mind. Walk in peace today, knowing God got you, and He will always be good.";
      default:
        return "Have a wonderful day! Remember, God got you, and He will always be good.";
    }
  }

  /// BRIEFING GENERATION: Triggered when you tap "STOP" on the AlarmPage
  Future<String> generateMorningBriefing(
    List<Task> todaysTasks,
    double lat,
    double lon,
  ) async {
    // Grab today's specific motivational quote
    String dailyMotivation = _getDailyMotivationalQuote();

    // 🔥 NEW: Fetch offline Google Calendar events
    final calendarService = CalendarService();
    final calendarEvents = await calendarService.getEventsForDate(
      DateTime.now(),
    );
    if (todaysTasks.isEmpty && calendarEvents.isEmpty) {
      return "Good morning! You have a clear schedule today. $dailyMotivation";
    }

    // 🔥 OFFLINE CHECK: Gatekeeper for the briefing
    bool hasInternet = await NetworkInfo.isConnected;

    // 1. Get Contextual Data (Safely bypass if offline)
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
    } else {
      debugPrint("📴 OFFLINE: Bypassing network calls for Morning Briefing.");
    }

    // 2. Prepare the Schedule Summary integrating Calendar + Tasks
    String scheduleSummary = "";
    String firstActivityName = "";
    String firstActivityTime = "";

    // Determine what happens first: A Task or a Calendar Event?
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

    // 3. AI Prediction Advice (Runs offline perfectly)
    await _initModel();
    String aiAdvice = "";
    if (_interpreter != null) {
      var input = [
        [
          _categorizeTask(firstActivityName).toDouble(),
          (DateTime.now().hour)
              .toDouble(), // Approximation based on current time
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

    // 4. Construct final speech (combining schedule + AI advice + daily motivation)
    if (hasInternet) {
      return "Good morning! In $cityName, it is currently $weatherContext. "
          "$scheduleSummary "
          "Your first activity is $firstActivityName at $firstActivityTime. "
          "$aiAdvice "
          "$dailyMotivation";
    } else {
      // Shorter, offline-specific briefing
      return "Good morning! You are currently offline, but $scheduleSummary "
          "Your first activity is $firstActivityName at $firstActivityTime. "
          "$aiAdvice "
          "$dailyMotivation";
    }
  }

  /// 🌟 NEW: The Sunday Evening Weekly Strategy Review
  Future<String> generateWeeklyStrategyReview() async {
    try {
      final box = Hive.box<Task>(AppConstants.taskBoxName);
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // 1. Get only tasks from the last 7 days that were actually completed or failed
      final weeklyTasks = box.values.where((t) {
        return t.scheduledTime.isAfter(oneWeekAgo) && t.isSuccessful != null;
      }).toList();

      if (weeklyTasks.isEmpty) {
        return "Good evening! It looks like you didn't track any tasks this week. Let's set some goals and start fresh tomorrow!";
      }

      // 2. Tally up the categories
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

      // 3. Calculate overall and categorical success rates
      int totalSuccess = successPhysical + successMental + successChores;
      int overallRate = ((totalSuccess / weeklyTasks.length) * 100).round();

      double physicalRate = totalPhysical == 0
          ? 1.0
          : successPhysical / totalPhysical;
      double mentalRate = totalMental == 0 ? 1.0 : successMental / totalMental;
      double choresRate = totalChores == 0 ? 1.0 : successChores / totalChores;

      // 4. Generate the dynamic coaching script
      String intro =
          "Good evening. It is time for your weekly strategy review. "
          "You tackled ${weeklyTasks.length} tasks this week and achieved an overall success rate of $overallRate percent. ";

      String analysis = "";
      String advice = "";

      // Find the weakest link to offer advice
      if (mentalRate <= physicalRate &&
          mentalRate <= choresRate &&
          totalMental > 0 &&
          mentalRate < 0.7) {
        analysis =
            "You did well overall, but I noticed you struggled a bit with your focus and study tasks. ";
        advice =
            "Next week, let's try the Pomodoro technique. Break your deep work into 25-minute sprints to keep your brain fresh. ";
      } else if (physicalRate <= mentalRate &&
          physicalRate <= choresRate &&
          totalPhysical > 0 &&
          physicalRate < 0.7) {
        analysis = "You had a solid week, but your fitness goals took a hit. ";
        advice =
            "Next week, try laying out your workout clothes the night before, or schedule your physical tasks earlier in the day when you have more energy. ";
      } else if (choresRate < 0.7) {
        analysis =
            "Your heavy lifting is getting done, but your daily chores are slipping. ";
        advice =
            "Try grouping all your chores into one 45-minute block on Saturday morning to free up the rest of your week. ";
      } else {
        analysis =
            "You absolutely crushed it across the board this week! Your consistency is highly impressive. ";
        advice =
            "Your current strategy is working perfectly. Keep this exact momentum going into tomorrow. ";
      }

      String outro =
          "Take this evening to rest, recharge, and prepare your mind. Remember, God's got you, and He will always be good.";

      return intro + analysis + advice + outro;
    } catch (e) {
      debugPrint("Weekly Review Error: $e");
      return "Good evening. I couldn't access your weekly data, but take time to rest and recharge for tomorrow.";
    }
  }
}

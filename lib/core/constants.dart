import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // 1. Secure API Keys
  static String get openWeatherApiKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'FATAL: OPENWEATHER_API_KEY is missing from the .env file.',
      );
    }
    return key;
  }

  // 2. API Endpoints & Default Locations
  // 🔥 FIX: Switched to the 100% Free Current Weather API endpoint
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // Default coordinates (used if GPS fails)
  static const double defaultLat = 0.2827;
  static const double defaultLon = 34.7519;

  // 3. Local Offline Assets
  static const String tfliteModelPath = 'assets/routine_predictor.tflite';
  static const String alarmAudioPath = 'assets/alarm.wav';
  static const String alarm2AudioPath =
      'assets/alarm2.wav'; // Added for Task End alarms

  // 4. Local Storage (Hive)
  static const String taskBoxName = 'tasks_box';
  static const String historyBoxName = 'history_box';

  // 5. App Identity
  static const String appName = 'Smart Routine AI';
}

import '../core/api_client.dart';

// ------------------------------------------------------------------------
// 1. Data Models (Kept in the same file for simplicity, but can be separated)
// ------------------------------------------------------------------------

class WeatherForecast {
  final double currentTemp;
  final String condition; // e.g., "Rain", "Clear", "Clouds"
  final String description; // e.g., "light rain"
  final List<HourlyWeather> hourlyForecast;

  WeatherForecast({
    required this.currentTemp,
    required this.condition,
    required this.description,
    required this.hourlyForecast,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    var hourlyList = json['hourly'] as List? ?? [];
    return WeatherForecast(
      currentTemp: (json['current']['temp'] as num).toDouble(),
      condition: json['current']['weather'][0]['main'],
      description: json['current']['weather'][0]['description'],
      // We only grab the next 24 hours to keep memory light
      hourlyForecast: hourlyList
          .take(24)
          .map((e) => HourlyWeather.fromJson(e))
          .toList(),
    );
  }
}

class HourlyWeather {
  final DateTime time;
  final double temp;
  final String condition;

  HourlyWeather({
    required this.time,
    required this.temp,
    required this.condition,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      // OpenWeather returns time in Unix seconds, Dart needs milliseconds
      time: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temp: (json['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
    );
  }
}

// ------------------------------------------------------------------------
// 2. The Repository Class
// ------------------------------------------------------------------------

class WeatherRepository {
  final ApiClient _apiClient;

  // Dependency Injection: Pass an ApiClient or let it create one
  WeatherRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches the weather and parses it into our clean [WeatherForecast] object
  Future<WeatherForecast?> getWeatherForLocation(double lat, double lon) async {
    try {
      final rawData = await _apiClient.fetchWeather(lat, lon);
      return WeatherForecast.fromJson(rawData);
    } catch (e) {
      // In a production app, you might log this to Crashlytics
      print("WeatherRepo Error: $e");
      return null;
    }
  }

  /// Helper method specifically for the AI:
  /// Gets a readable string of what the weather will be at a specific task time.
  Future<String> getWeatherContextForTask(
    DateTime taskTime,
    double lat,
    double lon,
  ) async {
    final forecast = await getWeatherForLocation(lat, lon);

    if (forecast == null) {
      return "Weather data is currently unavailable.";
    }

    try {
      // Find the hourly forecast that is closest to the scheduled task time
      final closestHourly = forecast.hourlyForecast.firstWhere(
        (h) => h.time.difference(taskTime).inHours.abs() <= 1,
        orElse: () => forecast.hourlyForecast.first, // Fallback
      );

      return "At ${taskTime.hour}:00, the temperature will be ${closestHourly.temp.round()}°C with ${closestHourly.condition}.";
    } catch (e) {
      // If the task is more than 24 hours out, fallback to the current weather
      return "Current weather is ${forecast.currentTemp.round()}°C, ${forecast.condition}.";
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Safely logs to console
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiClient {
  // ------------------------------------------------------------------------
  // 1. Weather API Call
  // ------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    // GUARD: Check if API key is missing before even trying
    if (AppConstants.openWeatherApiKey.isEmpty ||
        AppConstants.openWeatherApiKey.contains('YOUR_')) {
      throw Exception(
        'OpenWeather API Key is missing or invalid in the .env file!',
      );
    }

    final url =
        '${AppConstants.weatherBaseUrl}?lat=$lat&lon=$lon&appid=${AppConstants.openWeatherApiKey}&units=metric';

    try {
      // UPGRADE: Added a 10-second timeout. If the network hangs, the app won't freeze.
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // UPGRADE: Log the actual error code from the server for easier debugging
        debugPrint(
          'Weather API Error [${response.statusCode}]: ${response.body}',
        );
        throw Exception(
          'Server error: Could not load weather (Code ${response.statusCode})',
        );
      }
    } on SocketException {
      // UPGRADE: Specifically catches when the device has NO internet connection
      throw Exception(
        'No Internet connection. Please check your Wi-Fi or data.',
      );
    } catch (e) {
      throw Exception('Weather fetch failed: $e');
    }
  }
}

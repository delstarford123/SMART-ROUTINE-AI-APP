import 'package:flutter/material.dart';

class SmartParseResult {
  final DateTime? date;
  final TimeOfDay? time;
  SmartParseResult({this.date, this.time});
}

class NLPEngine {
  /// FIX: Added this method so planning_page.dart can compile.
  /// It extracts just the time from the full result.
  TimeOfDay? extractTime(String text) {
    final result = extractDateTime(text);
    return result.time;
  }

  /// The main brain that handles Today, Tomorrow, and Relative times.
  SmartParseResult extractDateTime(String text) {
    if (text.isEmpty) return SmartParseResult();
    final input = text.toLowerCase().trim();

    DateTime? extractedDate;
    TimeOfDay? extractedTime;

    // --- 1. Date Detection ---
    if (input.contains('tomorrow')) {
      extractedDate = DateTime.now().add(const Duration(days: 1));
    } else if (input.contains('today') || input.contains('tonight')) {
      extractedDate = DateTime.now();
    }

    // --- 2. Time Detection (Relative) ---
    final relativeMatch = RegExp(
      r'in\s(\d+)\s(min|minute|hr|hour)s?',
    ).firstMatch(input);

    if (relativeMatch != null) {
      int value = int.parse(relativeMatch.group(1)!);
      String unit = relativeMatch.group(2)!;
      DateTime calculated = DateTime.now().add(
        unit.startsWith('m')
            ? Duration(minutes: value)
            : Duration(hours: value),
      );
      extractedTime = TimeOfDay.fromDateTime(calculated);
      // Auto-set date if it rolls over to next day (e.g., adding 2 hours at 11 PM)
      extractedDate ??= calculated;
    }

    // --- 3. Time Detection (Absolute) ---
    final timeMatch = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s?([ap]m)?',
    ).firstMatch(input);

    if (timeMatch != null) {
      if (input.contains('at') ||
          input.contains(':') ||
          timeMatch.group(3) != null) {
        int hour = int.parse(timeMatch.group(1)!);
        int minute = int.parse(timeMatch.group(2) ?? "0");
        String? period = timeMatch.group(3);

        if (period != null) {
          if (period.contains('p') && hour < 12) hour += 12;
          if (period.contains('a') && hour == 12) hour = 0;
        } else if (hour > 0 && hour <= 7 && !input.contains(':')) {
          hour += 12; // Smart guess for evening hours
        }

        if (hour < 24 && minute < 60) {
          extractedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    return SmartParseResult(date: extractedDate, time: extractedTime);
  }
}

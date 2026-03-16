// lib/logic/calendar_service.dart
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// Fetches events for a specific date from all local calendars
  Future<List<Event>> getEventsForDate(DateTime date) async {
    List<Event> dayEvents = [];

    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess ||
            !(permissionsGranted.data ?? false)) {
          debugPrint("❌ Calendar permission denied.");
          return [];
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return [];
      }

      // 🔥 FIX: Use the specific 'date' passed in, not just "DateTime.now()"
      final startOfDay = TZDateTime.local(date.year, date.month, date.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

      for (var calendar in calendarsResult.data!) {
        if (calendar.id != null) {
          final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id!,
            RetrieveEventsParams(startDate: startOfDay, endDate: endOfDay),
          );

          if (eventsResult.isSuccess && eventsResult.data != null) {
            dayEvents.addAll(eventsResult.data!);
          }
        }
      }

      dayEvents.sort((a, b) {
        final aStart = a.start ?? startOfDay;
        final bStart = b.start ?? startOfDay;
        return aStart.compareTo(bStart);
      });

      return dayEvents;
    } catch (e) {
      debugPrint("❌ Error reading local calendar: $e");
      return [];
    }
  }
}

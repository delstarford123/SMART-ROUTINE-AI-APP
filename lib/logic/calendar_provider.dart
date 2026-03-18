import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as cal;
import 'calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  List<cal.Event> _events = [];
  bool _isLoading = false;

  List<cal.Event> get events => _events;
  bool get isLoading => _isLoading;

  Future<void> loadEventsForDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    _events = await CalendarService().getEventsForDate(date);

    _isLoading = false;
    notifyListeners();
  }
}

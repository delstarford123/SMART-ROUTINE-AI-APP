import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A global helper function to format time automatically based on user's phone settings
String getFormattedTime(BuildContext context, DateTime time) {
  // Checks if the Android system is set to 24-hour time
  bool is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;

  // Applies the correct format automatically
  return DateFormat(is24Hour ? 'HH:mm' : 'h:mm a').format(time);
}

import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkInfo {
  static Future<bool> get isConnected async {
    // 🚨 FIX: Added ".instance"
    return await InternetConnectionChecker.instance.hasConnection;
  }
}

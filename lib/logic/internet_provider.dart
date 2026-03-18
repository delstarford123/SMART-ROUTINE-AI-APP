import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetProvider extends ChangeNotifier {
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  late StreamSubscription<InternetConnectionStatus> _connectionSubscription;

  InternetProvider() {
    _initNetworkListener();
  }

  void _initNetworkListener() async {
    _hasInternet = await InternetConnectionChecker.instance.hasConnection;
    notifyListeners();

    _connectionSubscription = InternetConnectionChecker.instance.onStatusChange
        .listen((InternetConnectionStatus status) {
          _hasInternet = status == InternetConnectionStatus.connected;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}

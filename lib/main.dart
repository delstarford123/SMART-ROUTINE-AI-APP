import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

// Custom Layers
import 'core/theme.dart';
import 'data/hive_service.dart';
import 'logic/alarm_manager.dart';
import 'logic/plan_provider.dart';
import 'ui/home_page.dart';
import 'ui/alarm_page.dart';

// Global Navigation Key for background routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global subscription for the alarm stream
StreamSubscription<AlarmSettings>? globalRingSubscription;

void main() async {
  // 1. Ensure Flutter binding is initialized before native calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Global Error Handling (Pro Feature)
  // Catches UI errors and prevents the "Grey Screen of Death"
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 Flutter Error: ${details.exceptionAsString()}');
  };

  // Catches asynchronous Dart errors in the background
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 Async Error: $error');
    return true;
  };

  try {
    // 3. Core Service Initialization
    await Future.wait([
      dotenv.load(fileName: ".env"),
      HiveService.init(),
      AlarmService().init(),
    ]);

    // 4. Request Permissions
    await _requestPermissions();

    // 5. Bulletproof Alarm Listener
    _setupGlobalAlarmListener();
  } catch (e, stackTrace) {
    debugPrint('🔥 Fatal Initialization Error: $e\n$stackTrace');
    // In a real app, you might route to a "Crash/Maintenance" screen here
  }

  // 6. Launch App with MultiProvider (Highly Scalable)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        // Add more providers here easily in the future (e.g., ThemeProvider, AuthProvider)
      ],
      child: const SmartRoutineApp(),
    ),
  );
}

/// Sets up the alarm listener safely outside the widget tree
void _setupGlobalAlarmListener() {
  try {
    globalRingSubscription?.cancel();

    // Using asBroadcastStream ensures Hot Reloads don't crash the engine
    globalRingSubscription = Alarm.ringStream.stream.asBroadcastStream().listen(
      (alarmSettings) {
        debugPrint('⏰ Alarm Triggered: ID ${alarmSettings.id}');

        // 🔥 CRITICAL ADDITION: Tell the AlarmService which alarm is ringing
        // so the AI Text-to-Speech knows what script to read!
        AlarmService().setRingingAlarmData(
          alarmSettings.id,
          alarmSettings.notificationSettings.title,
        );

        // Push to the Alarm Page regardless of where the user is in the app
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const AlarmPage()),
        );
      },
    );
  } catch (e) {
    debugPrint('⚠️ Alarm Stream handled a hot-reload state gracefully.');
  }
}

/// Requests all critical permissions for the AI and Alarm engine
Future<void> _requestPermissions() async {
  await Permission.notification.request();

  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
  if (await Permission.microphone.isDenied) {
    await Permission.microphone.request();
  }
}

// -----------------------------------------------------------------------------
// APP WIDGET
// -----------------------------------------------------------------------------

class SmartRoutineApp extends StatefulWidget {
  const SmartRoutineApp({Key? key}) : super(key: key);

  @override
  State<SmartRoutineApp> createState() => _SmartRoutineAppState();
}

// Pro Feature: WidgetsBindingObserver allows the app to know when it is opened/closed
class _SmartRoutineAppState extends State<SmartRoutineApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Listens to App Lifecycle changes (Foreground/Background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user just re-opened the app!
      // Great place to refresh tasks, check for missed alarms, or update AI weather logic.
      debugPrint('📱 App Resumed: Refreshing Data...');

      // Example: context.read<PlanProvider>().loadTasksForDate(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Smart Routine AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}

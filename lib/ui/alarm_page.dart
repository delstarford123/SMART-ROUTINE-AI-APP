import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../logic/alarm_manager.dart'; // Make sure this matches your path to AlarmService!
import '../core/theme.dart';
import '../data/hive_service.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({Key? key}) : super(key: key);

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  bool _isWakeUpAlarm = false;
  bool _isUpright = false;
  bool _isListening = false;
  String _spokenWords = "";

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // 1. Check if this is the morning wake-up alarm
    _checkIfWakeUpAlarm();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Only start sensors and mic if it's the morning wake-up
    if (_isWakeUpAlarm) {
      _initSpeech();
      _startSensorListener();
    }
  }

  void _checkIfWakeUpAlarm() {
    // Grab the target wake-up time the user set in Settings
    final wakeupTime =
        HiveService().getWakeupTime() ?? const TimeOfDay(hour: 7, minute: 0);
    final now = DateTime.now();

    // If the alarm is ringing within 5 minutes of their target wake-up time, enforce Strict Mode!
    if (now.hour == wakeupTime.hour &&
        (now.minute - wakeupTime.minute).abs() <= 5) {
      setState(() => _isWakeUpAlarm = true);
    }
  }

  void _initSpeech() async {
    await _speechToText.initialize(
      onError: (val) => debugPrint("Speech Error: $val"),
      onStatus: (val) => debugPrint("Speech Status: $val"),
    );
  }

  void _startSensorListener() {
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      bool isCurrentlyUpright = event.y > 7.5;

      if (isCurrentlyUpright && !_isUpright) {
        setState(() => _isUpright = true);
        _startListening();
      } else if (!isCurrentlyUpright && _isUpright) {
        setState(() => _isUpright = false);
        _stopListening();
      }
    });
  }

  void _startListening() async {
    if (!_isListening && _speechToText.isAvailable) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _spokenWords = result.recognizedWords.toLowerCase();

            // 🔥 UPDATED: Now listens for "THANK YOU SMART"
            if (_spokenWords.contains("thank you smart") ||
                _spokenWords.contains("thanks smart")) {
              _triggerSuccess();
            }
          });
        },
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _triggerSuccess() async {
    if (_isWakeUpAlarm) {
      _stopListening();
      _accelerometerSubscription?.cancel();
    }

    // Stop the alarm and trigger the AI Morning Briefing
    await AlarmService().stopActiveAlarmAndSpeak(
      0.0,
      0.0,
    ); // Pass real GPS coords if you have them!

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accelerometerSubscription?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // UI FOR NORMAL DAILY TASKS (Simple Stop Button)
    // ==========================================
    if (!_isWakeUpAlarm) {
      return Scaffold(
        backgroundColor: AppTheme.navyBlue,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_active,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Time to Execute!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepSkyBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _triggerSuccess,
                  child: const Text(
                    "STOP ALARM",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================
    // UI FOR STRICT MORNING WAKE-UP
    // ==========================================
    return Scaffold(
      backgroundColor: _isUpright ? AppTheme.navyBlue : Colors.red.shade900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_animationController.value * 0.2),
                      child: Icon(
                        _isUpright ? Icons.mic : Icons.screen_rotation,
                        size: 100,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                Text(
                  _isUpright ? "Microphone Active!" : "WAKE UP PROTOCOL",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔥 UPDATED TEXT INSTRUCTIONS
                Text(
                  _isUpright
                      ? "Say loudly:\n\"THANK YOU SMART!\""
                      : "Stand up and hold your phone straight up to activate the microphone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 40),

                if (_isUpright)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _spokenWords.isEmpty
                          ? "Listening..."
                          : 'I heard: "$_spokenWords"',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const Spacer(),

                TextButton(
                  onPressed: _triggerSuccess,
                  child: const Text(
                    "Emergency Stop",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

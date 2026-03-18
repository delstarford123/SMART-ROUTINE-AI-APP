import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../logic/alarm_manager.dart';
import '../core/theme.dart';
import '../data/hive_service.dart';
import 'home_page.dart'; // 🔥 NEW: Import the Home Page

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

  // State variables to hold custom settings
  String _targetPhrase = "thank you smart";
  double _targetStrictness = 7.5;

  // State variables for Speech Error Handling
  String _speechFeedback = "";
  bool _hasSpeechError = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Fetch custom user settings
    _targetPhrase = HiveService().getWakeupPhrase();
    _targetStrictness = HiveService().getStrictness();

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
    final wakeupTime =
        HiveService().getWakeupTime() ?? const TimeOfDay(hour: 7, minute: 0);
    final now = DateTime.now();

    if (now.hour == wakeupTime.hour &&
        (now.minute - wakeupTime.minute).abs() <= 5) {
      setState(() => _isWakeUpAlarm = true);
    }
  }

  void _initSpeech() async {
    await _speechToText.initialize(
      onError: (val) {
        debugPrint("Speech Error: ${val.errorMsg}");
        if (mounted) {
          setState(() {
            _hasSpeechError = true;
            _isListening = false;

            if (val.errorMsg.contains('timeout')) {
              _speechFeedback = "Speech timeout. Please speak up louder.";
            } else if (val.errorMsg.contains('busy')) {
              _speechFeedback = "Microphone is busy. Resetting...";
            } else {
              _speechFeedback = "Couldn't hear you clearly. Try again.";
            }
          });
        }
      },
      onStatus: (val) {
        debugPrint("Speech Status: $val");
        if (val == 'notListening' || val == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  void _startSensorListener() {
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      bool isCurrentlyUpright = event.y > _targetStrictness;

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
      setState(() {
        _isListening = true;
        _hasSpeechError = false;
        _speechFeedback = "";
      });

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _spokenWords = result.recognizedWords.toLowerCase();

            if (_spokenWords.contains(_targetPhrase)) {
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

  // 🔥 UPDATED: Professional routing to avoid the "Dark Screen"
  void _triggerSuccess() async {
    if (_isWakeUpAlarm) {
      _stopListening();
      _accelerometerSubscription?.cancel();
    }

    // 1. Give immediate UI feedback
    setState(() {
      _spokenWords = "Good morning! Preparing your dashboard...";
    });

    // 2. Stop the alarm and trigger the AI Morning Briefing
    await AlarmService().stopActiveAlarmAndSpeak(0.0, 0.0);

    // 3. Professionally fade into the Home Page and destroy back history
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
        (route) => false,
      );
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

                Text(
                  _isUpright
                      ? "Say loudly:\n\"${_targetPhrase.toUpperCase()}!\""
                      : "Stand up and hold your phone straight up to activate the microphone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 40),

                if (_isUpright)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _hasSpeechError
                              ? Colors.red.withOpacity(0.2)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: _hasSpeechError
                              ? Border.all(color: Colors.redAccent)
                              : null,
                        ),
                        child: Text(
                          _hasSpeechError
                              ? _speechFeedback
                              : (_spokenWords.isEmpty
                                    ? "Listening..."
                                    : 'I heard: "$_spokenWords"'),
                          style: TextStyle(
                            color: _hasSpeechError
                                ? Colors.redAccent.shade100
                                : Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontWeight: _hasSpeechError
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      if (_hasSpeechError) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            "Retry Microphone",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: _startListening,
                        ),
                      ],
                    ],
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

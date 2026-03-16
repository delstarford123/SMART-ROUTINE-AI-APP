import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/theme.dart';
import '../data/models/task_model.dart';

class FocusModePage extends StatefulWidget {
  final Task task;
  // Default to 25 minutes (Pomodoro standard)
  final int durationMinutes;

  const FocusModePage({Key? key, required this.task, this.durationMinutes = 25})
    : super(key: key);

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

// 🔥 WidgetsBindingObserver lets us detect when the app goes to the background!
class _FocusModePageState extends State<FocusModePage>
    with WidgetsBindingObserver {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Start watching app lifecycle
    _remainingSeconds = widget.durationMinutes * 60;
    _initNotifications();
    _startTimer();
    _toggleAudio(); // Start rain sounds automatically
  }

  void _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _notificationsPlugin.initialize(initSettings);
  }

  // --- THE LOCKDOWN PROTOCOL ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // If the timer is running and the user leaves the app...
    if (state == AppLifecycleState.paused && _isRunning) {
      _sendGuiltTripNotification();
    }
  }

  void _sendGuiltTripNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'focus_channel',
          'Focus Mode Alerts',
          channelDescription: 'Alerts when leaving focus mode',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.red,
          enableVibration: true,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0,
      '🚨 Focus Mode Interrupted!',
      'You are supposed to be working on "${widget.task.description}". Get back to work!',
      platformDetails,
    );
  }
  // ------------------------------

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _endSession(success: true);
      }
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  Future<void> _toggleAudio() async {
    if (_isAudioPlaying) {
      await _audioPlayer.pause();
    } else {
      // Loop the audio infinitely
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // 🔥 Make sure you added rain.mp3 to your assets/audio folder!
      await _audioPlayer.play(AssetSource('audio/rain.mp3'));
    }
    setState(() => _isAudioPlaying = !_isAudioPlaying);
  }

  void _endSession({required bool success}) {
    _timer?.cancel();
    _audioPlayer.stop();

    // You could update your Hive database here to mark the task as complete!

    Navigator.pop(context, success);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop watching lifecycle
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = _remainingSeconds / (widget.durationMinutes * 60);

    return Scaffold(
      backgroundColor: AppTheme.navyBlue, // Dark, distraction-free background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "DEEP WORK LOCKDOWN",
              style: TextStyle(
                color: Colors.white54,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.task.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // The Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.2 ? AppTheme.deepSkyBlue : Colors.redAccent,
                    ),
                  ),
                ),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Ambient Audio Toggle
            GestureDetector(
              onTap: _toggleAudio,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAudioPlaying ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isAudioPlaying ? "Rain Sounds: ON" : "Rain Sounds: OFF",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    "Give Up",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _endSession(success: false),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.orange : Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isRunning ? "Pause" : "Resume",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

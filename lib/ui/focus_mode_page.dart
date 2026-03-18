import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/theme.dart';
import '../data/models/task_model.dart';

class FocusModePage extends StatefulWidget {
  final Task task;
  final int defaultDurationMinutes;

  const FocusModePage({
    Key? key,
    required this.task,
    this.defaultDurationMinutes = 25,
  }) : super(key: key);

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage>
    with WidgetsBindingObserver {
  // --- Phase & Setup State ---
  bool _isSetupPhase = true;
  late int _selectedDuration;
  String _selectedAudio = 'audio/rain.mp3'; // Default to rain

  // Available audio tracks matching your assets folder
  final Map<String, String> _audioOptions = {
    'none': 'Silent (No Sound)',
    'audio/rain.mp3': 'Light Rain',
    'audio/rain2.mp3': 'Heavy Rain',
    'audio/white noise.mp3': 'White Noise',
  };

  // --- Active Timer State ---
  late int _remainingSeconds;
  DateTime? _targetEndTime; // 🔥 CRITICAL: Prevents background timer drift!
  Timer? _timer;
  bool _isRunning = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDuration = widget.defaultDurationMinutes;
    _initNotifications();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _notificationsPlugin.initialize(initSettings);

    // Request permissions for Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // --- THE LOCKDOWN PROTOCOL ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Trigger guilt trip if leaving the app during an active lockdown
    if (state == AppLifecycleState.paused && _isRunning && !_isSetupPhase) {
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
      '🚨 Focus Broken!',
      'You are supposed to be working on "${widget.task.description}". Get back to work!',
      platformDetails,
    );
  }

  // --- TIMER & AUDIO CONTROLS ---

  void _beginLockdown() {
    setState(() {
      _remainingSeconds = _selectedDuration * 60;
      _isSetupPhase = false;
    });
    _startTimer();
    _startAudioBasedOnSelection();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      // 🔥 Set target time based on exact math, not tick increments
      _targetEndTime ??= DateTime.now().add(
        Duration(seconds: _remainingSeconds),
      );
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_targetEndTime!.isAfter(now)) {
        setState(() {
          _remainingSeconds = _targetEndTime!.difference(now).inSeconds;
        });
      } else {
        setState(() => _remainingSeconds = 0);
        _endSession(success: true); // Auto-completes when time is up
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _targetEndTime = null; // Clear so it recalculates accurately on resume
    });
    _timer?.cancel();
  }

  Future<void> _startAudioBasedOnSelection() async {
    if (_selectedAudio == 'none') return;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_selectedAudio));
      setState(() => _isAudioPlaying = true);
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> _toggleAudio() async {
    if (_selectedAudio == 'none') return;

    try {
      if (_isAudioPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      setState(() => _isAudioPlaying = !_isAudioPlaying);
    } catch (e) {
      debugPrint("Error toggling audio: $e");
    }
  }

  void _endSession({required bool success}) {
    _timer?.cancel();
    _audioPlayer.stop();
    Navigator.pop(context, success);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return Scaffold(
      backgroundColor: AppTheme.navyBlue,
      body: SafeArea(
        child: _isSetupPhase ? _buildSetupUI() : _buildActiveTimerUI(),
      ),
    );
  }

  // ==========================================
  // UI: PRE-LOCKDOWN SETUP PHASE
  // ==========================================
  Widget _buildSetupUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            "PREPARE FOR DEEP WORK",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.task.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Duration Selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  "Set Duration (Minutes)",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "$_selectedDuration",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.deepSkyBlue,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.deepSkyBlue,
                    overlayColor: AppTheme.deepSkyBlue.withOpacity(0.2),
                    trackHeight: 6.0,
                  ),
                  child: Slider(
                    value: _selectedDuration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23, // Steps of 5 minutes
                    onChanged: (val) =>
                        setState(() => _selectedDuration = val.toInt()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Audio Track Selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ambient Sound",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _audioOptions.entries.map((entry) {
                    bool isSelected = _selectedAudio == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      selectedColor: AppTheme.deepSkyBlue,
                      backgroundColor: Colors.black26,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (bool selected) {
                        if (selected)
                          setState(() => _selectedAudio = entry.key);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Start Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            onPressed: _beginLockdown,
            child: const Text(
              "BEGIN LOCKDOWN",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI: ACTIVE LOCKDOWN PHASE
  // ==========================================
  Widget _buildActiveTimerUI() {
    double progress = _remainingSeconds / (_selectedDuration * 60);

    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          "LOCKDOWN ACTIVE",
          style: TextStyle(
            color: Colors.white54,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.task.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const Spacer(),

        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 14,
                backgroundColor: Colors.white12,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.2 ? AppTheme.deepSkyBlue : Colors.redAccent,
                ),
              ),
            ),
            Text(
              _formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Show Audio Toggle only if they didn't select 'none'
        if (_selectedAudio != 'none')
          GestureDetector(
            onTap: _toggleAudio,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                    _isAudioPlaying ? "Audio: Playing" : "Audio: Paused",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 40),

        // Pause/Resume and Completion Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Abort Button (Fail)
              _buildActionButton(
                icon: Icons.close,
                label: "Abort",
                color: Colors.redAccent,
                onTap: () => _endSession(success: false),
              ),

              // Pause / Resume Button
              FloatingActionButton(
                backgroundColor: _isRunning ? Colors.orange : Colors.white,
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                elevation: 0,
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: _isRunning ? Colors.white : AppTheme.navyBlue,
                  size: 32,
                ),
              ),

              // Finish Early Button (Success)
              _buildActionButton(
                icon: Icons.check,
                label: "Done",
                color: Colors.green,
                onTap: () => _endSession(success: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/hive_service.dart';
import '../core/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts _flutterTts = FlutterTts();
  List<Map<String, String>> _voices = [];
  Map<String, String>? _selectedVoice;
  TimeOfDay _wakeupTime = const TimeOfDay(hour: 7, minute: 0);

  // Advanced AI controls
  double _speechRate = 0.5;
  double _speechPitch = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initVoices();
  }

  // 1. Load saved preferences from Hive
  void _loadSettings() {
    final savedVoice = HiveService().getSavedVoice();
    final savedTime = HiveService().getWakeupTime();

    setState(() {
      if (savedVoice != null) {
        _selectedVoice = Map<String, String>.from(savedVoice);
      }
      if (savedTime != null) _wakeupTime = savedTime;
    });
  }

  // 2. Load available system voices and format them
  Future<void> _initVoices() async {
    try {
      List<dynamic> voices = await _flutterTts.getVoices;

      List<Map<String, String>> formattedVoices = [];

      for (var v in voices) {
        String name = v["name"].toString();
        String locale = v["locale"].toString();

        // Only keep English voices
        if (!locale.toLowerCase().contains("en")) continue;

        // Parse Android TTS names to determine Gender and Clean Name
        String gender = "unknown";
        String cleanName = name;
        IconData icon = Icons.record_voice_over;
        Color iconColor = Colors.grey;

        // Google TTS usually uses standard identifiers in the name string
        if (name.toLowerCase().contains("-female") ||
            name.toLowerCase().contains("-f-") ||
            name.endsWith("-a") ||
            name.endsWith("-c") ||
            name.endsWith("-f")) {
          gender = "female";
          icon = Icons.face_3;
          iconColor = Colors.pinkAccent;
          cleanName = "Female Voice (${locale.toUpperCase()})";
        } else if (name.toLowerCase().contains("-male") ||
            name.toLowerCase().contains("-m-") ||
            name.endsWith("-b") ||
            name.endsWith("-d") ||
            name.endsWith("-e")) {
          gender = "male";
          icon = Icons.face;
          iconColor = Colors.blueAccent;
          cleanName = "Male Voice (${locale.toUpperCase()})";
        } else {
          // If we can't tell, keep it generic
          cleanName = "System Voice (${locale.toUpperCase()})";
        }

        // Add a unique identifier number to avoid identical names
        cleanName = "$cleanName [${name.substring(name.length - 2)}]";

        formattedVoices.add({
          "originalName": name,
          "locale": locale,
          "cleanName": cleanName,
          "gender": gender,
        });
      }

      setState(() {
        _voices = formattedVoices;
      });
    } catch (e) {
      debugPrint("Error loading voices: $e");
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeupTime,
    );
    if (picked != null && picked != _wakeupTime) {
      setState(() => _wakeupTime = picked);
      HiveService().saveWakeupTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("AI Personality & Voice"),

          // Voice Selector Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.deepSkyBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: AppTheme.navyBlue,
                ),
              ),
              title: const Text(
                "Assistant Voice",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _selectedVoice?["cleanName"] ?? "Tap to select a voice",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showVoicePicker,
            ),
          ),
          const SizedBox(height: 12),

          // Advanced AI Audio Settings (Speech Rate)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Speech Speed",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    activeColor: AppTheme.deepSkyBlue,
                    onChanged: (val) {
                      setState(() => _speechRate = val);
                      _flutterTts.setSpeechRate(val);
                    },
                    onChangeEnd: (val) {
                      _flutterTts.speak("This is my new speaking speed.");
                      // You should also save this to Hive Service in the future!
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle("Daily Schedule"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.orange,
                ),
              ),
              title: const Text(
                "Target Wake-up Time",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Your daily AI morning briefing"),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _wakeupTime.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyBlue,
                  ),
                ),
              ),
              onTap: () => _selectTime(context),
            ),
          ),
          const SizedBox(height: 40),

          // App Info footer
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(
                    Icons.memory,
                    size: 30,
                    color: AppTheme.navyBlue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Smart Routine AI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyBlue,
                  ),
                ),
                const Text(
                  "v1.0.0 • Local AI Engine Active",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Beautiful Bottom Sheet for Voice Selection
  void _showVoicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Select AI Voice",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _voices.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final voice = _voices[index];

                  // Determine Icon based on parsed gender
                  IconData genderIcon = Icons.record_voice_over;
                  Color iconColor = Colors.grey;

                  if (voice["gender"] == "female") {
                    genderIcon = Icons.face_3;
                    iconColor = Colors.pinkAccent;
                  } else if (voice["gender"] == "male") {
                    genderIcon = Icons.face;
                    iconColor = Colors.blueAccent;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(genderIcon, color: iconColor),
                    ),
                    title: Text(
                      voice["cleanName"]!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "Locale: ${voice["locale"]}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing:
                        _selectedVoice?["originalName"] == voice["originalName"]
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() => _selectedVoice = voice);
                      // Save the map to Hive
                      HiveService().saveVoice(voice);

                      // Tell TTS to use the original android system name
                      _flutterTts.setVoice({
                        "name": voice["originalName"]!,
                        "locale": voice["locale"]!,
                      });
                      _flutterTts.speak("Hello, this is how I will sound.");

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 🔥 Needed for direct setting saves
import '../data/hive_service.dart';
import '../logic/alarm_manager.dart'; // 🔥 Needed to sync the wake-up time
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

  // Wake-Up Protocol State Variables
  String _wakeupPhrase = "thank you smart";
  double _strictness = 7.5;

  // User Profile State
  String _userName = "";
  final TextEditingController _nameController = TextEditingController();

  bool _isLoadingVoices = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initVoices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 1. Load saved preferences
  void _loadSettings() {
    final savedVoice = HiveService().getSavedVoice();
    final savedTime = HiveService().getWakeupTime();

    setState(() {
      if (savedVoice != null) {
        _selectedVoice = Map<String, String>.from(savedVoice);
      }
      if (savedTime != null) _wakeupTime = savedTime;

      _wakeupPhrase = HiveService().getWakeupPhrase();
      _strictness = HiveService().getStrictness();

      // 🔥 Load the saved speech rate (default to 0.5 if not found)
      var settingsBox = Hive.box('settings');
      _speechRate = settingsBox.get('speechRate', defaultValue: 0.5);

      _userName = HiveService().getUserName();
      _nameController.text = _userName == "Friend" ? "" : _userName;
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

        if (!locale.toLowerCase().contains("en")) continue;

        String gender = "unknown";
        String cleanName = name;
        IconData icon = Icons.record_voice_over;
        Color iconColor = Colors.grey;

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
          cleanName = "System Voice (${locale.toUpperCase()})";
        }

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
        _isLoadingVoices = false;
      });
    } catch (e) {
      debugPrint("Error loading voices: $e");
      setState(() => _isLoadingVoices = false);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    FocusScope.of(context).unfocus(); // 🔥 CLOSES KEYBOARD TO PREVENT CRASH
    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // 🔥 Wait for animation

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeupTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.navyBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _wakeupTime) {
      setState(() => _wakeupTime = picked);
      HiveService().saveWakeupTime(picked);

      // Sync the new time with the OS Alarm Service instantly
      final now = DateTime.now();
      DateTime nextAlarm = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      if (nextAlarm.isBefore(now)) {
        nextAlarm = nextAlarm.add(
          const Duration(days: 1),
        ); // Schedule for tomorrow if time has passed
      }
      await AlarmService().setWakeUpAlarm(nextAlarm);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Wake-up time updated & alarm scheduled!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPhraseEditDialog(BuildContext context) {
    final TextEditingController phraseController = TextEditingController(
      text: _wakeupPhrase,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Edit Wake-up Phrase",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: TextField(
            controller: phraseController,
            decoration: InputDecoration(
              hintText: "e.g., thank you smart",
              helperText: "Keep it simple for the AI to understand.",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final newPhrase = phraseController.text.trim().toLowerCase();
                if (newPhrase.isNotEmpty) {
                  setState(() => _wakeupPhrase = newPhrase);
                  HiveService().saveWakeupPhrase(newPhrase);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Wake-up phrase updated!"),
                    backgroundColor: AppTheme.deepSkyBlue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text(
            "Settings",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ==========================================
            // 1. USER PROFILE SECTION
            // ==========================================
            _buildSectionTitle("User Profile"),
            _buildCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildIconContainer(
                      Icons.person,
                      AppTheme.deepSkyBlue,
                      AppTheme.deepSkyBlue.withOpacity(0.15),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyBlue,
                        ),
                        decoration: InputDecoration(
                          labelText: "What should I call you?",
                          labelStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          hintText: "Enter your name",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          final trimmed = value.trim();
                          HiveService().saveUserName(
                            trimmed.isNotEmpty ? trimmed : "Friend",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ==========================================
            // 2. AI PERSONALITY & VOICE
            // ==========================================
            _buildSectionTitle("AI Personality & Voice"),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: _buildIconContainer(
                      Icons.record_voice_over,
                      AppTheme.navyBlue,
                      AppTheme.navyBlue.withOpacity(0.1),
                    ),
                    title: const Text(
                      "Assistant Voice",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      _selectedVoice?["cleanName"] ?? "Tap to select a voice",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: _showVoicePicker,
                  ),
                  Divider(height: 1, indent: 64, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Speech Speed",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${_speechRate.toStringAsFixed(1)}x",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepSkyBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: _speechRate,
                            min: 0.1,
                            max: 1.0,
                            activeColor: AppTheme.deepSkyBlue,
                            inactiveColor: Colors.grey.shade200,
                            onChanged: (val) {
                              setState(() => _speechRate = val);
                              _flutterTts.setSpeechRate(val);
                            },
                            onChangeEnd: (val) {
                              // 🔥 Save to database so it survives app restarts
                              Hive.box('settings').put('speechRate', val);
                              _flutterTts.speak(
                                "This is my new speaking speed.",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ==========================================
            // 3. DAILY SCHEDULE
            // ==========================================
            _buildSectionTitle("Daily Schedule"),
            _buildCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: _buildIconContainer(
                  Icons.wb_sunny_outlined,
                  Colors.orange,
                  Colors.orange.withOpacity(0.15),
                ),
                title: const Text(
                  "Target Wake-up Time",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text(
                  "Your daily AI morning briefing",
                  style: TextStyle(fontSize: 13),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                      fontSize: 15,
                    ),
                  ),
                ),
                onTap: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 28),

            // ==========================================
            // 4. WAKE-UP PROTOCOL
            // ==========================================
            _buildSectionTitle("Wake-Up Protocol (Strict Mode)"),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: _buildIconContainer(
                      Icons.password,
                      Colors.redAccent,
                      Colors.red.withOpacity(0.1),
                    ),
                    title: const Text(
                      "Wake-up Phrase",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Current: "$_wakeupPhrase"',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onTap: () => _showPhraseEditDialog(context),
                  ),
                  Divider(height: 1, indent: 64, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Posture Strictness",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${_strictness.toStringAsFixed(1)} / 9.8",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "How straight must the phone be held to unlock the microphone?",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              "Relaxed",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                ),
                                child: Slider(
                                  value: _strictness,
                                  min: 5.0,
                                  max: 9.8,
                                  activeColor: Colors.redAccent,
                                  inactiveColor: Colors.red.shade100,
                                  onChanged: (val) =>
                                      setState(() => _strictness = val),
                                  onChangeEnd: (val) =>
                                      HiveService().saveStrictness(val),
                                ),
                              ),
                            ),
                            const Text(
                              "Military",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ==========================================
            // APP VERSION INFO
            // ==========================================
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.memory,
                      size: 36,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Smart Routine AI",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "v1.0.0 • Local AI Engine Active",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildIconContainer(
    IconData icon,
    Color color,
    Color bgColor, {
    double size = 22,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showVoicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
              0.6, // Restrict height to 60% of screen
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Select AI Voice",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyBlue,
                  ),
                ),
              ),
              if (_isLoadingVoices)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.deepSkyBlue,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _voices.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 70,
                      color: Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      final voice = _voices[index];
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: iconColor.withOpacity(0.1),
                          child: Icon(genderIcon, color: iconColor),
                        ),
                        title: Text(
                          voice["cleanName"]!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Locale: ${voice["locale"]}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing:
                            _selectedVoice?["originalName"] ==
                                voice["originalName"]
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              )
                            : const SizedBox.shrink(),
                        onTap: () {
                          setState(() => _selectedVoice = voice);
                          HiveService().saveVoice(voice);

                          _flutterTts.setVoice({
                            "name": voice["originalName"]!,
                            "locale": voice["locale"]!,
                          });

                          final currentName = _nameController.text.isNotEmpty
                              ? _nameController.text
                              : "my friend";
                          _flutterTts.speak(
                            "Hello $currentName, this is how I will sound.",
                          );

                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

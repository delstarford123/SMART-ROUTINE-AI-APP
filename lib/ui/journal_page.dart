import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/journal_model.dart';
import '../core/theme.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _winController = TextEditingController();
  final TextEditingController _distractionController = TextEditingController();
  final TextEditingController _frogController = TextEditingController();

  @override
  void dispose() {
    _winController.dispose();
    _distractionController.dispose();
    _frogController.dispose();
    super.dispose();
  }

  void _saveJournal() {
    if (_winController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your biggest win to finish your day strong!",
          ),
        ),
      );
      return;
    }

    final entry = JournalEntry(
      date: DateTime.now(),
      biggestWin: _winController.text.trim(),
      distraction: _distractionController.text.trim(),
      tomorrowFrog: _frogController.text.trim(),
    );

    Hive.box<JournalEntry>('journalBox').add(entry);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reflection saved. Rest well!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // Deep, calming evening background
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white70),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.nightlight_round,
                color: Colors.amberAccent,
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                "Evening Reflection",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Take 2 minutes to wind down and set up tomorrow for success.",
                style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 15),
              ),
              const SizedBox(height: 32),

              _buildQuestionCard(
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                question: "What was your biggest win today?",
                hint: "I finally finished that report...",
                controller: _winController,
              ),
              const SizedBox(height: 20),

              _buildQuestionCard(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.redAccent,
                question: "What distracted you the most?",
                hint: "Scrolling Instagram for an hour...",
                controller: _distractionController,
              ),
              const SizedBox(height: 20),

              _buildQuestionCard(
                icon: Icons.pest_control,
                iconColor: Colors.greenAccent,
                question: "What is your #1 'Frog' for tomorrow?",
                hint: "The hardest task I need to do first is...",
                controller: _frogController,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepSkyBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveJournal,
                  child: const Text(
                    "Save & Sleep",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required IconData icon,
    required Color iconColor,
    required String question,
    required String hint,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slightly lighter dark blue
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.blueGrey.shade600),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

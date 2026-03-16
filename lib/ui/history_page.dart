import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 🔥 NEW: Added TTS to speak the review
import '../data/hive_service.dart';
import '../data/models/task_model.dart';
import '../logic/ai_engine.dart'; // 🔥 NEW: Import AIEngine
import '../core/theme.dart';
import '../core/constants.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingReview = false;

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // 🔥 NEW: Trigger the AI Engine and Play the Audio
  void _playWeeklyReview() async {
    setState(() => _isPlayingReview = true);

    // 1. Generate the script from our new AIEngine method
    String script = await AIEngine().generateWeeklyStrategyReview();

    // 2. Configure TTS to sound natural and slightly slower for a "review"
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);

    // 3. Play the audio
    await _flutterTts.speak(script);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlayingReview = false);
      }
    });
  }

  void _stopWeeklyReview() async {
    await _flutterTts.stop();
    setState(() => _isPlayingReview = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Performance History'),
        backgroundColor: AppTheme.navyBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmClearHistory(context),
            tooltip: "Clear All History",
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Task>(AppConstants.taskBoxName).listenable(),
        builder: (context, Box<Task> box, _) {
          final history = box.values
              .where((t) => t.isSuccessful != null)
              .toList()
              .reversed
              .toList();

          if (history.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildAnalyticsDashboard(history),

              // 🔥 NEW: Weekly Strategy Audio Player Card
              _buildWeeklyAudioCard(),

              _buildEnergyMappingInsight(history),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final task = history[index];
                    return _buildHistoryCard(context, task);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  // 🔥 NEW: The Audio Player UI
  Widget _buildWeeklyAudioCard() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navyBlue, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Stop Button
          GestureDetector(
            onTap: _isPlayingReview ? _stopWeeklyReview : _playWeeklyReview,
            child: Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlayingReview ? Icons.stop : Icons.play_arrow_rounded,
                color: AppTheme.navyBlue,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Weekly Strategy Review",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlayingReview
                      ? "AI is speaking..."
                      : "Tap to listen to your AI coaching",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Audio Wave Icon
          if (_isPlayingReview)
            const Icon(Icons.graphic_eq, color: Colors.white)
          else
            const Icon(Icons.headphones, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDashboard(List<Task> history) {
    int successCount = history.where((t) => t.isSuccessful == true).length;
    int totalReviewed = history.length;
    double rate = totalReviewed == 0 ? 0 : (successCount / totalReviewed) * 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: AppTheme.navyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(
            "Success Rate",
            "${rate.toStringAsFixed(1)}%",
            AppTheme.lightBlue,
          ),
          _buildStatColumn(
            "Completed",
            successCount.toString(),
            Colors.greenAccent,
          ),
          _buildStatColumn(
            "Failed",
            (totalReviewed - successCount).toString(),
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMappingInsight(List<Task> history) {
    if (history.length < 3) return const SizedBox.shrink();

    int morningSuccess = 0, morningTotal = 0;
    int afternoonSuccess = 0, afternoonTotal = 0;
    int eveningSuccess = 0, eveningTotal = 0;

    for (var task in history) {
      int hour = task.scheduledTime.hour;
      bool success = task.isSuccessful == true;

      if (hour >= 5 && hour < 12) {
        morningTotal++;
        if (success) morningSuccess++;
      } else if (hour >= 12 && hour < 17) {
        afternoonTotal++;
        if (success) afternoonSuccess++;
      } else {
        eveningTotal++;
        if (success) eveningSuccess++;
      }
    }

    double mRate = morningTotal == 0 ? 0 : morningSuccess / morningTotal;
    double aRate = afternoonTotal == 0 ? 0 : afternoonSuccess / afternoonTotal;
    double eRate = eveningTotal == 0 ? 0 : eveningSuccess / eveningTotal;

    String bestTime = "Morning";
    if (aRate > mRate && aRate > eRate) bestTime = "Afternoon";
    if (eRate > mRate && eRate > aRate) bestTime = "Evening";

    if (mRate == 0 && aRate == 0 && eRate == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.deepSkyBlue.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: AppTheme.navyBlue, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Energy Map Insight",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your biological rhythm shows you are most successful completing tasks in the $bestTime. Plan your hardest work then!",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Task task) {
    final bool isSuccess = task.isSuccessful == true;

    return Dismissible(
      key: Key(task.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => HiveService().deleteTask(task.key),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? Colors.green : Colors.red,
              size: 30,
            ),
          ),
          title: Text(
            task.description,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "${task.scheduledTime.day}/${task.scheduledTime.month} at ${task.scheduledTime.hour}:${task.scheduledTime.minute.toString().padLeft(2, '0')}",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            "No historical data yet.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All History?"),
        content: const Text(
          "This action cannot be undone. All past data will be wiped.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              HiveService().clearAllHistory();
              Navigator.pop(context);
            },
            child: const Text("CLEAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import '../data/hive_service.dart';
import '../data/models/task_model.dart';
import '../logic/ai_engine.dart';
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

  void _playWeeklyReview() async {
    setState(() => _isPlayingReview = true);

    // Fetch the generated script from the AI Engine
    String script = await AIEngine().generateWeeklyStrategyReview();

    await _flutterTts.setSpeechRate(
      0.48,
    ); // Slightly faster for a more natural cadence
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(script);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingReview = false);
    });
  }

  void _stopWeeklyReview() async {
    await _flutterTts.stop();
    setState(() => _isPlayingReview = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50, // Lighter, premium background
        appBar: AppBar(
          title: const Text(
            'Performance History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.navyBlue,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearHistory(context),
              tooltip: "Clear Past History",
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.deepSkyBlue,
            indicatorWeight: 4,
            labelColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelColor: Colors.white60,
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: [
              Tab(icon: Icon(Icons.dashboard_rounded), text: "Overview"),
              Tab(icon: Icon(Icons.psychology_rounded), text: "Deep Work"),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<Task>(
            AppConstants.taskBoxName,
          ).listenable(),
          builder: (context, Box<Task> box, _) {
            // 🔥 FILTER: Only show tasks that have ACTUALLY been graded (History)
            final history = box.values
                .where((t) => t.isSuccessful != null)
                .toList()
                .reversed
                .toList();

            if (history.isEmpty) return _buildEmptyState();

            return TabBarView(
              children: [
                _buildOverviewTab(history),
                _buildDeepWorkTab(history),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(List<Task> history) {
    return Column(
      children: [
        _buildAnalyticsDashboard(history),
        _buildWeeklyAudioCard(),
        _buildEnergyMappingInsight(history),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: history.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(context, history[index]);
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: DEEP WORK STATISTICS
  // ==========================================
  Widget _buildDeepWorkTab(List<Task> history) {
    final successfulTasks = history
        .where((t) => t.isSuccessful == true)
        .toList();

    // 1. Calculate Active Days & Streaks safely
    Set<String> activeDays = successfulTasks.map((t) {
      return "${t.scheduledTime.year}-${t.scheduledTime.month.toString().padLeft(2, '0')}-${t.scheduledTime.day.toString().padLeft(2, '0')}";
    }).toSet();

    List<String> sortedDays = activeDays.toList()..sort();
    int longestStreak = 0;
    int currentRun = 0;
    DateTime? prevDate;

    for (String dStr in sortedDays) {
      DateTime d = DateTime.parse(dStr);
      if (prevDate == null) {
        currentRun = 1;
      } else {
        if (d.difference(prevDate).inDays == 1) {
          currentRun++;
        } else {
          currentRun = 1;
        }
      }
      if (currentRun > longestStreak) longestStreak = currentRun;
      prevDate = d;
    }

    // Current Streak Logic
    int currentStreak = 0;
    DateTime iterDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    String iterStr =
        "${iterDate.year}-${iterDate.month.toString().padLeft(2, '0')}-${iterDate.day.toString().padLeft(2, '0')}";

    if (activeDays.contains(iterStr)) {
      currentStreak++;
      iterDate = iterDate.subtract(const Duration(days: 1));
      while (activeDays.contains(
        "${iterDate.year}-${iterDate.month.toString().padLeft(2, '0')}-${iterDate.day.toString().padLeft(2, '0')}",
      )) {
        currentStreak++;
        iterDate = iterDate.subtract(const Duration(days: 1));
      }
    } else {
      iterDate = iterDate.subtract(const Duration(days: 1));
      while (activeDays.contains(
        "${iterDate.year}-${iterDate.month.toString().padLeft(2, '0')}-${iterDate.day.toString().padLeft(2, '0')}",
      )) {
        currentStreak++;
        iterDate = iterDate.subtract(const Duration(days: 1));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const Text(
          "CONSISTENCY",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        // Streak Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Current Streak",
                "$currentStreak Days",
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Longest Streak",
                "$longestStreak Days",
                Icons.emoji_events_rounded,
                AppTheme.deepSkyBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        const Text(
          "LIFETIME FOCUS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        // Lifetime Cards
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildColumnStat(
                  "Completed",
                  successfulTasks.length.toString(),
                  Colors.green,
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade200),
                _buildColumnStat(
                  "Failed/Skipped",
                  (history.length - successfulTasks.length).toString(),
                  Colors.redAccent,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
        _buildLast7DaysChart(activeDays),
      ],
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.navyBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLast7DaysChart(Set<String> activeDays) {
    List<Widget> dayColumns = [];
    DateTime today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime d = today.subtract(Duration(days: i));
      String dStr =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      bool isActive = activeDays.contains(dStr);
      String dayName = ["M", "T", "W", "T", "F", "S", "S"][d.weekday - 1];

      dayColumns.add(
        Column(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.deepSkyBlue : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check_rounded : Icons.close_rounded,
                color: isActive ? Colors.white : Colors.grey.shade400,
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dayName,
              style: TextStyle(
                color: isActive ? AppTheme.navyBlue : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "LAST 7 DAYS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: dayColumns,
            ),
          ),
        ),
      ],
    );
  }

  // --- OVERVIEW UI COMPONENTS ---

  Widget _buildWeeklyAudioCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPlayingReview
              ? [
                  AppTheme.deepSkyBlue,
                  AppTheme.navyBlue,
                ] // Dynamic pulse colors
              : [AppTheme.navyBlue, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isPlayingReview
                ? AppTheme.deepSkyBlue.withOpacity(0.5)
                : AppTheme.navyBlue.withOpacity(0.3),
            blurRadius: _isPlayingReview ? 25 : 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isPlayingReview ? _stopWeeklyReview : _playWeeklyReview,
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isPlayingReview
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                color: AppTheme.navyBlue,
                size: 34,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Weekly Strategy Review",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlayingReview
                      ? "AI is analyzing & speaking..."
                      : "Tap to listen to your AI coach",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isPlayingReview)
            const Icon(Icons.graphic_eq_rounded, color: Colors.white)
          else
            const Icon(Icons.headphones_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDashboard(List<Task> history) {
    int successCount = history.where((t) => t.isSuccessful == true).length;
    int totalReviewed = history.length;
    double rate = totalReviewed == 0 ? 0 : (successCount / totalReviewed) * 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: AppTheme.navyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTopStatColumn(
            "Success Rate",
            "${rate.toStringAsFixed(1)}%",
            AppTheme.lightBlue,
          ),
          Container(height: 40, width: 1, color: Colors.white24), // Divider
          _buildTopStatColumn(
            "Completed",
            successCount.toString(),
            Colors.greenAccent,
          ),
          Container(height: 40, width: 1, color: Colors.white24), // Divider
          _buildTopStatColumn(
            "Skipped",
            (totalReviewed - successCount).toString(),
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatColumn(String label, String value, Color color) {
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.deepSkyBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.deepSkyBlue.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: AppTheme.navyBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Energy Map Insight",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyBlue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your biological rhythm shows you are most successful completing tasks in the $bestTime. Plan your hardest work then!",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key(task.key.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_sweep_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        onDismissed: (_) => HiveService().deleteTask(task.key),
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.do_not_disturb_on_rounded,
                color: isSuccess ? Colors.green : Colors.grey.shade600,
                size: 28,
              ),
            ),
            title: Text(
              task.description,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isSuccess ? Colors.black87 : Colors.grey.shade600,
                decoration: isSuccess ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat(
                      "MMM d, yyyy • h:mm a",
                    ).format(task.scheduledTime),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No historical data yet.",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Complete or skip tasks today to build your history.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Clear Past History?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will permanently delete all completed and skipped tasks. Your future tasks will remain safe.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              // 🔥 FIXED LOGIC: Only delete tasks that have actually been graded!
              final box = Hive.box<Task>(AppConstants.taskBoxName);
              final keysToDelete = box.values
                  .where((t) => t.isSuccessful != null)
                  .map((t) => t.key)
                  .toList();

              await box.deleteAll(keysToDelete);

              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "CLEAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

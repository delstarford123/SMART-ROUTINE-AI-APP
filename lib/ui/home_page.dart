import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../logic/plan_provider.dart';
import '../logic/calendar_provider.dart';
import '../logic/internet_provider.dart';
import '../core/theme.dart';
import '../core/time_utils.dart';
import '../data/models/task_model.dart';
import '../data/models/journal_model.dart';
import 'vision_board_page.dart';
import 'planning_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'focus_mode_page.dart';
import 'coaching_page.dart';
import 'journal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  final FlutterTts _flutterTts = FlutterTts();
  int? _speakingTaskKey;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<PlanProvider>(
        context,
        listen: false,
      ).loadTasksForDate(_selectedDate);
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).loadEventsForDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // --- Core AI Audio Logic ---
  Future<void> _speakTaskAdvice(int taskKey, String? advice) async {
    if (advice == null || advice.isEmpty) {
      _showSnackBar("No AI advice available for this task.", Colors.blueGrey);
      return;
    }

    if (_speakingTaskKey == taskKey) {
      await _flutterTts.stop();
      if (mounted) setState(() => _speakingTaskKey = null);
      return;
    }

    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);

    if (mounted) setState(() => _speakingTaskKey = taskKey);
    await _flutterTts.speak(advice);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingTaskKey = null);
    });
  }

  // --- Navigation & Utility Methods ---
  void _changeDate(int daysToAdd) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: daysToAdd));
    });
    _refreshData();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Reset System?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This permanently deletes all tasks, AI learning, and custom settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await Provider.of<PlanProvider>(
                context,
                listen: false,
              ).nukeHistory();
              if (Hive.isBoxOpen('settings')) {
                await Hive.box('settings').clear();
              }
              Navigator.pop(ctx);
              _refreshData();
              _showSnackBar("System Nuke Complete", Colors.redAccent);
            },
            child: const Text(
              "Delete Everything",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Modern, premium background
      appBar: AppBar(
        title: const Text(
          'Smart Routine',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: false,
        backgroundColor: AppTheme.navyBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.rocket_launch_outlined, color: Colors.white),
            tooltip: "Vision Board",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisionBoardPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.school, color: Colors.white),
            tooltip: "AI Coach",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoachingPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            tooltip: "Performance History",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),
          _buildMoreMenu(),
        ],
      ),
      body: Column(
        children: [
          _buildOfflineBanner(),
          _buildDateNavigator(),
          _buildEveningReflectionPrompt(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshData(),
              color: AppTheme.deepSkyBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Today's Objectives"),
                    const SizedBox(height: 12),
                    _buildTaskList(),
                    const SizedBox(height: 30),
                    _buildSectionHeader("Calendar Integration"),
                    const SizedBox(height: 12),
                    _buildCalendarList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlanningPage()),
        ).then((_) => _refreshData()),
        backgroundColor: AppTheme.navyBlue,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          "NEW TASK",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // =========================================================================
  // SUB-WIDGETS & UI COMPONENTS
  // =========================================================================

  Widget _buildEveningReflectionPrompt() {
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour < 4) {
      if (Hive.isBoxOpen('journalBox')) {
        final box = Hive.box<JournalEntry>('journalBox');
        if (box.isNotEmpty) {
          final lastEntryDate = box.values.last.date;
          if (now.difference(lastEntryDate).inHours < 6) {
            return const SizedBox.shrink();
          }
        }
      }
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalPage()),
        ).then((_) => setState(() {})),
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.nightlight_round,
                color: Colors.amberAccent,
                size: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Evening Reflection",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "It's late. Take 2 mins to log your wins and set tomorrow's Frog.",
                      style: TextStyle(
                        color: Colors.blueGrey.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOfflineBanner() {
    return Consumer<InternetProvider>(
      builder: (context, internet, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: internet.hasInternet ? 0 : 35,
        color: Colors.orange.shade800,
        child: const Center(
          child: Text(
            "Offline Mode: AI Coach is resting",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.navyBlue,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            _isToday(_selectedDate)
                ? "TODAY"
                : DateFormat('EEEE, MMM d').format(_selectedDate).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Colors.blueGrey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TASK LIST BUILDERS
  // =========================================================================

  Widget _buildTaskList() {
    return Consumer<PlanProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (provider.todaysTasks.isEmpty) {
          return _buildEmptyState("No tasks planned. Tap 'New Task' to begin.");
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.todaysTasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildTaskCard(provider.todaysTasks[index], index, provider);
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, int index, PlanProvider provider) {
    final bool isDone = task.isSuccessful == true;
    final bool isFailed = task.isSuccessful == false;

    final now = DateTime.now();

    // 🔥 Uses the actual saved end time from PlanningPage
    final DateTime exactEndTime =
        task.endTime ?? task.scheduledTime.add(const Duration(hours: 1));

    final bool hasStarted =
        now.isAfter(task.scheduledTime) ||
        now.isAtSameMomentAs(task.scheduledTime);
    final bool isTaskEnded = now.isAfter(exactEndTime);
    final bool isTaskActive = hasStarted && !isTaskEnded;

    final bool isHighRisk =
        task.aiWarning?.toLowerCase().contains(RegExp(r'low|critical')) ??
        false;

    final startTimeStr = DateFormat.jm().format(task.scheduledTime);
    final endTimeStr = DateFormat.jm().format(exactEndTime);

    return Dismissible(
      key: Key(task.key.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.removeTask(task);
        _showSnackBar("${task.description} deleted.", Colors.blueGrey);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDone || isFailed ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? Colors.green.withOpacity(0.3)
                : (isFailed
                      ? Colors.red.withOpacity(0.3)
                      : (isHighRisk
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.grey.shade200)),
            width: 1.5,
          ),
          boxShadow: isDone || isFailed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // LAYER 1: The Time Pill & Status Badge
              // ----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dedicated Time Pill wrapped in Flexible to prevent overflow!
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppTheme.navyBlue,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "$startTimeStr - $endTimeStr",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.navyBlue,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🔥 Dynamic Status Badges (Completed vs Killed/Exited)
                  if (isDone)
                    _buildStatusBadge("Completed", Colors.green)
                  else if (isFailed)
                    _buildStatusBadge("Killed/Exited", Colors.grey.shade700)
                  else if (!hasStarted)
                    _buildStatusBadge("Upcoming", Colors.orange.shade700)
                  else if (isTaskActive)
                    _buildStatusBadge("In Progress", Colors.blue)
                  else if (isTaskEnded)
                    _buildStatusBadge("Pending Review", Colors.redAccent),
                ],
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------
              // LAYER 2: Task Description
              // ----------------------------------------------------
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: isDone || isFailed
                      ? TextDecoration.lineThrough
                      : null,
                  color: isDone || isFailed ? Colors.grey : Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------
              // LAYER 3: Action Buttons
              // ----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Tools (AI, Focus Mode)
                  Row(
                    children: [
                      if (task.aiWarning != null && task.aiWarning!.isNotEmpty)
                        _buildIconButton(
                          icon: _speakingTaskKey == task.key
                              ? Icons.stop_circle
                              : Icons.record_voice_over,
                          color: isHighRisk
                              ? Colors.red.shade400
                              : Colors.blueGrey.shade400,
                          onTap: () =>
                              _speakTaskAdvice(task.key, task.aiWarning),
                        ),
                      const SizedBox(width: 8),
                      if (!isDone && !isFailed)
                        _buildIconButton(
                          icon: Icons.play_arrow_rounded,
                          color: AppTheme.deepSkyBlue,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FocusModePage(task: task),
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                task.isSuccessful = true;
                              }); // 🔥 Instant Update
                              await provider.updateTaskStatus(index, true);
                              _refreshData();
                            }
                          },
                        ),
                    ],
                  ),

                  // Right Tools (Tick, X)
                  Row(
                    children: [
                      // ✅ SUCCESS BUTTON
                      _buildPillButton(
                        label: "DONE",
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        isActive: !isDone && !isFailed,
                        onTap: () async {
                          // 🔥 Instant UI Update Logic
                          setState(() {
                            task.isSuccessful = true;
                          });
                          // Database Save
                          await provider.updateTaskStatus(index, true);
                          _refreshData();
                          _showSnackBar(
                            "Task completed! Great job.",
                            Colors.green,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // ❌ FAIL BUTTON
                      _buildPillButton(
                        label: "KILL",
                        icon: Icons.close_rounded,
                        color: Colors.redAccent,
                        isActive: !isDone && !isFailed,
                        onTap: () async {
                          // 🔥 Instant UI Update Logic
                          setState(() {
                            task.isSuccessful = false;
                          });
                          // Database Save
                          await provider.updateTaskStatus(index, false);
                          _refreshData();
                          _showSnackBar(
                            "Task Killed/Exited.",
                            Colors.redAccent,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // ----------------------------------------------------
              // LAYER 4: AI Warning Dropdown
              // ----------------------------------------------------
              if (task.aiWarning != null &&
                  task.aiWarning!.isNotEmpty &&
                  !isDone &&
                  !isFailed)
                _buildAIWarning(task.aiWarning!, isHighRisk),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.3,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIWarning(String text, bool isHighRisk) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighRisk ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighRisk
              ? Colors.red.withOpacity(0.2)
              : AppTheme.lightBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHighRisk ? Icons.warning_amber_rounded : Icons.auto_awesome,
            color: isHighRisk ? Colors.red : AppTheme.deepSkyBlue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isHighRisk ? Colors.red.shade900 : AppTheme.navyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CALENDAR BUILDER
  // =========================================================================

  Widget _buildCalendarList() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const LinearProgressIndicator();
        if (provider.events.isEmpty) {
          return _buildEmptyState("Your calendar is clear today.");
        }

        return Column(
          children: provider.events
              .map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      e.title ?? "Meeting",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      e.start != null
                          ? DateFormat.jm().format(e.start!)
                          : "All Day",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // --- Menu Setup ---
  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (val) {
        if (val == 'clear') {
          _showClearHistoryDialog(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'settings', child: Text("Settings")),
        const PopupMenuItem(
          value: 'clear',
          child: Text("Reset App Data", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

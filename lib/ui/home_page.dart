import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:device_calendar/device_calendar.dart' as cal;

import '../logic/plan_provider.dart';
import '../logic/calendar_service.dart';
import '../core/theme.dart';
import 'planning_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import '../core/time_utils.dart';
import 'focus_mode_page.dart'; // 🔥 NEW: Import the Focus Mode Page

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();

  // Offline State Variables
  bool _hasInternet = true;
  late StreamSubscription<InternetConnectionStatus> _connectionSubscription;

  // Calendar State Variables
  List<cal.Event> _calendarEvents = [];
  bool _isLoadingCalendar = false;

  @override
  void initState() {
    super.initState();

    // Load tasks for the initial selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlanProvider>(
        context,
        listen: false,
      ).loadTasksForDate(_selectedDate);

      // Fetch calendar events on startup
      _loadCalendarEvents(_selectedDate);
    });

    _setupNetworkListener();
  }

  Future<void> _loadCalendarEvents(DateTime date) async {
    setState(() => _isLoadingCalendar = true);
    final events = await CalendarService().getEventsForDate(date);
    if (mounted) {
      setState(() {
        _calendarEvents = events;
        _isLoadingCalendar = false;
      });
    }
  }

  void _setupNetworkListener() async {
    _hasInternet = await InternetConnectionChecker.instance.hasConnection;
    if (mounted) setState(() {});

    _connectionSubscription = InternetConnectionChecker.instance.onStatusChange
        .listen((InternetConnectionStatus status) {
          if (mounted) {
            setState(() {
              _hasInternet = status == InternetConnectionStatus.connected;
            });
          }
        });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  void _changeDate(int daysToAdd) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: daysToAdd));
    });
    // Refresh both Tasks AND Calendar events when the day changes
    Provider.of<PlanProvider>(
      context,
      listen: false,
    ).loadTasksForDate(_selectedDate);
    _loadCalendarEvents(_selectedDate);
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Wipe All History?"),
        content: const Text(
          "This will permanently delete all your tasks and AI learning data for privacy. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PlanProvider>(context, listen: false).nukeHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All history permanently deleted."),
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Slightly off-white background
      appBar: AppBar(
        title: const Text(
          'Smart Routine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: "Performance History",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog(context);
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20, color: Colors.black54),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        'Clear All History',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _hasInternet ? 0 : 30,
            width: double.infinity,
            color: Colors.redAccent,
            alignment: Alignment.center,
            child: _hasInternet
                ? const SizedBox.shrink()
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Offline Mode - AI features limited",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),

          // Date Navigator Header
          Container(
            color: AppTheme.navyBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => _changeDate(-1),
                ),
                Text(
                  _isToday(_selectedDate)
                      ? "Today"
                      : DateFormat('EEE, MMM d').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),

          // --- UI SPLIT: Scrollable Area for Tasks and Calendar ---
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. PERSONAL TASKS SECTION ---
                    const Text(
                      "Your Tasks",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navyBlue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Consumer<PlanProvider>(
                      builder: (context, planProvider, child) {
                        if (planProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (planProvider.todaysTasks.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              "No tasks planned. Tap + to add one!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // shrinkWrap: true is required when ListView is inside SingleChildScrollView
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: planProvider.todaysTasks.length,
                          itemBuilder: (context, index) {
                            final task = planProvider.todaysTasks[index];
                            final isDone = task.isSuccessful == true;
                            final isFailed = task.isSuccessful == false;

                            return Dismissible(
                              key: Key(task.key.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              onDismissed: (direction) {
                                planProvider.removeTask(task);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${task.description} deleted.",
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: isDone ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isDone
                                        ? Colors.green.shade200
                                        : isFailed
                                        ? Colors.red.shade200
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                color: isDone
                                    ? Colors.grey.shade50
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: AppTheme.navyBlue
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                getFormattedTime(
                                                  context,
                                                  task.scheduledTime,
                                                ),
                                                style: TextStyle(
                                                  color: AppTheme.navyBlue
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // 🔥 NEW: Play Button to trigger Focus Mode
                                              if (!isDone && !isFailed)
                                                IconButton(
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.play_circle_fill,
                                                    color: AppTheme.deepSkyBlue,
                                                    size: 30,
                                                  ),
                                                  onPressed: () async {
                                                    // Route to the new Focus Mode Page
                                                    final result =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                FocusModePage(
                                                                  task: task,
                                                                ),
                                                          ),
                                                        );

                                                    // Automatically check off task if focus mode completed successfully
                                                    if (result == true) {
                                                      planProvider
                                                          .updateTaskStatus(
                                                            index,
                                                            true,
                                                          );
                                                    }
                                                  },
                                                ),

                                              // Check Button
                                              IconButton(
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                                icon: Icon(
                                                  Icons.check_circle,
                                                  color: isDone
                                                      ? Colors.green
                                                      : Colors.grey.shade400,
                                                  size: 28,
                                                ),
                                                onPressed: () => planProvider
                                                    .updateTaskStatus(
                                                      index,
                                                      true,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Cancel Button
                                              IconButton(
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                                icon: Icon(
                                                  Icons.cancel,
                                                  color: isFailed
                                                      ? Colors.red
                                                      : Colors.grey.shade400,
                                                  size: 28,
                                                ),
                                                onPressed: () => planProvider
                                                    .updateTaskStatus(
                                                      index,
                                                      false,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        task.description,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isDone
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (task.aiWarning != null &&
                                          task.aiWarning!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightBlue
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.lightBlue
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.auto_awesome,
                                                size: 16,
                                                color: AppTheme.deepSkyBlue,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  task.aiWarning!,
                                                  style: const TextStyle(
                                                    color: AppTheme.navyBlue,
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- 2. SCHEDULED EVENTS SECTION (READ-ONLY) ---
                    const Text(
                      "Calendar Events",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingCalendar)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_calendarEvents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          "No meetings or events scheduled.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _calendarEvents.length,
                        itemBuilder: (context, index) {
                          final event = _calendarEvents[index];

                          // Format start and end times cleanly
                          String timeString = "All Day";
                          if (event.start != null && event.end != null) {
                            timeString =
                                "${DateFormat.jm().format(event.start!)} - ${DateFormat.jm().format(event.end!)}";
                          } else if (event.start != null) {
                            timeString = DateFormat.jm().format(event.start!);
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            color: Colors.blueGrey.shade50, // Distinct styling
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event,
                                  color: Colors.blueGrey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                event.title ?? "Untitled Event",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                timeString,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(
                      height: 80,
                    ), // Padding for Floating Action Button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.navyBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Plan Task",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlanningPage()),
          ).then((_) {
            Provider.of<PlanProvider>(
              context,
              listen: false,
            ).loadTasksForDate(_selectedDate);
            _loadCalendarEvents(_selectedDate); // Refresh events too
          });
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

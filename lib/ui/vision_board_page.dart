import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../data/models/goal_model.dart';
import '../core/theme.dart';

class VisionBoardPage extends StatefulWidget {
  const VisionBoardPage({Key? key}) : super(key: key);

  @override
  State<VisionBoardPage> createState() => _VisionBoardPageState();
}

class _VisionBoardPageState extends State<VisionBoardPage> {
  late Box<Goal> _goalBox;

  @override
  void initState() {
    super.initState();
    _goalBox = Hive.box<Goal>('goalsBox');
  }

  void _deleteGoal(Goal goal) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              "Delete Milestone?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to remove this goal from your Vision Board? This action cannot be undone.",
          style: TextStyle(color: Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await goal.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Milestone deleted successfully.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blueGrey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // 🔥 NEW: Remembrance Details View
  void _showGoalDetails(Goal goal) {
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final baseColor = Color(goal.colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [baseColor.withOpacity(0.8), baseColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(goal.iconCode, fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      goal.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Details Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "THE VISION",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        goal.description,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_available,
                              color: baseColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Target Deadline",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'MMMM d, yyyy',
                                ).format(goal.deadline),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.navyBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (daysLeft >= 0 ? Colors.green : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.timer,
                              color: daysLeft >= 0 ? Colors.green : Colors.red,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Time Remaining",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                daysLeft > 0
                                    ? "$daysLeft Days"
                                    : (daysLeft == 0
                                          ? "Today is the day!"
                                          : "Overdue by ${daysLeft.abs()} Days"),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: daysLeft >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Premium light background
      appBar: AppBar(
        title: const Text(
          'Vision Board',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.navyBlue,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.navyBlue),
        centerTitle: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: _goalBox.listenable(),
        builder: (context, Box<Goal> box, _) {
          final goals = box.values.toList().reversed.toList();

          if (goals.isEmpty) {
            return _buildEmptyState();
          }

          // TRUE MASONRY ALGORITHM
          List<Goal> leftColumn = [];
          List<Goal> rightColumn = [];
          double leftHeight = 0;
          double rightHeight = 0;

          for (var goal in goals) {
            double cardHeight = 160.0 + (goal.description.length % 50);
            if (leftHeight <= rightHeight) {
              leftColumn.add(goal);
              leftHeight += cardHeight + 16;
            } else {
              rightColumn.add(goal);
              rightHeight += cardHeight + 16;
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: leftColumn
                        .map((goal) => _buildGoalCard(goal))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: rightColumn
                        .map((goal) => _buildGoalCard(goal))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.navyBlue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "NEW MILESTONE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddGoalModal(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.deepSkyBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 64,
                color: AppTheme.deepSkyBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your vision board is empty.",
              style: TextStyle(
                color: AppTheme.navyBlue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Big journeys begin with small steps. Tap the button below to define your first major life milestone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final double cardHeight = 170.0 + (goal.description.length % 60);

    // SMART DEADLINE LOGIC
    final now = DateTime.now();
    final targetDate = DateTime(
      goal.deadline.year,
      goal.deadline.month,
      goal.deadline.day,
    );
    final todayDate = DateTime(now.year, now.month, now.day);
    final daysLeft = targetDate.difference(todayDate).inDays;

    String deadlineText;
    Color badgeColor;

    if (daysLeft > 1) {
      deadlineText = "$daysLeft Days Left";
      badgeColor = Colors.black.withOpacity(0.25);
    } else if (daysLeft == 1) {
      deadlineText = "Tomorrow";
      badgeColor = Colors.orange.withOpacity(0.9);
    } else if (daysLeft == 0) {
      deadlineText = "Today";
      badgeColor = Colors.redAccent.withOpacity(0.9);
    } else {
      deadlineText = "Overdue";
      badgeColor = Colors.red.shade900.withOpacity(0.9);
    }

    final baseColor = Color(goal.colorValue);

    return GestureDetector(
      onTap: () => _showGoalDetails(goal), // 🔥 Opens Details View
      child: Container(
        width: double.infinity,
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor.withOpacity(0.85), baseColor],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconData(goal.iconCode, fontFamily: 'MaterialIcons'),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    goal.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      goal.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deadlineText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'delete') _deleteGoal(goal);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Delete Milestone",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// ADD GOAL BOTTOM SHEET MODAL (Polished & Expanded)
// =========================================================================

class AddGoalModal extends StatefulWidget {
  const AddGoalModal({Key? key}) : super(key: key);

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90));

  // 🔥 EXTENDED: 20 Premium UI Colors
  final List<Color> _colors = [
    AppTheme.navyBlue,
    AppTheme.deepSkyBlue,
    const Color(0xFF10B981),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
    const Color(0xFF06B6D4),
    const Color(0xFF6366F1),
    const Color(0xFF3B82F6),
    const Color(0xFFD946EF),
    const Color(0xFF84CC16),
    const Color(0xFFEAB308),
    const Color(0xFF78716C),
    const Color(0xFF64748B),
    const Color(0xFF0F766E),
    const Color(0xFFBE123C),
    const Color(0xFF4338CA),
  ];
  late Color _selectedColor;

  // 🔥 EXTENDED: 50 Carefully Curated Icons
  final List<IconData> _icons = [
    // General / Goals
    Icons.rocket_launch_rounded,
    Icons.flag_rounded,
    Icons.star_rounded,
    Icons.emoji_events_rounded,
    Icons.diamond_rounded,
    // Work / Business
    Icons.laptop_mac_rounded,
    Icons.business_center_rounded,
    Icons.lightbulb_rounded,
    Icons.pie_chart_rounded,
    Icons.trending_up_rounded,
    // Finance / Wealth
    Icons.attach_money_rounded,
    Icons.account_balance_rounded,
    Icons.savings_rounded,
    Icons.credit_card_rounded,
    Icons.monetization_on_rounded,
    // Health / Fitness
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.favorite_rounded,
    Icons.sports_tennis_rounded,
    Icons.self_improvement_rounded,
    Icons.restaurant_rounded,
    Icons.local_hospital_rounded,
    Icons.spa_rounded,
    Icons.water_drop_rounded,
    Icons.monitor_heart_rounded,
    // Education / Growth
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.science_rounded,
    Icons.architecture_rounded,
    Icons.code_rounded,
    // Lifestyle / Travel
    Icons.flight_takeoff_rounded,
    Icons.sailing_rounded,
    Icons.directions_car_rounded,
    Icons.landscape_rounded,
    Icons.camera_alt_rounded,
    Icons.home_rounded,
    Icons.festival_rounded,
    Icons.music_note_rounded,
    Icons.palette_rounded,
    Icons.brush_rounded,
    // Social / Relationships
    Icons.diversity_3_rounded,
    Icons.family_restroom_rounded,
    Icons.groups_rounded,
    Icons.volunteer_activism_rounded,
    Icons.pets_rounded,
    // Tech / Tools
    Icons.mic_rounded,
    Icons.videocam_rounded,
    Icons.key_rounded,
    Icons.anchor_rounded,
    Icons.shield_rounded,
  ];
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors[0];
    _selectedIcon = _icons[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.navyBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveGoal() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Title cannot be empty!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newGoal = Goal(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      deadline: _selectedDate,
      colorValue: _selectedColor.value,
      iconCode: _selectedIcon.codePoint,
    );

    Hive.box<Goal>('goalsBox').add(newGoal);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "🚀 Milestone locked in!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Define Your Milestone",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.navyBlue,
              ),
            ),
            const SizedBox(height: 20),

            // Title Field
            TextField(
              controller: _titleController,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Goal Title",
                hintText: "e.g., Run a Marathon",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.deepSkyBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Why is this important?",
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.deepSkyBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Deadline Picker
            const Text(
              "Target Deadline",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.deepSkyBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navyBlue,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔥 2-Row Horizontal Scroll Pickers for large lists
            const Text(
              "Theme Color",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100, // Enough for 2 rows
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black87, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Milestone Icon",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100, // Enough for 2 rows
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _selectedColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: _saveGoal,
                child: const Text(
                  "SAVE MILESTONE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

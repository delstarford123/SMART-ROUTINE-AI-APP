import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../logic/plan_provider.dart';
import '../logic/alarm_manager.dart';
import '../data/models/task_model.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../logic/nlp_engine.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({Key? key}) : super(key: key);

  @override
  _PlanningPageState createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  final TextEditingController _taskController = TextEditingController();
  final NLPEngine _nlpEngine = NLPEngine();
  final AlarmService _alarmService = AlarmService(); // Use singleton

  late stt.SpeechToText _speech;
  bool _isListening = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  TimeOfDay? _wakeUpTime;

  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _taskController.text = val.recognizedWords;
            _handleSmartTimeExtraction(val.recognizedWords);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _handleSmartTimeExtraction(String text) {
    TimeOfDay? extracted = _nlpEngine.extractTime(text);
    if (extracted != null) {
      setState(() => _selectedTime = extracted);
    }
  }

  DateTime _combineDateAndTime(TimeOfDay time) {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  // --- Core Save Logic ---

  Future<void> _saveTask() async {
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your task first!')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // 1. Create the Task Object
      final task = Task(
        description: _taskController.text.trim(),
        scheduledTime: _combineDateAndTime(_selectedTime),
      );

      // 2. Save to Hive via Provider (Includes AI Analysis)
      await Provider.of<PlanProvider>(
        context,
        listen: false,
      ).addTaskWithAnalysis(
        task,
        AppConstants.defaultLat,
        AppConstants.defaultLon,
      );

      // 3. Trigger Alarms (Start & End)
      // This uses the automatic dual-alarm logic we built
      await _alarmService.scheduleStartAndEndAlarms(task);

      // 4. Handle Specific End Time Alarm (If custom-picked)
      if (_endTime != null) {
        await _alarmService.setTaskEndTimeAlarm(
          _combineDateAndTime(_endTime!),
          task.alarmId + 2, // Ensure it doesn't clash with start/end IDs
          task.description,
        );
      }

      // 5. Handle Wake-Up Alarm
      if (_wakeUpTime != null) {
        await _alarmService.setWakeUpAlarm(_combineDateAndTime(_wakeUpTime!));
      }

      _taskController.clear();
      setState(() => _endTime = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule synced and Alarms set!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error saving task: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('New Routine'),
        elevation: 0,
        backgroundColor: AppTheme.navyBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader("Task Details"),
            const SizedBox(height: 16),
            _buildTaskInput(),
            const SizedBox(height: 20),
            _buildSectionHeader("Scheduling"),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 12),
            _buildTimePickerRow(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _buildSectionHeader("Routine Optimization"),
            const SizedBox(height: 12),
            _buildWakeUpPicker(),
            const SizedBox(height: 40),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // --- Sub-Widgets for Clarity ---

  Widget _buildTaskInput() {
    return TextField(
      controller: _taskController,
      onChanged: _handleSmartTimeExtraction,
      decoration: InputDecoration(
        labelText: 'What is the plan?',
        hintText: 'e.g., Gym at 6:00 PM',
        prefixIcon: const Icon(
          Icons.edit_calendar,
          color: AppTheme.deepSkyBlue,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : AppTheme.navyBlue,
          ),
          onPressed: _listen,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDatePicker() {
    return _buildPickerTile(
      icon: Icons.calendar_month,
      label: "Date",
      value: DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
    );
  }

  Widget _buildTimePickerRow() {
    return Row(
      children: [
        Expanded(
          child: _buildPickerTile(
            icon: Icons.access_time,
            label: "Start Time",
            value: _selectedTime.format(context),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) setState(() => _selectedTime = time);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerTile(
            icon: Icons.timer_outlined,
            label: "End Time (Alarm)",
            value: _endTime?.format(context) ?? "Optional",
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) setState(() => _endTime = time);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWakeUpPicker() {
    return _buildPickerTile(
      icon: Icons.wb_sunny_outlined,
      label: "Daily Wake Up Time",
      value: _wakeUpTime?.format(context) ?? "Not Set",
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 7, minute: 0),
        );
        if (time != null) setState(() => _wakeUpTime = time);
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.navyBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isAnalyzing ? null : _saveTask,
        child: _isAnalyzing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Add to Schedule",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

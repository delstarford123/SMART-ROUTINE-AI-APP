import 'dart:async';
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
  final AlarmService _alarmService = AlarmService();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late TimeOfDay _endTime;
  TimeOfDay? _wakeUpTime;

  bool _endTimeManuallySet = false;
  String _selectedRecurrence = 'Does not repeat';
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _speechToText.initialize();
    _calculateDefaultEndTime();
  }

  void _calculateDefaultEndTime() {
    if (_endTimeManuallySet) return;

    int hour = _selectedTime.hour + 1;
    if (hour >= 24) hour = hour - 24;
    _endTime = TimeOfDay(hour: hour, minute: _selectedTime.minute);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _taskController.text = result.recognizedWords;
              _handleSmartTimeExtraction(result.recognizedWords);
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _handleSmartTimeExtraction(String text) {
    TimeOfDay? extracted = _nlpEngine.extractTime(text);
    if (extracted != null) {
      setState(() {
        _selectedTime = extracted;
        _calculateDefaultEndTime();
      });
    }
  }

  Future<void> _showRecurrencePicker() async {
    FocusScope.of(context).unfocus(); // Drop keyboard

    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text(
            'Select Recurrence',
            style: TextStyle(
              color: AppTheme.navyBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          children: <Widget>[
            _buildDialogOption('Does not repeat', Icons.close),
            _buildDialogOption('Every Day', Icons.today),
            _buildDialogOption('Every Week', Icons.view_week),
            _buildDialogOption('Every Month', Icons.calendar_month),
            _buildDialogOption('Every Year', Icons.event_repeat),
          ],
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRecurrence = picked);
    }
  }

  SimpleDialogOption _buildDialogOption(String text, IconData icon) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.deepSkyBlue, size: 20),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTask() async {
    FocusScope.of(context).unfocus(); // Drop keyboard when saving

    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your task first!')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      int loopCount = 1;
      if (_selectedRecurrence == 'Every Day') loopCount = 7;
      if (_selectedRecurrence == 'Every Week') loopCount = 4;
      if (_selectedRecurrence == 'Every Month') loopCount = 3;
      if (_selectedRecurrence == 'Every Year') loopCount = 2;

      List<Future<void>> backgroundOperations = [];

      for (int i = 0; i < loopCount; i++) {
        DateTime targetDate = _selectedDate;
        if (_selectedRecurrence == 'Every Day') {
          targetDate = _selectedDate.add(Duration(days: i));
        } else if (_selectedRecurrence == 'Every Week') {
          targetDate = _selectedDate.add(Duration(days: i * 7));
        } else if (_selectedRecurrence == 'Every Month') {
          targetDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + i,
            _selectedDate.day,
          );
        } else if (_selectedRecurrence == 'Every Year') {
          targetDate = DateTime(
            _selectedDate.year + i,
            _selectedDate.month,
            _selectedDate.day,
          );
        }

        DateTime startDateTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        DateTime endDateTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          _endTime.hour,
          _endTime.minute,
        );

        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }

        final task = Task(
          description: _taskController.text.trim(),
          scheduledTime: startDateTime,
          endTime: endDateTime,
        );

        backgroundOperations.add(
          Future(() async {
            await Provider.of<PlanProvider>(
              context,
              listen: false,
            ).addTaskWithAnalysis(
              task,
              AppConstants.defaultLat,
              AppConstants.defaultLon,
            );

            if (_wakeUpTime != null && i == 0) {
              DateTime wakeDateTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                _wakeUpTime!.hour,
                _wakeUpTime!.minute,
              );
              await _alarmService.setWakeUpAlarm(wakeDateTime);
            }
          }),
        );
      }

      await Future.wait(backgroundOperations);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving task: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // 🔥 Tapping outside drops keyboard
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'New Routine',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: AppTheme.navyBlue,
          iconTheme: const IconThemeData(color: Colors.white),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildSectionHeader("Scheduling")],
              ),
              const SizedBox(height: 12),

              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildTimePickerRow(),
              const SizedBox(height: 12),

              _buildPickerTile(
                icon: Icons.repeat,
                label: "Recurrence",
                value: _selectedRecurrence,
                onTap: _showRecurrencePicker,
              ),

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
      ),
    );
  }

  Widget _buildTaskInput() {
    return TextField(
      controller: _taskController,
      onChanged: _handleSmartTimeExtraction,
      maxLines: 2,
      minLines: 1,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.navyBlue,
      ),
      decoration: InputDecoration(
        labelText: 'What is the plan?',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.normal,
        ),
        hintText: 'e.g., Gym at 6:00 PM',
        prefixIcon: const Icon(
          Icons.edit_calendar,
          color: AppTheme.deepSkyBlue,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.redAccent : AppTheme.navyBlue,
            size: _isListening ? 28 : 24,
          ),
          onPressed: _toggleListening,
          tooltip: "Hold to Dictate Task",
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.deepSkyBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDatePicker() {
    return _buildPickerTile(
      icon: Icons.calendar_month,
      label: "Starting Date",
      value: DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
      onTap: () async {
        FocusScope.of(context).unfocus(); // 🔥 Hide keyboard
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
              FocusScope.of(context).unfocus(); // 🔥 START CLOSING KEYBOARD
              await Future.delayed(
                const Duration(milliseconds: 300),
              ); // 🔥 WAIT FOR ANIMATION

              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                  _calculateDefaultEndTime();
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerTile(
            icon: Icons.timer_outlined,
            label: "End Time",
            value: _endTime.format(context),
            onTap: () async {
              FocusScope.of(context).unfocus(); // 🔥 START CLOSING KEYBOARD
              await Future.delayed(
                const Duration(milliseconds: 300),
              ); // 🔥 WAIT FOR ANIMATION

              final time = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                  _endTimeManuallySet = true;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWakeUpPicker() {
    return _buildPickerTile(
      icon: Icons.wb_sunny_outlined,
      label: "Daily Wake Up Time Override",
      value: _wakeUpTime?.format(context) ?? "Use Global Settings",
      onTap: () async {
        FocusScope.of(context).unfocus(); // 🔥 START CLOSING KEYBOARD
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // 🔥 WAIT FOR ANIMATION

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
          elevation: 4,
        ),
        onPressed: _isAnalyzing ? null : _saveTask,
        child: _isAnalyzing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "Add to Schedule",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTheme.deepSkyBlue,
        letterSpacing: 1.2,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.deepSkyBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

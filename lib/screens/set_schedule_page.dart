import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SetSchedulePage extends StatefulWidget {
  const SetSchedulePage({super.key});

  @override
  _SetSchedulePageState createState() => _SetSchedulePageState();
}

class _SetSchedulePageState extends State<SetSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<DateTime, TextEditingController> _scheduleControllers = {};
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  User? _currentUser;
  TimeOfDay? _physicalStartTime;
  TimeOfDay? _physicalEndTime;
  TimeOfDay? _onlineStartTime;
  TimeOfDay? _onlineEndTime;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _scheduleControllers[_selectedDate] = TextEditingController();
    _fetchExistingSchedules();
  }

  /// Fetch existing schedules from Firestore
  void _fetchExistingSchedules() async {
    if (_currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_currentUser!.email!)
          .collection('schedules')
          .get();

      setState(() {
        for (var doc in snapshot.docs) {
          final DateTime date = DateTime.parse(doc.id);
          final data = doc.data();
          _scheduleControllers[date] = TextEditingController(
            text: [
              if (data['physical_schedule'] != null)
                'Physical: ${data['physical_schedule']}',
              if (data['online_schedule'] != null)
                'Online: ${data['online_schedule']}',
            ].join('\n'),
          );
        }
      });
    }
  }

  /// Save schedule to Firestore
  void _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      if ((_physicalStartTime != null && _physicalEndTime != null) ||
          (_onlineStartTime != null && _onlineEndTime != null)) {
        // Validate that end time is after start time
        if ((_physicalStartTime != null &&
                _physicalEndTime != null &&
                !_isEndTimeValid(_physicalStartTime!, _physicalEndTime!)) ||
            (_onlineStartTime != null &&
                _onlineEndTime != null &&
                !_isEndTimeValid(_onlineStartTime!, _onlineEndTime!))) {
          _showDialog('Error', 'End time must be after the start time.');
          return;
        }

        final physicalScheduleText = (_physicalStartTime != null &&
                _physicalEndTime != null)
            ? '${_physicalStartTime!.format(context)} - ${_physicalEndTime!.format(context)}'
            : null;
        final onlineScheduleText = (_onlineStartTime != null &&
                _onlineEndTime != null)
            ? '${_onlineStartTime!.format(context)} - ${_onlineEndTime!.format(context)}'
            : null;

        final scheduleData = <String, String?>{
          if (physicalScheduleText != null)
            'physical_schedule': physicalScheduleText,
          if (onlineScheduleText != null) 'online_schedule': onlineScheduleText,
        };

        try {
          await FirebaseFirestore.instance
              .collection('doctor_schedules')
              .doc(_currentUser!.email!)
              .collection('schedules')
              .doc(_selectedDate.toIso8601String().split('T').first)
              .set(scheduleData, SetOptions(merge: true));

          setState(() {
            _scheduleControllers[_selectedDate]?.text = [
              if (physicalScheduleText != null)
                'Physical: $physicalScheduleText',
              if (onlineScheduleText != null) 'Online: $onlineScheduleText',
            ].join('\n');
            _physicalStartTime = null;
            _physicalEndTime = null;
            _onlineStartTime = null;
            _onlineEndTime = null;
          });

          _showDialog(
              'Success', 'Your schedules have been saved successfully.');
        } catch (e) {
          _showDialog('Error', 'Failed to save schedule. Please try again.');
        }
      } else {
        _showDialog(
            'Error', 'Please set either the Physical or Online schedule.');
      }
    }
  }

  /// Validate if end time is after start time
  bool _isEndTimeValid(TimeOfDay startTime, TimeOfDay endTime) {
    return endTime.hour > startTime.hour ||
        (endTime.hour == startTime.hour && endTime.minute > startTime.minute);
  }

  /// Show a dialog with a message
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(
      BuildContext context, bool isPhysical, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPhysical) {
          if (isStartTime) {
            _physicalStartTime = picked;
          } else {
            _physicalEndTime = picked;
          }
        } else {
          if (isStartTime) {
            _onlineStartTime = picked;
          } else {
            _onlineEndTime = picked;
          }
        }
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      if (!_scheduleControllers.containsKey(selectedDay)) {
        _scheduleControllers[selectedDay] = TextEditingController();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _selectedDate = focusedDay;
                },
              ),
              const SizedBox(height: 20.0),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Schedule for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 18.0),
                    ),
                    const SizedBox(height: 20.0),
                    _buildTimeSelector('Physical Start Time', true, true),
                    _buildTimeSelector('Physical End Time', true, false),
                    _buildTimeSelector('Online Start Time', false, true),
                    _buildTimeSelector('Online End Time', false, false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSchedule,
                child: const Text('Save Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, bool isPhysical, bool isStartTime) {
    final time = isPhysical
        ? (isStartTime ? _physicalStartTime : _physicalEndTime)
        : (isStartTime ? _onlineStartTime : _onlineEndTime);

    return Row(
      children: [
        ElevatedButton(
          onPressed: () => _selectTime(context, isPhysical, isStartTime),
          child: Text('Set $label'),
        ),
        const SizedBox(width: 10.0),
        if (time != null) Text(': ${time.format(context)}'),
      ],
    );
  }
}

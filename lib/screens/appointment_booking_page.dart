import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  @override
  _AppointmentBookingPageState createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _healthIssuesController = TextEditingController();

  String? _selectedDoctorEmail;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  List<String> _doctorEmails = [];
  List<DateTime> _availableDates = [];
  List<String> _timeSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctorEmails();
    _setUserEmail();
  }

  Future<void> _fetchDoctorEmails() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('doctors').get();
    final emails = snapshot.docs.map((doc) => doc['email'] as String).toList();
    setState(() {
      _doctorEmails = emails;
    });
  }

  Future<void> _setUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _fetchAvailableDates() async {
    if (_selectedDoctorEmail != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_selectedDoctorEmail!)
          .collection('schedules')
          .get();

      setState(() {
        _availableDates = snapshot.docs
            .map((doc) => DateTime.parse(doc.id))
            .toList()
          ..sort((a, b) => a.compareTo(b));
        _timeSlots = [];
        _selectedTimeSlot = null;
      });
    }
  }

  Future<void> _fetchTimeSlots() async {
    if (_selectedDoctorEmail != null && _selectedDate != null) {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final snapshot = await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_selectedDoctorEmail!)
          .collection('schedules')
          .doc(dateString)
          .get();

      final scheduleString = snapshot.data()?['online_schedule'] ?? '';
      if (scheduleString.isNotEmpty && scheduleString.contains(' - ')) {
        final generatedSlots = _generateTimeSlots(scheduleString);

        final bookedSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorEmail', isEqualTo: _selectedDoctorEmail)
            .where('appointmentDate', isEqualTo: dateString)
            .get();

        final bookedSlots = bookedSnapshot.docs
            .map((doc) => doc['appointmentTime'] as String)
            .toSet();

        setState(() {
          _timeSlots = generatedSlots
              .where((slot) => !bookedSlots.contains(slot))
              .toList();
        });
      } else {
        setState(() {
          _timeSlots = [];
        });
      }
    }
  }

  List<String> _generateTimeSlots(String schedule) {
    final timeSlots = <String>[];

    final times = schedule.split(' - ');
    if (times.length == 2) {
      final startTime = _parseTime(times[0]);
      final endTime = _parseTime(times[1]);

      DateTime currentTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        startTime.hour,
        startTime.minute,
      );
      DateTime endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        endTime.hour,
        endTime.minute,
      );

      while (
          currentTime.add(const Duration(minutes: 25)).isBefore(endDateTime) ||
              currentTime
                  .add(const Duration(minutes: 25))
                  .isAtSameMomentAs(endDateTime)) {
        final slotStart = _formatTime(currentTime);
        final slotEnd =
            _formatTime(currentTime.add(const Duration(minutes: 25)));

        timeSlots.add('$slotStart - $slotEnd');
        currentTime = currentTime.add(const Duration(minutes: 30));
      }
    }

    return timeSlots;
  }

  DateTime _parseTime(String time) {
    try {
      final format = DateFormat('h:mm a');
      return format.parse(time);
    } catch (e) {
      throw FormatException('Invalid time format: $time');
    }
  }

  String _formatTime(DateTime time) {
    final format = DateFormat.jm();
    return format.format(time);
  }

  Future<void> _registerAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final appointmentData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'doctorEmail': _selectedDoctorEmail,
        'appointmentDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'appointmentTime': _selectedTimeSlot,
        'healthIssues': _healthIssuesController.text,
      };

      await FirebaseFirestore.instance
          .collection('online_appointments')
          .add(appointmentData);

      setState(() {
        _isLoading = false;

        // Reset fields after registration
        _nameController.clear();
        _ageController.clear();
        _phoneController.clear();
        _healthIssuesController.clear();
        _selectedDoctorEmail = null;
        _selectedDate = null;
        _selectedTimeSlot = null;
        _availableDates = [];
        _timeSlots = [];
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your appointment has been booked successfully.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedDoctorEmail,
                      decoration: const InputDecoration(labelText: 'Doctor'),
                      items: _doctorEmails.map((email) {
                        return DropdownMenuItem(
                          value: email,
                          child: Text(email),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctorEmail = value;
                          _selectedDate = null;
                          _availableDates = [];
                          _timeSlots = [];
                        });
                        _fetchAvailableDates();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a doctor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<DateTime>(
                      value: _selectedDate,
                      decoration: const InputDecoration(labelText: 'Date'),
                      items: _availableDates.map((date) {
                        return DropdownMenuItem(
                          value: date,
                          child: Text(DateFormat('yyyy-MM-dd').format(date)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDate = value;
                          _timeSlots = [];
                          _selectedTimeSlot = null;
                        });
                        _fetchTimeSlots();
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedTimeSlot,
                      decoration: const InputDecoration(labelText: 'Time Slot'),
                      items: _timeSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTimeSlot = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time slot';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _healthIssuesController,
                      decoration:
                          const InputDecoration(labelText: 'Health Issues'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe your health issues';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _registerAppointment,
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

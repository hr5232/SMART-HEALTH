import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'video_call.dart';

class AppointmentBookedPage extends StatefulWidget {
  const AppointmentBookedPage({super.key});

  @override
  _AppointmentBookedPageState createState() => _AppointmentBookedPageState();
}

class _AppointmentBookedPageState extends State<AppointmentBookedPage> {
  final _currentUserEmail = FirebaseAuth.instance.currentUser!.email;
  String _selectedAppointmentType =
      'virtual'; // Default to virtual appointments

  Future<void> _deleteAppointment(String docId) async {
    try {
      final collection = _selectedAppointmentType == 'virtual'
          ? 'online_appointments'
          : 'physical_appointments';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete appointment: $e')),
      );
    }
  }

  void _joinVideoCall(String channelName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallPage(channelName: channelName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Appointments'),
      ),
      body: Column(
        children: [
          // Toggle between virtual and physical appointments
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Virtual Appointments'),
                selected: _selectedAppointmentType == 'virtual',
                onSelected: (selected) {
                  setState(() {
                    _selectedAppointmentType = 'virtual';
                  });
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Physical Appointments'),
                selected: _selectedAppointmentType == 'physical',
                onSelected: (selected) {
                  setState(() {
                    _selectedAppointmentType = 'physical';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_selectedAppointmentType == 'virtual'
                      ? 'online_appointments'
                      : 'physical_appointments')
                  .where('doctorEmail', isEqualTo: _currentUserEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No appointments found'));
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointmentDoc = appointments[index];
                    final appointment =
                        appointmentDoc.data() as Map<String, dynamic>;
                    final docId = appointmentDoc.id; // Document ID for deletion
                    final name = appointment['name'];
                    final age = appointment['age'];
                    final phone = appointment['phone'];
                    final email = appointment['email'];
                    final appointmentTime = appointment['appointmentTime'];
                    final appointmentDate = appointment['appointmentDate'];
                    final healthIssues = appointment['healthIssues'];

                    return Card(
                      child: Stack(
                        children: [
                          ListTile(
                            title: Text('Patient: $name'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Age: $age'),
                                Text('Phone: $phone'),
                                Text('Email: $email'),
                                Text('Date: $appointmentDate'),
                                Text('Time: $appointmentTime'),
                                Text('Health Issues: $healthIssues'),
                              ],
                            ),
                            trailing: _selectedAppointmentType == 'virtual'
                                ? IconButton(
                                    icon: const Icon(Icons.videocam,
                                        color: Colors.blueAccent),
                                    onPressed: () => _joinVideoCall(
                                        email), // Join video call
                                  )
                                : null,
                          ),
                          Positioned(
                            top: -11,
                            right: -9,
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 17, color: Colors.black),
                              onPressed: () => _deleteAppointment(docId),
                              tooltip: 'Delete appointment',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
